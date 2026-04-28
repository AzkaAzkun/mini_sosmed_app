import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String userId;
  final String mediaUrl;
  final bool isVideo;
  final String caption;
  final DateTime createdAt;

  PostModel({
    required this.id,
    required this.userId,
    required this.mediaUrl,
    this.isVideo = false,
    this.caption = '',
    required this.createdAt,
  });

  factory PostModel.fromDocument(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return PostModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      mediaUrl: data['mediaUrl'] ?? '',
      isVideo: data['isVideo'] ?? false,
      caption: data['caption'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'mediaUrl': mediaUrl,
      'isVideo': isVideo,
      'caption': caption,
      'createdAt': createdAt,
    };
  }
}
