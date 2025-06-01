import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String postId;
  final String userId;
  final String nickname;
  final String profileImageUrl;
  final String category;
  final int likeCount;
  final int commentCount;
  final DateTime timestamp;
  final String title;
  final String content;
  final String? imageUrl;

  PostModel({
    required this.postId,
    required this.userId,
    required this.nickname,
    required this.profileImageUrl,
    required this.category,
    required this.likeCount,
    required this.commentCount,
    required this.timestamp,
    required this.title,
    required this.content,
    this.imageUrl,
  });

  factory PostModel.fromMap(Map<String, dynamic> map) {
    return PostModel(
      postId: map['postId'],
      userId: map['userId'],
      nickname: map['nickname'],
      profileImageUrl: map['profileImageUrl'],
      category: map['category'],
      likeCount: map['likeCount'] ?? 0,
      commentCount: map['commentCount'] ?? 0,
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      title: map['title'],
      content: map['content'],
      imageUrl: map['imageUrl'],
    );
  }
}


