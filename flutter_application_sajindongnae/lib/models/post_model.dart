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
  late final String title;
  late final String content;
  final String? imageUrl;

  // 변경: likedBy 추가 (좋아요 누른 uid 목록)
  final List<String> likedBy;

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
    this.likedBy = const [], // 기본값: 빈 리스트
  });


  factory PostModel.fromDocument(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;

    return PostModel(
      postId: doc.id, // Firestore의 문서 ID (문서 고유 식별자)

      // ↓ 필드가 null일 수 있으므로 기본값 처리 (null 대비)
      uId: map['uId'] ?? '',
      nickname: map['nickname'] ?? '',
      profileImageUrl: map['profileImageUrl'] ?? '',
      category: map['category'] ?? '',
      likeCount: map['likeCount'] ?? 0,
      commentCount: map['commentCount'] ?? 0,
      timestamp: map['createdAt'] != null && map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      imageUrl: map['imageUrl'] as String?,
      // 변경: likedBy 읽어오기
      likedBy: List<String>.from(map['likedBy'] ?? []),
    );
  }

  // Firestore 저장용 (추가)
  Map<String, dynamic> toMap() {
    return {
      'uid': uId,
      'nickname': nickname,
      'profileImageUrl': profileImageUrl,
      'category': category,
      'likeCount': likeCount,
      'commentCount': commentCount,
      'createdAt': Timestamp.fromDate(timestamp),
      'title': title,
      'content': content,
      'imageUrl': imageUrl,
      'likedBy': likedBy, // 추가
    };
  }
}

