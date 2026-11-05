// Widget tests for the sign-in page, run against a fake auth server
// (no network).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sqproject/l10n/app_localizations.dart';
import 'package:sqproject/pages/login_page.dart';

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

final requests = <http.Request>[];

/// When set, the fake auth server waits for it before answering.
Completer<void>? holdReplies;

Future<void> sendMagicLink(WidgetTester tester, String email,
    {Locale locale = const Locale('en')}) async {
  await tester.pumpWidget(MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: const LoginPage(),
  ));
  await tester.enterText(find.byType(TextFormField), email);
  await tester
      .tap(find.text(lookupAppLocalizations(locale).sendMagicLink));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await Supabase.initialize(
      url: 'https://test.supabase.co',
      publishableKey: 'test-key',
      httpClient: MockClient((request) async {
        requests.add(request);
        await holdReplies?.future;
        return http.Response('{}', 200,
            headers: {'content-type': 'application/json'}, request: request);
      }),
      authOptions: FlutterAuthClientOptions(
        localStorage: const EmptyLocalStorage(),
        pkceAsyncStorage: MemoryAsyncStorage(),
        detectSessionInUri: false,
        autoRefreshToken: false,
      ),
    );
  });

  setUp(() {
    requests.clear();
    holdReplies = null;
  });

  for (final email in ['', '   ']) {
    testWidgets('a blank email ("$email") sends no request', (tester) async {
      await sendMagicLink(tester, email);

      expect(requests, isEmpty);
      expect(find.text('Enter your email address'), findsOneWidget);
    });
  }

  testWidgets('typing clears the email error without sending',
      (tester) async {
    await sendMagicLink(tester, '');
    expect(find.text('Enter your email address'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'a');
    await tester.pump();
    expect(find.text('Enter your email address'), findsNothing);

    // Erasing it again brings the error back.
    await tester.enterText(find.byType(TextFormField), '');
    await tester.pump();
    expect(find.text('Enter your email address'), findsOneWidget);
    expect(requests, isEmpty);
  });

  testWidgets('an email sends one magic-link request', (tester) async {
    await sendMagicLink(tester, ' alice@example.com ');

    expect(requests.single.url.path, '/auth/v1/otp');
    expect(requests.single.body, contains('"email":"alice@example.com"'));
    expect(find.text('Please check your email for a sign-in link.'), findsOneWidget);
  });

  testWidgets('the button says it is sending until the server answers',
      (tester) async {
    holdReplies = Completer();
    await sendMagicLink(tester, 'alice@example.com');

    final button = find.widgetWithText(ElevatedButton, 'Sending…');
    expect(button, findsOneWidget);
    expect(tester.widget<ElevatedButton>(button).onPressed, isNull);

    holdReplies!.complete();
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ElevatedButton, 'Send sign-in link'),
        findsOneWidget);
  });

  // Text that doesn't fit fails the test with an overflow error.
  for (final locale in AppLocalizations.supportedLocales) {
    testWidgets('the sign-in page fits a small phone in $locale',
        (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final l10n = lookupAppLocalizations(locale);

      await sendMagicLink(tester, '', locale: locale);
      expect(find.text(l10n.signInTitle), findsOneWidget);
      expect(find.text(l10n.signInPrompt), findsOneWidget);
      expect(find.text(l10n.emailRequired), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), 'alice@example.com');
      await tester.tap(find.text(l10n.sendMagicLink));
      await tester.pumpAndSettle();
      expect(requests, hasLength(1));
      expect(find.text(l10n.magicLinkSent), findsOneWidget);
    });
  }
}
