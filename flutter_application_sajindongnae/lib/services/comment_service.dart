import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/comment_model.dart';
import 'dart:io';
import 'dart:developer';


/// 댓글 관련 Firestore 작업을 처리하는 서비스 클래스
/// - 댓글 생성, 조회, 삭제
/// - 댓글 수(PostModel.commentCount) 자동 반영까지 포함
class CommentService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 특정 게시글(postId)에 댓글을 추가하는 함수
  /// - comments 서브컬렉션에 commentId 문서를 생성하고 데이터를 저장
  /// - 댓글 저장 후 해당 게시글의 commentCount도 +1 증가
  static Future<void> addComment(String postId, CommentModel comment) async {
    try {
      final commentRef = _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .doc(comment.commentId); // commentId는 외부에서 UUID 등으로 생성

      await commentRef.set(comment.toMap()); // 댓글 데이터 저장
      await _increaseCommentCount(postId);   // 댓글 수 +1 처리
      log('댓글 작성 완료: ${comment.commentId}');
    } catch (e) {
      log('댓글 작성 실패: $e');
      rethrow;
    }
  }

  /// 특정 게시글(postId)의 댓글 목록을 스트리밍으로 받아오는 함수
  /// - Firestore의 서브컬렉션: posts/{postId}/comments
  /// - timestamp 기준으로 내림차순 정렬 (최신 댓글이 위로)
  static Stream<List<CommentModel>> getComments(String postId) {
    return _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CommentModel.fromDocument(doc))
            .toList());
  }

  /// 특정 게시글(postId)의 특정 댓글(commentId)을 삭제하는 함수
  /// - 댓글 문서를 삭제하고, 댓글 수는 -1 감소
  static Future<void> deleteComment(String postId, String commentId) async {
    try {
      final commentRef = _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .doc(commentId);

      await commentRef.delete();           // 댓글 삭제
      await _decreaseCommentCount(postId); // 댓글 수 -1 처리
      log('댓글 삭제 완료: $commentId');
    } catch (e) {
      log('댓글 삭제 실패: $e');
      rethrow;
    }
  }

  /// 게시글의 commentCount 필드를 +1 증가시키는 내부 함수
  static Future<void> _increaseCommentCount(String postId) async {
    try {
      await _firestore.collection('posts').doc(postId).update({
        'commentCount': FieldValue.increment(1)
      });
    } catch (e) {
      log('댓글 수 증가 실패: $e');
    }
  }

  /// 게시글의 commentCount 필드를 -1 감소시키는 내부 함수
  static Future<void> _decreaseCommentCount(String postId) async {
    try {
      await _firestore.collection('posts').doc(postId).update({
        'commentCount': FieldValue.increment(-1)
      });
    } catch (e) {
      log('댓글 수 감소 실패: $e');
    }
  }
}
