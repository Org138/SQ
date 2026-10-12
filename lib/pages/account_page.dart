import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase_quickstart/components/auth_required_state.dart';
import 'package:supabase_quickstart/components/avatar.dart';
import 'package:supabase_quickstart/utils/constants.dart';


class AccountPage extends StatefulWidget {
  const AccountPage({Key? key}) : super(key: key);

  @override
  _AccountPageState createState() => _AccountPageState();
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
      if (mounted) context.showSnackBar(message: 'Successfully updated profile!');
    } on PostgrestException catch (error) {
      if (mounted) context.showErrorSnackBar(message: error.message);
    }
    if (!mounted) return;
    setState(() {
      _loading = false;
    });
  }

  Future<void> _signOut() async {
    final response = await supabase.auth.signOut();
    final error = response.error;
    if (error != null) {
      context.showErrorSnackBar(message: error.message);
    }
    Navigator.of(context).pushReplacementNamed('/login');
  }

  /// Called when image has been uploaded to Supabase storage from within Avatar widget
  Future<void> _onUpload(String imageUrl) async {
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
    context.showSnackBar(message: 'Updated your profile image!');
  }

  @override
  void onAuthenticated(Session session) {
    final user = session.user;
    if (user != null) {
      _userId = user.id;
      _getProfile(user.id);
    }
  }

  @override
  void onUnauthenticated() {
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
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
            decoration: const InputDecoration(labelText: 'User Name'),
          ),
          const SizedBox(height: 18),
          TextFormField(
            controller: _websiteController,
            decoration: const InputDecoration(labelText: 'Website' ),
          ),
          const SizedBox(height: 18),
          ElevatedButton(
              onPressed: _updateProfile,
              child: Text(_loading ? 'Saving...' : 'Update')),
          const SizedBox(height: 18),
          ElevatedButton(
              onPressed: () => Navigator.of(context).pushNamed('/tasks'),
              child: const Text('My Tasks')),
          const SizedBox(height: 18),
          ElevatedButton(onPressed: _signOut, child: const Text('Sign Out')),
        ],
      ),
    );
  }
}