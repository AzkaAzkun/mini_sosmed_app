import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:mini_sosmed_app/models/story_model.dart';
import 'package:mini_sosmed_app/services/auth_service.dart';
import 'package:mini_sosmed_app/services/storage_service.dart';
import 'package:mini_sosmed_app/services/story_service.dart';

class CreateStoryScreen extends StatefulWidget {
  const CreateStoryScreen({super.key});

  @override
  State<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends State<CreateStoryScreen> {
  final ImagePicker _picker = ImagePicker();
  final StorageService _storageService = StorageService();
  final StoryService _storyService = StoryService();

  File? _mediaFile;
  bool _isVideo = false;
  bool _isLoading = false;
  String? _locationName;

  Future<void> _pickMedia({required bool isVideo, required ImageSource source}) async {
    XFile? pickedFile;
    try {
      if (isVideo) {
        pickedFile = await _picker.pickVideo(
          source: source,
          maxDuration: const Duration(seconds: 30),
        );
      } else {
        pickedFile = await _picker.pickImage(
          source: source,
          imageQuality: 80,
        );
      }

      if (pickedFile != null) {
        setState(() {
          _mediaFile = File(pickedFile!.path);
          _isVideo = isVideo;
        });
        _getLocation();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking media: $e')),
        );
      }
    }
  }

  void _showPickerOptions(bool isVideo) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(isVideo ? Icons.videocam : Icons.camera_alt, color: Colors.white),
              title: Text(isVideo ? 'Rekam Video' : 'Ambil Foto', style: const TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _pickMedia(isVideo: isVideo, source: ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.white),
              title: Text(isVideo ? 'Pilih dari Galeri' : 'Pilih dari Galeri', style: const TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _pickMedia(isVideo: isVideo, source: ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _getLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    
    if (permission == LocationPermission.deniedForever) return;

    try {
      Position position = await Geolocator.getCurrentPosition();
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          _locationName = '${place.locality}, ${place.country}';
        });
      }
    } catch (e) {
      // Ignore if failed
    }
  }

  Future<void> _uploadStory() async {
    if (_mediaFile == null) return;

    final user = AuthService().currentUser;
    if (user == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final mediaUrl = await _storageService.uploadMedia(_mediaFile!, 'stories');

      final story = StoryModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: user.uid,
        mediaUrl: mediaUrl,
        isVideo: _isVideo,
        location: _locationName,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(hours: 24)),
      );

      await _storyService.createStory(story);

      if (mounted) {
        Navigator.pop(context); // Go back to Feed
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Story berhasil diunggah!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengunggah story: $e')),
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buat Story')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_mediaFile != null)
              Container(
                height: 400,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                  image: !_isVideo
                      ? DecorationImage(
                          image: FileImage(_mediaFile!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: Stack(
                  children: [
                    if (_isVideo)
                      const Center(child: Text('Video Selected')),
                    if (_locationName != null)
                      Positioned(
                        bottom: 16,
                        left: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on, color: Colors.white, size: 16),
                              const SizedBox(width: 4),
                              Text(_locationName!, style: const TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              )
            else
              Container(
                height: 400,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[800]!),
                ),
                child: const Center(
                  child: Text(
                    'Pilih foto/video untuk Story',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _showPickerOptions(false),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Foto'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showPickerOptions(true),
                  icon: const Icon(Icons.videocam),
                  label: const Text('Video'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading || _mediaFile == null ? null : _uploadStory,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Bagikan ke Story', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
