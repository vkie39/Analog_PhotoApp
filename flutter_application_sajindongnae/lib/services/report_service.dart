import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/report_model.dart';

class ReportService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// ⭐ 추가됨 : 해당 사용자가 이미 이 게시글을 신고했는지 확인
  Future<bool> hasReported(String postId, String userId) async {
    final existing = await _db
        .collection('reports')
        .where('postId', isEqualTo: postId)
        .where('reporterId', isEqualTo: userId)
        .limit(1)
        .get();

    return existing.docs.isNotEmpty;
  }

  /// 신고 등록 + 해당 게시글 신고 카운트 증가
  Future<void> submitReport({
    required String postId,
    required String postType, // posts / requests / sells
    required String reporterId,
    required String reason,
  }) async {

    /// ⭐ 추가됨 : 중복 신고 방지
    if (await hasReported(postId, reporterId)) {
      throw Exception("이미 신고한 게시글입니다.");
    }

    final String reportId = const Uuid().v4();

    final report = ReportModel(
      reportId: reportId,
      postId: postId,
      postType: postType,
      reporterId: reporterId,
      reason: reason,
      timestamp: DateTime.now(),
    );

    final reportRef = _db.collection('reports').doc(reportId);
    final postRef = _db.collection(postType).doc(postId);

    await _db.runTransaction((transaction) async {
      // 신고 기록 추가
      transaction.set(reportRef, report.toMap());

      // reportCount 증가
      transaction.update(postRef, {
        'reportCount': FieldValue.increment(1),
      });
    });
  }
}
