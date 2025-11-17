import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/report_model.dart';

class ReportService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// 신고 등록 + 해당 게시글 신고 카운트 증가
  Future<void> submitReport({
    required String postId,
    required String postType, // posts / requests / sells
    required String reporterId,
    required String reason,
  }) async {
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
