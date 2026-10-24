import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sqproject/l10n/app_localizations.dart';

/// A message for [error] in the user's language. Known Postgres, PostgREST
/// and Auth error codes get their own translated message; anything else
/// falls back to the server's (English) message, or to [offline] when the
/// request never got a response.
///
/// [offline]: AppLocalizations.offline
String errorMessage(AppLocalizations l10n, Object error) => switch (error) {
      // The only unique index users can hit; task rows use generated ids.
      PostgrestException(code: '23505', :final message)
          when message.contains('profiles_username_key') =>
        l10n.errorUsernameTaken,
      // A gating trigger or foreign key refused a change that the app's own
      // checks allowed, so the board was out of date (e.g. a task was
      // changed or deleted on another device).
      PostgrestException(code: '23503' || '23514') => l10n.errorOutOfDate,
      // Row-level security refused the change.
      PostgrestException(code: '42501') => l10n.errorPermissionDenied,
      // The access token was invalid or expired.
      PostgrestException(code: 'PGRST301' || 'PGRST303') =>
        l10n.errorSessionExpired,
      PostgrestException(:final message) => message,
      AuthRetryableFetchException() => l10n.offline,
      // A magic link's redirect puts the error code in statusCode.
      AuthException(code: 'otp_expired' || 'flow_state_expired') ||
      AuthException(statusCode: 'otp_expired') =>
        l10n.errorLinkExpired,
      AuthException(
        code: 'over_email_send_rate_limit' || 'over_request_rate_limit'
      ) =>
        l10n.errorTooManyRequests,
      AuthException(
        code: 'session_not_found' ||
            'session_expired' ||
            'refresh_token_not_found'
      ) =>
        l10n.errorSessionExpired,
      AuthException(code: 'email_address_invalid') => l10n.errorInvalidEmail,
      AuthException(:final message) => message,
      StorageException(:final message) => message,
      _ => l10n.offline,
    };
