import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase_quickstart/utils/constants.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLoading = false;
  late final TextEditingController _emailController;
  late final StreamSubscription<AuthState> _authSubscription;

  Future<void> _signIn() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await supabase.auth.signInWithOtp(
        email: _emailController.text.trim(),
        emailRedirectTo:
            kIsWeb ? null : 'io.supabase.flutterquickstart://login-callback',
      );
      if (mounted) {
        context.showSnackBar(message: 'Check your email for login link!');
        _emailController.clear();
      }
    } on AuthException catch (error) {
      if (mounted) context.showErrorSnackBar(message: error.message);
    }
    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    // Opening the magic link signs the user in (via deep link on mobile).
    _authSubscription = supabase.auth.onAuthStateChange.listen(
      (data) {
        if (data.session != null && mounted) {
          Navigator.of(context)
              .pushNamedAndRemoveUntil('/account', (route) => false);
        }
      },
      onError: (Object error) {
        if (mounted) {
          context.showErrorSnackBar(
              message: error is AuthException ? error.message : '$error');
        }
      },
    );
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign In')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        children: [
          const Text('Sign in via the magic link with your email below'),
          const SizedBox(height: 18),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          const SizedBox(height: 18),
          ElevatedButton(
              onPressed: _isLoading ? null: _signIn,
              child: Text(_isLoading ? 'Loading' : 'Send Magic Link'),
          ),
        ],
      ),
    );
  }
}








