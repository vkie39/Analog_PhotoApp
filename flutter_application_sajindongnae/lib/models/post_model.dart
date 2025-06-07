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

  factory PostModel.fromMap(Map<String, dynamic> map) { // json 스트링을 Dart에서 사용 가능한 객체로 받아오기 위한 함수
    return PostModel(                                   // 실제 사용할 땐 post = PostModel.fromMap(doc.data() as Map<String,dynamic>); 처럼 쓰면 됨 
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


