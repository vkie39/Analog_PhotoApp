import 'package:cloud_firestore/cloud_firestore.dart';

/// 댓글 데이터를 표현하는 모델 클래스
/// Firestore의 posts/{postId}/comments/{commentId} 구조에 매핑됨
class CommentModel {
  final String commentId;         // 댓글 고유 ID (Firestore 문서 ID)
  final String userId;            // 댓글 작성자 UID
  final String nickname;          // 작성자 닉네임
  final String profileImageUrl;   // 작성자 프로필 이미지 URL
  final String content;           // 댓글 본문 내용
  final DateTime timestamp;       // 작성 시간 (클라이언트 시각 기준)

  CommentModel({
    required this.commentId,
    required this.userId,
    required this.nickname,
    required this.profileImageUrl,
    required this.content,
    required this.timestamp,
  });

  /// Firestore의 DocumentSnapshot을 CommentModel 객체로 변환
  /// - doc.id는 Firestore 문서 ID로, commentId로 사용
  /// - doc.data()는 댓글 본문 데이터 Map<String, dynamic> 형태로 받아옴
  factory CommentModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return CommentModel(
      commentId: doc.id,                                      // 문서 ID를 commentId로 사용
      userId: data['userId'] ?? '',                           // userId가 null일 경우 빈 문자열로 처리
      nickname: data['nickname'] ?? '',                       // nickname 기본값 처리
      profileImageUrl: data['profileImageUrl'] ?? '',         // 프로필 이미지 URL 기본값 처리
      content: data['content'] ?? '',                         // 댓글 내용 기본값 처리
      timestamp: (data['timestamp'] as Timestamp).toDate(),   // Firestore Timestamp → Dart DateTime 변환
    );
  }

  /// CommentModel 객체를 Firestore에 저장 가능한 Map 형태로 변환
  /// - Firestore에 저장 시 timestamp는 Timestamp.fromDate(...)로 명시적으로 변환
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'nickname': nickname,
      'profileImageUrl': profileImageUrl,
      'content': content,
      'timestamp': Timestamp.fromDate(timestamp), // DateTime을 Firestore에서 이해할 수 있는 Timestamp로 변환
    };
  }
}
