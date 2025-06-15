import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String postId;
  final String uId;
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
    required this.uId,
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
    final map = doc.data() as Map<String, dynamic>; // Firestore 문서 데이터를 Map으로 캐스팅

    return PostModel(
      postId: doc.id, // Firestore의 문서 ID (문서 고유 식별자)

      // ↓ 필드가 null일 수 있으므로 기본값 처리 (null 대비)
      uId: map['uId'] ?? '',
      nickname: map['nickname'] ?? '',
      profileImageUrl: map['profileImageUrl'] ?? '',
      category: map['category'] ?? '',
      likeCount: map['likeCount'] ?? 0,
      commentCount: map['commentCount'] ?? 0,

      // createdAt이 null이거나 Timestamp가 아닐 경우 예외 발생 방지
      //    → 안전하게 타입 체크 후 변환, 없으면 현재 시각으로 대체
      timestamp: map['createdAt'] != null && map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(), // ← createdAt이 없거나 잘못된 경우 기본값 설정

      // ↓ 기본값 처리
      title: map['title'] ?? '',
      content: map['content'] ?? '',

      // ↓ 선택 필드: null 허용
      imageUrl: map['imageUrl'] as String?,
    );
  }


}


