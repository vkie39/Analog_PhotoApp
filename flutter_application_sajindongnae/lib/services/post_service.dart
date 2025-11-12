import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/post_model.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:developer';

class PostService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;
  static final _postCollection = _firestore.collection('posts');
  final _ref = FirebaseFirestore.instance.collection('posts');

  /// 게시글 업로드
   static Future<void> createPost(PostModel post) async {
    try {
      log('게시글 업로드 시작');
      await _postCollection.doc(post.postId).set(post.toMap());
      log('게시글 업로드 완료');
    } catch (e) {
      log('게시글 업로드 실패: $e');
      rethrow;
    }
  }

  // ///좋아요 토글 (중복 방지: likedBy 배열 기반)
  // static Future<void> toggleLike(String postId) async {
  //   final user = _auth.currentUser;
  //   if (user == null) throw Exception("로그인이 필요합니다.");
  //   final uid = user.uid;

  //   final postRef = _postCollection.doc(postId);

  //   await _firestore.runTransaction((transaction) async {
  //     final snapshot = await transaction.get(postRef);
  //     if (!snapshot.exists) return;

  //     final data = snapshot.data() as Map<String, dynamic>;
  //     final likedBy = List<String>.from(data['likedBy'] ?? []);
  //     int likeCount = data['likeCount'] ?? 0;

  //     if (likedBy.contains(uid)) {
  //       // 이미 눌렀으면 취소
  //       likedBy.remove(uid);
  //       likeCount = likeCount > 0 ? likeCount - 1 : 0;
  //     } else {
  //       // 새로 좋아요 추가
  //       likedBy.add(uid);
  //       likeCount += 1;
  //     }

  //     transaction.update(postRef, {'likedBy': likedBy, 'likeCount': likeCount});
  //   });

  //   log("좋아요 토글 완료: $postId");
  // }

  // 좋아요가 안 눌려서.. 수정 중
  // 좋아요가 눌리는 게시글도 있고 안 되는 게시글도 있는데 뭐가 문제임? 
  static Future<void> toggleLike(String postId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final docRef = FirebaseFirestore.instance.collection('posts').doc(postId);
    final snapshot = await docRef.get();
    final likedBy = List<String>.from(snapshot['likedBy'] ?? []);

    if (likedBy.contains(uid)) {
      await docRef.update({
        'likedBy': FieldValue.arrayRemove([uid]),
        'likeCount': FieldValue.increment(-1),
      });
    } else {
      await docRef.update({
        'likedBy': FieldValue.arrayUnion([uid]),
        'likeCount': FieldValue.increment(1),
      });
    }
  }

  /// 전체 게시글 조회 (최신순)
  static Stream<List<PostModel>> getAllPosts() {
    return _postCollection
    //createdAt이 null인 문서 필터링
        .where('createdAt', isNotEqualTo: null)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => PostModel.fromDocument(doc)).toList(),
        );
  }

  /// 카테고리별 게시글 조회
  /// 테스트 진행 중.. 
  // static Stream<List<PostModel>> getPostsByCategory(String category) {
  //   return _postCollection
  //       .where('category', isEqualTo: category)
  //       .orderBy('createdAt', descending: true)
  //       .snapshots()
  //       .map(
  //         (snapshot) =>
  //             snapshot.docs.map((doc) => PostModel.fromDocument(doc)).toList(),
  //       );
  // }

    // 기존 카테고리별 게시글 가져오기
  static Stream<List<PostModel>> getPostsByCategory(String category) {
    return FirebaseFirestore.instance
        .collection('posts')
        .where('category', isEqualTo: category)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => PostModel.fromFirestore(doc)).toList());
  }

  /// 이미지 업로드 (Storage)
  static Future<String?> uploadImage(File imageFile, String postId) async {
    try {
      log('이미지 업로드 시작: $postId, 경로: ${imageFile.path}');

      final ref = FirebaseStorage.instance
          .ref()
          .child('post_images')
          .child('$postId.jpg');

      await ref.putFile(imageFile);
      final downloadUrl = await ref.getDownloadURL();
      log('이미지 업로드 완료: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      log('이미지 업로드 실패: $e');
      return null;
    }
  }

  /// 게시글 수정
  static Future<void> updatePost(
    String postId,
    Map<String, dynamic> updatedData,
  ) async {
    try {
      await _postCollection.doc(postId).update(updatedData);
      log('게시글 수정 완료');

    } catch (e) {
      log('게시글 수정 실패: $e');
      rethrow;
    }
  }



  // 게시글 삭제 기능
  static Future<void> deletePostWithImage(PostModel post) async {
    try {
      // 1. 이미지가 있다면 Storage에서 삭제
      if (post.imageUrl != null && post.imageUrl!.isNotEmpty) {
        final ref = FirebaseStorage.instance.refFromURL(post.imageUrl!);
        await ref.delete();
        log('이미지 삭제 완료');
      }
      // 2. Firestore 문서 삭제
      await _postCollection.doc(post.postId).delete();
      log('게시글 삭제 완료');

    } catch (e) {
      log('게시글/이미지 삭제 실패: $e');
      rethrow;
    }
  }

  /// 좋아요 수 기준 상위 3개 게시글
  static Stream<List<PostModel>> getBestPostsStream() {
    return _postCollection
        .orderBy('likeCount', descending: true)
        .limit(3)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => PostModel.fromDocument(doc)).toList(),
        );
  }
  
  // 유저가 작성한 게시글 보기 (마이페이지용)
  static Stream<List<PostModel>> getPostsByUser(String uid) {
    return _firestore
        .collection('posts')
        .where('uId', isEqualTo: uid) //uid 키 확인
        // .orderBy('createdAt', descending: true) // 복합 인덱스 필요하다는데 그냥 멍..
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => PostModel.fromDocument(doc)).toList());
  }

  // 유저가 누른 좋아요 게시글 보기 (마이페이지용)
  Stream<List<PostModel>> getLikedPosts(String uid) {
  return _ref
      .where('likedBy', arrayContains: uid)
      .snapshots()
      .map((s) =>
          s.docs.map((d) => PostModel.fromDocument(d)).toList());
}

}
