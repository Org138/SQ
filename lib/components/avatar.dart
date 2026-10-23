import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sqproject/l10n/app_localizations.dart';
import 'package:sqproject/utils/constants.dart';

class Avatar extends StatefulWidget {
  const Avatar({
    super.key,
    required this.imageUrl,
    required this.onUpload,
  });

  final String? imageUrl;
  final void Function(String) onUpload;

  @override
  State<Avatar> createState() => _AvatarState();
}

class _AvatarState extends State<Avatar> {
  static const _allowedTypes = {'image/jpeg', 'image/png', 'image/webp'};
  static const _allowedExtensions = {'jpg', 'jpeg', 'png', 'webp'};
  static const _maxBytes = 1024 * 1024;

  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        if (widget.imageUrl == null)
          Container(
            width: 150,
            height: 150,
            color: Colors.grey,
            child: Center(
              child: Text(l10n.noAvatar),
            ),
          )
        else
          Image.network(
            widget.imageUrl!,
            width: 150,
            height: 150,
            fit: BoxFit.cover,
          ),
        ElevatedButton(
          onPressed: _isLoading ? null : _upload,
          child: Text(l10n.uploadAvatar),
        ),
      ],
    );
  }

  Future<void> _upload() async {
    final l10n = AppLocalizations.of(context);
    final picker = ImagePicker();
    final imageFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 300,
      maxHeight: 300,
    );
    if (imageFile == null) {
      return;
    }
    setState(() => _isLoading = true);

    final bytes = await imageFile.readAsBytes();
    // Use the file's name, not its path: on web the path is a blob: URL.
    final name = imageFile.name;
    final fileExt =
        name.contains('.') ? name.split('.').last.toLowerCase() : 'jpg';
    final contentType = imageFile.mimeType ??
        'image/${fileExt == 'jpg' ? 'jpeg' : fileExt}';
    // Mirrors the avatars bucket limits (see the restrict_avatar_file_types
    // migration), which the server enforces regardless.
    if (!_allowedTypes.contains(contentType) ||
        !_allowedExtensions.contains(fileExt)) {
      if (mounted) {
        context.showErrorSnackBar(message: l10n.avatarWrongType);
        setState(() => _isLoading = false);
      }
      return;
    }
    if (bytes.length > _maxBytes) {
      if (mounted) {
        context.showErrorSnackBar(message: l10n.avatarTooLarge);
        setState(() => _isLoading = false);
      }
      return;
    }
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
    // Storage policies only allow uploads into the user's own folder.
    final filePath = '${supabase.auth.currentUser!.id}/$fileName';
    try {
      await supabase.storage.from('avatars').uploadBinary(
            filePath,
            bytes,
            fileOptions: FileOptions(contentType: contentType),
          );
    } on StorageException catch (error) {
      if (mounted) context.showErrorSnackBar(message: error.message);
      return;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }

    final imageUrl = supabase.storage.from('avatars').getPublicUrl(filePath);
    widget.onUpload(imageUrl);
  }
}
