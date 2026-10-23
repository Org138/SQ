import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sqproject/components/auth_required_state.dart';
import 'package:sqproject/components/avatar.dart';
import 'package:sqproject/l10n/app_localizations.dart';
import 'package:sqproject/utils/constants.dart';


class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends AuthRequiredState<AccountPage> {
  final _usernameController = TextEditingController();
  final _websiteController = TextEditingController();
  String? _userId;
  String? _avatarUrl;
  var _loading = false;

  /// Called once a user id is received within `onAuthenticated()`
  Future<void> _getProfile(String userId) async {
    setState(() {
      _loading = true;
    });
    try {
      // A profile row may not exist yet, so allow zero rows.
      final data = await supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      if (data != null) {
        _usernameController.text = (data['username'] ?? '') as String;
        _websiteController.text = (data['website'] ?? '') as String;
        _avatarUrl = data['avatar_url'] as String?;
      }
    } on PostgrestException catch (error) {
      if (mounted) context.showErrorSnackBar(message: error.message);
    }
    if (!mounted) return;
    setState(() {
      _loading = false;
    });
  }

  /// Called when user taps `Update` button
  Future<void> _updateProfile() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _loading = true;
    });
    final userName = _usernameController.text;
    final website = _websiteController.text;
    final user = supabase.auth.currentUser;
    final updates = {
      'id': user!.id,
      'username': userName,
      'website': website,
      'updated_at': DateTime.now().toIso8601String(),
    };
    try {
      await supabase.from('profiles').upsert(updates);
      if (mounted) context.showSnackBar(message: l10n.profileUpdated);
    } on PostgrestException catch (error) {
      if (mounted) context.showErrorSnackBar(message: error.message);
    }
    if (!mounted) return;
    setState(() {
      _loading = false;
    });
  }

  /// The signedOut auth event sends the user to the login page
  /// (see AuthRequiredState).
  Future<void> _signOut() async {
    try {
      await supabase.auth.signOut();
    } on AuthException catch (error) {
      if (mounted) context.showErrorSnackBar(message: error.message);
    }
  }

  /// Called when image has been uploaded to Supabase storage from within Avatar widget
  Future<void> _onUpload(String imageUrl) async {
    final l10n = AppLocalizations.of(context);
    try {
      await supabase.from('profiles').upsert({
        'id': _userId,
        'avatar_url': imageUrl,
      });
    } on PostgrestException catch (error) {
      if (mounted) context.showErrorSnackBar(message: error.message);
      return;
    }
    if (!mounted) return;
    setState(() {
      _avatarUrl = imageUrl;
    });
    context.showSnackBar(message: l10n.avatarUpdated);
  }

  @override
  void onAuthenticated(Session session) {
    _userId = session.user.id;
    _getProfile(session.user.id);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileTitle)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        children: [
          Avatar(
            imageUrl: _avatarUrl,
            onUpload: _onUpload,
          ),
          const SizedBox(height: 18),
          TextFormField(
            controller: _usernameController,
            decoration: InputDecoration(labelText: l10n.userNameLabel),
          ),
          const SizedBox(height: 18),
          TextFormField(
            controller: _websiteController,
            decoration: InputDecoration(labelText: l10n.websiteLabel),
          ),
          const SizedBox(height: 18),
          ElevatedButton(
              onPressed: _loading ? null : _updateProfile,
              child: Text(_loading ? l10n.savingProfile : l10n.updateProfile)),
          const SizedBox(height: 18),
          ElevatedButton(
              onPressed: () => Navigator.of(context).pushNamed('/tasks'),
              child: Text(l10n.myTasks)),
          const SizedBox(height: 18),
          ElevatedButton(onPressed: _signOut, child: Text(l10n.signOut)),
        ],
      ),
    );
  }
}