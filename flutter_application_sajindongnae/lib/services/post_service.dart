/// 게시글 관련 Firebase Firestore 작업을 처리하는 Service 클래스
/// - 게시글 생성 (create)
/// - 전체 게시글 조회
/// - 카테고리별 게시글 조회
/// 작성자 : 민채영

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';

class PostService {
  static final _firestore = FirebaseFirestore.instance;
  static final _postCollection = _firestore.collection('posts');

  /// 게시글 업로드
  static Future<void> createPost(PostModel post) async {
    print('!!파이어 스토어에 업로드 시작!!');
    await _postCollection.doc(post.postId).set({
      'userId': post.userId,
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
    print('!!파이어 스토어에 업로드 완료!!');

  }

  /// 전체 게시글 조회 (최신순 정렬)
  static Stream<List<PostModel>> getAllPosts() {
    return _postCollection
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
}
