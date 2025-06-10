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


  factory PostModel.fromDocument(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;
    return PostModel(
      postId: doc.id, // Firestore 문서의 고유 ID (자동 생성된 값)
      userId: map['userId'] ?? '', //null 대비
      nickname: map['nickname'] ?? '',
      profileImageUrl: map['profileImageUrl'] ?? '',
      category: map['category'] ?? '',
      likeCount: map['likeCount'] ?? 0,
      commentCount: map['commentCount'] ?? 0,
      timestamp: (map['createdAt'] as Timestamp).toDate(), //Firestore에서 저장한 시간 필드
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      imageUrl: map['imageUrl'], //선택 필드라 null 허용
    );
  }

}


