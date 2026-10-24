import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sqproject/l10n/app_localizations.dart';
import 'package:sqproject/utils/constants.dart';
import 'package:sqproject/utils/error_messages.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  late final StreamSubscription<AuthState> _authSubscription;

  Future<void> _signIn() async {
    // Without an email the auth server only answers with a 400.
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context);
    setState(() {
      _isLoading = true;
    });
    try {
      await supabase.auth.signInWithOtp(
        email: _emailController.text.trim(),
        emailRedirectTo:
            kIsWeb ? null : 'io.supabase.sqproject://login-callback',
      );
      if (mounted) {
        context.showSnackBar(message: l10n.magicLinkSent);
        _emailController.clear();
      }
    } on AuthException catch (error) {
      if (mounted) {
        context.showErrorSnackBar(message: errorMessage(l10n, error));
      }
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
              message: error is AuthException
                  ? errorMessage(AppLocalizations.of(context), error)
                  : '$error');
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
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.signInTitle)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
          children: [
            Text(l10n.signInPrompt),
            const SizedBox(height: 18),
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(labelText: l10n.emailLabel),
              keyboardType: TextInputType.emailAddress,
              validator: (value) =>
                  (value ?? '').trim().isEmpty ? l10n.emailRequired : null,
            ),
            const SizedBox(height: 18),
            ElevatedButton(
                onPressed: _isLoading ? null: _signIn,
                child: Text(
                    _isLoading ? l10n.sendingMagicLink : l10n.sendMagicLink),
            ),
          ],
        ),
      ),
    );
  }
}








