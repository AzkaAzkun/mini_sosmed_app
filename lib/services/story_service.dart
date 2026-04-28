import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mini_sosmed_app/models/story_model.dart';

class StoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createStory(StoryModel story) async {
    try {
      await _firestore.collection('stories').doc(story.id).set(story.toMap());
    } catch (e) {
      throw Exception('Failed to create story: $e');
    }
  }

  Stream<List<StoryModel>> getActiveStories() {
    return _firestore
        .collection('stories')
        .where('expiresAt', isGreaterThan: Timestamp.now())
        .orderBy('expiresAt')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => StoryModel.fromDocument(doc)).toList();
    });
  }
}
