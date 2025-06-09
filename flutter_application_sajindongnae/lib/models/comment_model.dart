import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  final String commentId;
  final String postId;
  final String userId;
  final String nickname;
  final String profileImageUrl;
  final String content;
  final DateTime timestamp;

  CommentModel({
    required this.commentId,
    required this.postId,
    required this.userId,
    required this.nickname,
    required this.profileImageUrl,
    required this.content,
    required this.timestamp,
  });

  // Firestore에서 받아온 데이터를 CommentModel로 변환할 때 사용
  factory CommentModel.fromMap(Map<String, dynamic> map) {
    return CommentModel(
      commentId: map['commentId'] ?? '',
      postId: map['postId'] ?? '',
      userId: map['userId'] ?? '',
      nickname: map['nickname'] ?? '',
      profileImageUrl: map['profileImageUrl'] ?? '',
      content: map['content'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }

  // 반대로 객체를 JSON으로 변환할 때도 필요함 (댓글을 Firestore에 저장할 때)
  Map<String, dynamic> toMap() {
    return {
      'commentId': commentId,
      'postId': postId,
      'userId': userId,
      'nickname': nickname,
      'profileImageUrl': profileImageUrl,
      'content': content,
      'timestamp': timestamp,
    };
  }
}
