import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/request_model.dart';

class RequestService {
  final CollectionReference _ref =
      FirebaseFirestore.instance.collection('requests');

  // 전체 의뢰글 스트림 조회 (실시간)
  Stream<List<RequestModel>> getRequests() {
    return _ref
        .orderBy('dateTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RequestModel.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ))
            .toList());
  }

  // 단일 의뢰글 조회
  Future<RequestModel?> getRequestById(String id) async {
    final doc = await _ref.doc(id).get();
    if (!doc.exists) return null;
    return RequestModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  // 함경민 추가 : 단일 의뢰글 실시간 스트림
  Stream<RequestModel?> watchRequest(String id) {
    return _ref.doc(id).snapshots().map((doc) {
      if (!doc.exists) return null;
      return RequestModel.fromMap(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    });

  }
  // 신규 의뢰글 등록
  Future<void> addRequest(RequestModel model) async {
    await _ref.doc(model.requestId).set(model.toMap());
  }

  // 의뢰글 수정
  Future<void> updateRequest(String id, Map<String, dynamic> data) async {
    await _ref.doc(id).update(data);
  }

  // 의뢰글 삭제
  Future<void> deleteRequest(String id) async {
    await _ref.doc(id).delete();
  }

  // 북마크 토글
  Future<void> toggleBookmark(String requestId, String uid) async {
    final docRef = _ref.doc(requestId);
    final doc = await docRef.get();
    if (!doc.exists) return;

    final data = doc.data() as Map<String, dynamic>;
    List<dynamic> bookmarkedBy = data['bookmarkedBy'] ?? [];

    if (bookmarkedBy.contains(uid)) {
      bookmarkedBy.remove(uid);
    } else {
      bookmarkedBy.add(uid);
    }

    await docRef.update({'bookmarkedBy': bookmarkedBy});
  }

  // 거래 수락
  Future<void> acceptRequest(String requestId, String accepterUid) async {
    await _ref.doc(requestId).update({
      'status': 'accepted',
      'acceptedBy': accepterUid,
      'acceptedAt': Timestamp.now(),
    });
  }

  // 거래 완료
  Future<void> completeRequest(String requestId) async {
    await _ref.doc(requestId).update({
      'status': 'completed',
      'completedAt': Timestamp.now(),
    });
  }

  // 좋아요 내역 (마이페이지용)
  Stream<List<RequestModel>> getLikedRequests(String uid) {
    return _ref
        .where('likedBy', arrayContains: uid)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RequestModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }
}
