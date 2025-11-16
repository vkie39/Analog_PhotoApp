import 'package:cloud_firestore/cloud_firestore.dart';

class ReportModel {
  final String reportId;       // 문서 ID
  final String postId;         // 신고 대상 게시글 ID
  final String postType;       // posts / requests / sells ...
  final String reporterId;     // 신고자 UID
  final String reason;         // 신고 사유
  final DateTime timestamp;    // 신고 시간

  ReportModel({
    required this.reportId,
    required this.postId,
    required this.postType,
    required this.reporterId,
    required this.reason,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'reportId': reportId,
      'postId': postId,
      'postType': postType,
      'reporterId': reporterId,
      'reason': reason,
      'timestamp': timestamp,
    };
  }

  factory ReportModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReportModel(
      reportId: data['reportId'],
      postId: data['postId'],
      postType: data['postType'],
      reporterId: data['reporterId'],
      reason: data['reason'],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }
}
