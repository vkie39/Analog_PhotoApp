import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/photo_trade_model.dart';
import 'image_service.dart'; // 이미지 업로드 담당 서비스

class PhotoTradeService {
  static final _firestore = FirebaseFirestore.instance;
  static final _collection = _firestore.collection('photo_trades');

  /// 거래 게시글 업로드 (Storage + Firestore)
  static Future<void> uploadTradePost({
    required File imageFile,
    required int price,
    required List<String> tags,
  }) async {
    final user = FirebaseAuth.instance.currentUser!;
    final fileName = '${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    
    // Storage에 이미지 업로드
    final imageUrl = await ImageService.uploadImage(imageFile, 'photo_trades/$fileName');

    // Firestore에 글 저장
    final post = PhotoTradeModel(
      id: null,
      imageUrl: imageUrl,
      price: price,
      userId: user.uid,
      nickname: await _getNickname(user.uid),
      tags: tags,
      isSold: false,
      createdAt: DateTime.now(),
    );

    await _collection.add(post.toMap());
  }

  /// 특정 사용자의 게시글 목록 가져오기
  static Stream<List<PhotoTradeModel>> getPostsByUser(String userId) {
    return _collection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PhotoTradeModel.fromSnapshot(doc))
            .toList());
  }

  /// 전체 판매 게시글 스트리밍
  static Stream<List<PhotoTradeModel>> getAllPosts() {
    return _collection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PhotoTradeModel.fromSnapshot(doc))
            .toList());
  }

  /// 판매 완료 처리
  static Future<void> markAsSold(String postId) async {
    await _collection.doc(postId).update({'isSold': true});
  }

  /// 게시글 삭제
  static Future<void> deletePost(String postId) async {
    await _collection.doc(postId).delete();
  }

  /// 사용자 닉네임 가져오기 (users/{uid}에서)
  static Future<String> _getNickname(String uid) async {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return userDoc.data()?['nickname'] ?? 'Unknown';
  }
}
