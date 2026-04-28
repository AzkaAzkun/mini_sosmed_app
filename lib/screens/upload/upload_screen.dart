import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mini_sosmed_app/models/post_model.dart';
import 'package:mini_sosmed_app/services/auth_service.dart';
import 'package:mini_sosmed_app/services/db_service.dart';
import 'package:mini_sosmed_app/services/storage_service.dart';

class UploadScreen extends StatefulWidget {
  final VoidCallback? onUploadComplete;

  const UploadScreen({super.key, this.onUploadComplete});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _captionController = TextEditingController();
  final StorageService _storageService = StorageService();
  final DatabaseService _dbService = DatabaseService();

  File? _mediaFile;
  bool _isVideo = false;
  bool _isLoading = false;

  Future<void> _pickMedia({required bool isVideo}) async {
    final XFile? pickedFile;
    if (isVideo) {
      pickedFile = await _picker.pickVideo(source: ImageSource.gallery);
    } else {
      pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    }

    if (pickedFile != null) {
      setState(() {
        _mediaFile = File(pickedFile!.path);
        _isVideo = isVideo;
      });
    }
  }

  Future<void> _uploadPost() async {
    if (_mediaFile == null) return;

    final user = AuthService().currentUser;
    if (user == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Upload media to Storage
      final mediaUrl = await _storageService.uploadMedia(_mediaFile!, 'posts');

      // 2. Create PostModel
      final post = PostModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(), // or Use UUID
        userId: user.uid,
        mediaUrl: mediaUrl,
        isVideo: _isVideo,
        caption: _captionController.text.trim(),
        createdAt: DateTime.now(),
      );

      // 3. Save to Firestore
      await _dbService.createPost(post);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post berhasil diunggah!')),
        );
        setState(() {
          _mediaFile = null;
          _captionController.clear();
          _isVideo = false;
        });
        widget.onUploadComplete?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengunggah: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Post'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_mediaFile != null)
              Container(
                height: 300,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  image: !_isVideo
                      ? DecorationImage(
                          image: FileImage(_mediaFile!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _isVideo
                    ? const Center(child: Text('Video Selected (Preview placeholder)'))
                    : null,
              )
            else
              Container(
                height: 300,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text('Tidak ada media yang dipilih'),
                ),
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _pickMedia(isVideo: false),
                  icon: const Icon(Icons.image),
                  label: const Text('Pilih Foto'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _pickMedia(isVideo: true),
                  icon: const Icon(Icons.videocam),
                  label: const Text('Pilih Video'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _captionController,
              decoration: const InputDecoration(
                hintText: 'Tulis caption...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading || _mediaFile == null ? null : _uploadPost,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Upload'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
