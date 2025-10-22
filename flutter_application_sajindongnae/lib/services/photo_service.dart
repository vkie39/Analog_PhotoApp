import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_application_sajindongnae/models/photo_model.dart';

/// 사진 판매 관련 Firestore + Storage 서비스
class PhotoService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;
  static final _storage = FirebaseStorage.instance;

  static final _photoCollection = _firestore.collection('photos');

  /// 판매글 생성
  static Future<void> createPhoto(PhotoModel photo) async {
    await _photoCollection.doc(photo.photoId).set(photo.toMap());
  }

  /// 판매글 스트림 가져오기 (실시간, 최신순, 제한 가능)
  static Stream<List<PhotoModel>> getPhotos({int limit = 20}) {
    return _photoCollection
        .orderBy('dateTime', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => PhotoModel.fromDocument(doc)).toList());
  }

  /// 특정 판매글 단일 조회
  static Future<PhotoModel?> getPhotoById(String photoId) async {
    final doc = await _photoCollection.doc(photoId).get();
    if (!doc.exists) return null;
    return PhotoModel.fromDocument(doc);
  }

  /// 좋아요 토글
  /// isLiked: 현재 상태(true면 좋아요 취소, false면 좋아요 추가)
  static Future<void> toggleLike(String photoId, {required bool isLiked}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("로그인이 필요합니다.");
    final uid = user.uid;

    final photoRef = _photoCollection.doc(photoId);

    await photoRef.update({
      'likedBy': isLiked
          ? FieldValue.arrayRemove([uid]) // 이미 눌렀으면 제거
          : FieldValue.arrayUnion([uid]), // 안 눌렀으면 추가
      'likeCount': FieldValue.increment(isLiked ? -1 : 1), // 카운트 동기화
    });
  }

  /// 판매글 삭제 (Firestore 문서 + Storage 이미지 동기 삭제)
  static Future<void> deletePhoto(PhotoModel photo) async {
    // Firestore 문서 삭제
    await _photoCollection.doc(photo.photoId).delete();

    // Storage 이미지 삭제
    if (photo.imageUrl.isNotEmpty) {
      try {
        final ref = _storage.refFromURL(photo.imageUrl);
        await ref.delete();
      } catch (e) {
        print("Storage 이미지 삭제 실패: $e");
      }
    }
  }

  /// 본인 글 여부 확인 (수정/삭제 권한 체크용)
  static bool isOwner(PhotoModel photo) {
    final user = _auth.currentUser;
    return user != null && user.uid == photo.uid;
  }
}
