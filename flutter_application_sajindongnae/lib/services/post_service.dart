/// 게시글 관련 Firebase Firestore 작업을 처리하는 Service 클래스
/// - 게시글 생성 (create)
/// - 전체 게시글 조회
/// - 카테고리별 게시글 조회

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:developer';


class PostService {
  static final _firestore = FirebaseFirestore.instance;
  static final _postCollection = _firestore.collection('posts');

  /// 게시글 업로드
  static Future<void> createPost(PostModel post) async {
    log('!!파이어 스토어에 업로드 시작!!');
    await _postCollection.doc(post.postId).set({
      'uId': post.uId,
      'nickname': post.nickname,
      'profileImageUrl': post.profileImageUrl,
      'category': post.category,
      'likeCount': post.likeCount,
      'commentCount': post.commentCount,
      'createdAt': Timestamp.fromDate(post.timestamp), // ← DateTime을 Timestamp로 변환
      'title': post.title,
      'content': post.content,
      'imageUrl': post.imageUrl,
    });
    log('!!파이어 스토어에 업로드 완료!!');

  }
  /// 좋아요 기능
  static Future<void> updateLikeCount(String postId, int likeCount) async {
    await _postCollection.doc(postId).update({'likeCount': likeCount});
  }


  /// 전체 게시글 조회 (최신순 정렬)
  static Stream<List<PostModel>> getAllPosts() {
    return _postCollection
        //createdAt이 null인 문서 필터링
        .where('createdAt', isNotEqualTo: null)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PostModel.fromDocument(doc))
            .toList());
  }

  /// 카테고리별 게시글 조회
  static Stream<List<PostModel>> getPostsByCategory(String category) {
    return _postCollection
        .where('category', isEqualTo: category)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PostModel.fromDocument(doc))
            .toList());
  }

  /// 이미지 업로드 (Storage)
  static Future<String?> uploadImage(File imageFile, String postId) async {
    try {
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

  //게시글 수정
  static Future<void> updatePost(String postId, Map<String, dynamic> updatedData) async {
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
      log('✅ 이미지 삭제 완료');
    }

    // 2. Firestore 문서 삭제
    await _postCollection.doc(post.postId).delete();
    log('✅ 게시글 삭제 완료');

  } catch (e) {
    log('게시글/이미지 삭제 실패: $e');
    rethrow;
  }
}

  /// 좋아요 수 기준 상위 3개 게시글 스트림
  static Stream<List<PostModel>> getBestPostsStream() {
  return _postCollection
      .orderBy('likeCount', descending: true)
      .limit(3)
      .snapshots()
      .map((snapshot) =>
          snapshot.docs.map((doc) => PostModel.fromDocument(doc)).toList());
  }



}
