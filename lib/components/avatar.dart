import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase_quickstart/utils/constants.dart';

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
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.imageUrl == null)
          Container(
            width: 150,
            height: 150,
            color: Colors.grey,
            child: const Center(
              child: Text('No Image'),
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
          child: const Text('Upload'),
        ),
      ],
    );
  }

  Future<void> _upload() async {
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
