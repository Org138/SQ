// Widget tests for the profile page, run against a fake Supabase REST and
// auth backend (no network) with a signed-in test session.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sqproject/l10n/app_localizations.dart';
import 'package:sqproject/pages/account_page.dart';

/// In-memory stand-in for the `profiles` table and the auth server.
class FakeBackend {
  /// The signed-in user's row, or null if it doesn't exist yet.
  Map<String, dynamic>? profile = {
    'id': 'user-1',
    'username': 'alice',
    'website': 'https://alice.example',
    // A URL here would make Image.network fetch it.
    'avatar_url': null,
  };

  final profileReads = <http.Request>[];
  final upserts = <http.Request>[];
  final logouts = <http.Request>[];

  /// When set, upserts fail with this unique-constraint message.
  String? rejectUpsertsWith;

  /// When set, upserts wait for it before answering.
  Completer<void>? holdUpserts;

  Future<http.Response> handle(http.Request request) async {
    final json = {'content-type': 'application/json'};
    switch ((request.method, request.url.path)) {
      // maybeSingle() reads a list and allows zero rows.
      case ('GET', '/rest/v1/profiles'):
        profileReads.add(request);
        return http.Response(jsonEncode([if (profile != null) profile]), 200,
            headers: json, request: request);
      case ('POST', '/rest/v1/profiles'):
        upserts.add(request);
        await holdUpserts?.future;
        if (rejectUpsertsWith != null) {
          return http.Response(
            jsonEncode({'code': '23505', 'message': rejectUpsertsWith}),
            409,
            headers: json,
            request: request,
          );
        }
        profile = {...?profile, ...jsonDecode(request.body)};
        return http.Response('', 201, request: request);
      case ('POST', '/auth/v1/logout'):
        logouts.add(request);
        return http.Response('', 204, request: request);
    }
    return http.Response('Unexpected ${request.method} ${request.url}', 404,
        request: request);
  }
}

/// PKCE storage kept in memory so tests don't need platform plugins.
class MemoryAsyncStorage extends GotrueAsyncStorage {
  final _items = <String, String>{};

  @override
  Future<String?> getItem({required String key}) async => _items[key];

  @override
  Future<void> removeItem({required String key}) async => _items.remove(key);

  @override
  Future<void> setItem({required String key, required String value}) async =>
      _items[key] = value;
}

late FakeBackend backend;

Future<void> pumpAccountPage(WidgetTester tester, {Locale? locale}) async {
  await tester.pumpWidget(MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: const AccountPage(),
    routes: {
      '/login': (_) => const Scaffold(body: Text('login')),
      '/tasks': (_) => const Scaffold(body: Text('tasks')),
    },
  ));
  await tester.pumpAndSettle();
}

/// The text in the form field labeled [label].
String fieldText(WidgetTester tester, String label) => tester
    .widget<TextField>(find.widgetWithText(TextField, label))
    .controller!
    .text;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await Supabase.initialize(
      url: 'https://test.supabase.co',
      publishableKey: 'test-key',
      httpClient: MockClient((request) => backend.handle(request)),
      authOptions: FlutterAuthClientOptions(
        localStorage: const EmptyLocalStorage(),
        pkceAsyncStorage: MemoryAsyncStorage(),
        detectSessionInUri: false,
        autoRefreshToken: false,
      ),
    );
  });

  // Each test starts signed in, since the sign-out test ends the session.
  setUp(() async {
    backend = FakeBackend();
    // A non-JWT access token has no expiry, so the session is accepted
    // without contacting the auth server.
    await Supabase.instance.client.auth.recoverSession(jsonEncode({
      'access_token': 'test-access-token',
      'token_type': 'bearer',
      'refresh_token': 'test-refresh-token',
      'user': {
        'id': 'user-1',
        'aud': 'authenticated',
        'app_metadata': <String, dynamic>{},
        'user_metadata': <String, dynamic>{},
        'created_at': '2026-01-01T00:00:00Z',
      },
    }));
  });

  testWidgets('loads the signed-in user\'s profile into the form',
      (tester) async {
    await pumpAccountPage(tester);

    expect(backend.profileReads.single.url.queryParameters['id'], 'eq.user-1');
    expect(fieldText(tester, 'User Name'), 'alice');
    expect(fieldText(tester, 'Website'), 'https://alice.example');
    expect(find.text('No Image'), findsOneWidget);
  });

  testWidgets('a user without a profile row gets an empty form',
      (tester) async {
    backend.profile = null;
    await pumpAccountPage(tester);

    expect(fieldText(tester, 'User Name'), isEmpty);
    expect(fieldText(tester, 'Website'), isEmpty);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('Update saves the form and says so', (tester) async {
    await pumpAccountPage(tester);
    await tester.enterText(find.widgetWithText(TextField, 'User Name'), 'bob');
    await tester.enterText(
        find.widgetWithText(TextField, 'Website'), 'https://bob.example');
    backend.holdUpserts = Completer();
    await tester.tap(find.text('Update'));
    await tester.pump();

    final button = find.widgetWithText(ElevatedButton, 'Saving…');
    expect(button, findsOneWidget);
    expect(tester.widget<ElevatedButton>(button).onPressed, isNull);

    backend.holdUpserts!.complete();
    await tester.pumpAndSettle();
    expect(jsonDecode(backend.upserts.single.body), {
      'id': 'user-1',
      'username': 'bob',
      'website': 'https://bob.example',
      'updated_at': isA<String>(),
    });
    expect(find.text('Successfully updated profile!'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Update'), findsOneWidget);
  });

  testWidgets('a taken user name shows the translated message',
      (tester) async {
    backend.rejectUpsertsWith = 'duplicate key value violates unique '
        'constraint "profiles_username_key"';
    await pumpAccountPage(tester);
    await tester.enterText(find.widgetWithText(TextField, 'User Name'), 'bob');
    await tester.tap(find.text('Update'));
    await tester.pumpAndSettle();

    expect(backend.upserts, hasLength(1));
    expect(find.text('That user name is taken. Try another one.'),
        findsOneWidget);
    expect(find.text('Successfully updated profile!'), findsNothing);
    // The form keeps what the user typed, and they can try again.
    expect(fieldText(tester, 'User Name'), 'bob');
    expect(
        tester
            .widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Update'))
            .onPressed,
        isNotNull);
  });

  testWidgets('My Tasks opens the tasks page', (tester) async {
    await pumpAccountPage(tester);
    await tester.tap(find.text('My Tasks'));
    await tester.pumpAndSettle();

    expect(find.text('tasks'), findsOneWidget);
  });

  testWidgets('Sign Out ends the session and returns to the login page',
      (tester) async {
    await pumpAccountPage(tester);
    await tester.tap(find.text('Sign Out'));
    await tester.pumpAndSettle();

    expect(backend.logouts, hasLength(1));
    expect(Supabase.instance.client.auth.currentSession, isNull);
    expect(find.text('login'), findsOneWidget);
    // The login page replaced the stack, so there's no way back.
    expect(find.text('Profile'), findsNothing);
  });

  // Text that doesn't fit fails the test with an overflow error.
  for (final locale in AppLocalizations.supportedLocales) {
    testWidgets('the profile page fits a small phone in $locale',
        (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final l10n = lookupAppLocalizations(locale);
      await pumpAccountPage(tester, locale: locale);

      expect(find.text(l10n.profileTitle), findsOneWidget);
      expect(find.text(l10n.noAvatar), findsOneWidget);
      for (final label in [l10n.userNameLabel, l10n.websiteLabel]) {
        expect(find.widgetWithText(TextField, label), findsOneWidget);
      }
      for (final label in [
        l10n.uploadAvatar,
        l10n.myTasks,
        l10n.signOut,
      ]) {
        expect(find.widgetWithText(ElevatedButton, label), findsOneWidget);
      }

      final update = find.widgetWithText(ElevatedButton, l10n.updateProfile);
      await tester.ensureVisible(update);
      await tester.tap(update);
      await tester.pumpAndSettle();
      expect(find.text(l10n.profileUpdated), findsOneWidget);
    });
  }
}
