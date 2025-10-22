import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String postId;
  final String uid;
  final String nickname;
  final String profileImageUrl;
  final String category;
  final int likeCount;
  final int commentCount;
  final DateTime timestamp;
  late final String title;
  late final String content;
  final String? imageUrl;

  // ✅ 변경: likedBy 추가 (좋아요 누른 uid 목록)
  final List<String> likedBy;

  PostModel({
    required this.postId,
    required this.uid,
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
      postId: doc.id,
      uid: map['uId'] ?? '',
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
      // ✅ 변경: likedBy 읽어오기
      likedBy: List<String>.from(map['likedBy'] ?? []),
    );
  }

  // factory PostModel.fromJson(Map<String, dynamic> json) {
  //   return PostModel(
  //     postId: json['postId'] ?? '',
  //     uid: json['uid'] ?? '',
  //     nickname: json['nickname'] ?? '',
  //     profileImageUrl: json['profileImageUrl'] ?? '',
  //     category: json['category'],
  //     likeCount: json['likeCount'] ?? 0,
  //     commentCount: json['commentCount'] ?? 0,
  //     timestamp: (json['timestamp'] as Timestamp).toDate(),
  //     title: json['title'] ?? '',
  //     content: json['content'],
  //     imageUrl: json['imageUrl'],
  //   );
  // }

  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PostModel(
      postId: doc.id,
      uid: data['uId'] ?? '',
      nickname: data['nickname'] ?? '',
      profileImageUrl: data['profileImageUrl'] ?? '',
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      likeCount: data['likeCount'] ?? 0,
      commentCount: data['commentCount'] ?? 0,
      timestamp: (data['createdAt'] as Timestamp).toDate(),
      category: data['category'] ?? '' // Firestore 문서 필드 확인
    );
  }


  // Firestore 저장용 (추가)
  Map<String, dynamic> toMap() {
    return {
      'uId': uid,
      'nickname': nickname,
      'profileImageUrl': profileImageUrl,
      'category': category,
      'likeCount': likeCount,
      'commentCount': commentCount,
      'createdAt': Timestamp.fromDate(timestamp),
      'title': title,
      'content': content,
      'imageUrl': imageUrl,
      'likedBy': likedBy, // ✅ 추가
    };
  }
}
