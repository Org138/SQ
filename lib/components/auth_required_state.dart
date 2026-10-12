import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sqproject/utils/constants.dart';

/// Base state for pages that need a signed-in user.
///
/// Calls [onAuthenticated] with the current session once the page is shown,
/// and [onUnauthenticated] if there is no session or the user signs out.
abstract class AuthRequiredState<T extends StatefulWidget> extends State<T> {
  late final StreamSubscription<AuthState> _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription = supabase.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedOut) onUnauthenticated();
    });
    // Navigation can't happen during the first build, so defer it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final session = supabase.auth.currentSession;
      if (session == null) {
        onUnauthenticated();
      } else {
        onAuthenticated(session);
      }
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  /// Called once with the current session when the page is shown.
  void onAuthenticated(Session session) {}

  /// Users are sent back to the login page if they aren't signed in.
  void onUnauthenticated() {
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }
}
