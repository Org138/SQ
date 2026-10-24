import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sqproject/l10n/app_localizations.dart';
import 'package:sqproject/utils/error_messages.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));
  String message(Object error) => errorMessage(l10n, error);

  group('Postgres and PostgREST errors', () {
    test('a taken user name', () {
      expect(
          message(const PostgrestException(
              message: 'duplicate key value violates unique constraint '
                  '"profiles_username_key"',
              code: '23505')),
          l10n.errorUsernameTaken);
    });

    test('other duplicates keep the server message', () {
      const error = PostgrestException(
          message: 'duplicate key value violates unique constraint '
              '"task_dependencies_pkey"',
          code: '23505');
      expect(message(error), error.message);
    });

    test('gating triggers and foreign keys mean the board was out of date', () {
      for (final code in ['23514', '23503']) {
        expect(message(PostgrestException(message: 'Blocked by', code: code)),
            l10n.errorOutOfDate);
      }
    });

    test('row-level security', () {
      expect(
          message(const PostgrestException(
              message: 'new row violates row-level security policy',
              code: '42501')),
          l10n.errorPermissionDenied);
    });

    test('an invalid or expired token', () {
      for (final code in ['PGRST301', 'PGRST303']) {
        expect(message(PostgrestException(message: 'JWT expired', code: code)),
            l10n.errorSessionExpired);
      }
    });

    test('unknown codes keep the server message', () {
      const error = PostgrestException(message: 'Something new', code: 'XX000');
      expect(message(error), error.message);
    });
  });

  group('Auth errors', () {
    test('an expired magic link, from the API or the redirect URL', () {
      expect(
          message(const AuthApiException('Token expired', code: 'otp_expired')),
          l10n.errorLinkExpired);
      expect(
          message(const AuthException('Email link is invalid or has expired',
              statusCode: 'otp_expired', code: 'access_denied')),
          l10n.errorLinkExpired);
    });

    test('rate limits', () {
      expect(
          message(const AuthApiException('Email rate limit exceeded',
              code: 'over_email_send_rate_limit')),
          l10n.errorTooManyRequests);
    });

    test('a missing session', () {
      expect(
          message(const AuthApiException('Session not found',
              code: 'session_not_found')),
          l10n.errorSessionExpired);
    });

    test('an invalid email address', () {
      expect(
          message(const AuthApiException('Email address is invalid',
              code: 'email_address_invalid')),
          l10n.errorInvalidEmail);
    });

    test('no response means offline', () {
      expect(message(AuthRetryableFetchException()), l10n.offline);
    });

    test('unknown codes keep the server message', () {
      const error = AuthApiException('Signups not allowed', code: 'other');
      expect(message(error), error.message);
    });
  });

  test('anything else means the request never got a response', () {
    expect(message(Exception('SocketException')), l10n.offline);
  });
}
