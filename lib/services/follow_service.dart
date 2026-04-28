import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mini_sosmed_app/models/follow_model.dart';
import 'package:mini_sosmed_app/models/notification_model.dart';

class FollowService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> followUser(String currentUserId, String targetUserId) async {
    final followId = '${currentUserId}_$targetUserId';
    
    // Create follow record
    final follow = FollowModel(
      followerId: currentUserId,
      followingId: targetUserId,
      createdAt: DateTime.now(),
    );
    
    await _firestore.collection('follows').doc(followId).set(follow.toMap());

    // Create notification
    final notificationRef = _firestore.collection('notifications').doc();
    final notification = NotificationModel(
      id: notificationRef.id,
      receiverId: targetUserId,
      senderId: currentUserId,
      type: 'follow',
      message: 'mulai mengikuti Anda.',
      createdAt: DateTime.now(),
    );
    
    await notificationRef.set(notification.toMap());
  }

  Future<void> unfollowUser(String currentUserId, String targetUserId) async {
    final followId = '${currentUserId}_$targetUserId';
    await _firestore.collection('follows').doc(followId).delete();
  }

  Stream<bool> isFollowing(String currentUserId, String targetUserId) {
    final followId = '${currentUserId}_$targetUserId';
    return _firestore.collection('follows').doc(followId).snapshots().map((doc) => doc.exists);
  }

  Stream<int> getFollowerCount(String userId) {
    return _firestore
        .collection('follows')
        .where('followingId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<int> getFollowingCount(String userId) {
    return _firestore
        .collection('follows')
        .where('followerId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<List<String>> getFollowingIds(String userId) {
    return _firestore
        .collection('follows')
        .where('followerId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc['followingId'] as String).toList());
  }

  Stream<List<String>> getFollowers(String userId) {
    return _firestore
        .collection('follows')
        .where('followingId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc['followerId'] as String).toList());
  }

  Stream<List<String>> getFollowing(String userId) {
    return _firestore
        .collection('follows')
        .where('followerId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc['followingId'] as String).toList());
  }
}
