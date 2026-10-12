import 'package:flutter/material.dart';
import 'package:supabase_quickstart/utils/constants.dart';

/// Sends the user to their account if a session was restored at startup,
/// otherwise to the login page.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    // Supabase.initialize() restores any saved session before runApp, so
    // currentSession is already up to date. Navigate after the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final route = supabase.auth.currentSession == null ? '/login' : '/account';
      Navigator.of(context).pushNamedAndRemoveUntil(route, (route) => false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
