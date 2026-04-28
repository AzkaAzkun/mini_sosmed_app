import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = const Uuid();

  Future<String> uploadMedia(File file, String folderName) async {
    try {
      final String fileId = _uuid.v4();
      final String ext = file.path.split('.').last;
      final Reference ref = _storage.ref().child(folderName).child('$fileId.$ext');

      final UploadTask uploadTask = ref.putFile(file);
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload media: $e');
    }
  }
}
