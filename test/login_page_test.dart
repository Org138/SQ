// Widget tests for the sign-in page, run against a fake auth server
// (no network).

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

Future<void> sendMagicLink(WidgetTester tester, String email) async {
  await tester.pumpWidget(const MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: LoginPage(),
  ));
  await tester.enterText(find.byType(TextFormField), email);
  await tester.tap(find.text('Send sign-in link'));
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

  setUp(requests.clear);

  for (final email in ['', '   ']) {
    testWidgets('a blank email ("$email") sends no request', (tester) async {
      await sendMagicLink(tester, email);

      expect(requests, isEmpty);
      expect(find.text('Enter your email address'), findsOneWidget);
    });
  }

  testWidgets('an email sends one magic-link request', (tester) async {
    await sendMagicLink(tester, ' alice@example.com ');

    expect(requests.single.url.path, '/auth/v1/otp');
    expect(requests.single.body, contains('"email":"alice@example.com"'));
    expect(find.text('Check your email for a sign-in link.'), findsOneWidget);
  });
}
