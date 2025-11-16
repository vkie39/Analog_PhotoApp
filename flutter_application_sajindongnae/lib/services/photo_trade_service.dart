import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../../models/photo_trade_model.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; 

class PhotoTradeService {
  final CollectionReference _ref =
      FirebaseFirestore.instance.collection('photo_trades');

  // 전체 판매글 실시간 조회
  Stream<List<PhotoTradeModel>> getPhotoTrades({required int limit}) {
    return _ref
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PhotoTradeModel.fromSnapshot(doc))
            .toList());
  }

  // 특정 사용자 판매글 조회
  Stream<List<PhotoTradeModel>> getUserTrades(String uid) {
    return _ref
        .where('uid', isEqualTo: uid)
        // .orderBy('createdAt', descending: true) // 복합 인덱스 필요
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PhotoTradeModel.fromSnapshot(doc))
            .toList());
  }

  // 단일 판매글 조회
  Future<PhotoTradeModel?> getTradeById(String id) async {
    final doc = await _ref.doc(id).get();
    if (!doc.exists) return null;
    return PhotoTradeModel.fromSnapshot(doc);
  }

  // 단일 판매글 조회 (Future -> stream 함경민 수정)
  Stream<PhotoTradeModel?> streamGetTradeById(String id)  {
    return _ref.doc(id).snapshots().map((doc){
      if (!doc.exists) return null;
      return PhotoTradeModel.fromSnapshot(doc);
    });
  }


  // 판매글 등록 (Storage 업로드 포함)
  Future<void> addTrade({
    
    required File imageFile,
    required String title,
    required String description,
    required int price,
    required String uid,
    required String nickname,
    required String profileImageUrl,
    required String location,
    required LatLng position,
    List<String>? tags,
  }) async {
    try {
      final tradeId = const Uuid().v4();

      // 🔹 파일 이름에 uid 포함
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('photo_trades/$uid/$tradeId.jpg');

      // Storage 업로드
      await storageRef.putFile(imageFile);
      final imageUrl = await storageRef.getDownloadURL();

      // Firestore 등록
      final newTrade = PhotoTradeModel(
        id: tradeId,
        uid: uid,
        nickname: nickname,
        profileImageUrl: profileImageUrl,
        imageUrl: imageUrl,
        title: title,
        description: description,
        price: price,
        isSold: false,
        buyerUid: null,
        tags: tags ?? [],
        createdAt: DateTime.now(),
        category: '판매',
        location: location,
        position: position,
      );

      await _ref.doc(tradeId).set(newTrade.toMap());
    } catch (e) {
      print("addTrade 실패: $e");
      rethrow;
    }
  }

  // 판매 상태 업데이트 (거래 완료)
  Future<void> updateTradeStatus(String id, bool isSold, {String? buyerUid}) async {
    await _ref.doc(id).update({
      'isSold': isSold,
      'buyerUid': buyerUid,
      'updatedAt': DateTime.now(),
    });
  }

  // 판매글 수정 (이미지 변경 가능)
  Future<void> updateTrade({
    required String tradeId,
    String? title,
    String? description,
    int? price,
    List<String>? tags,
    File? newImageFile, // 새 이미지 파일 있을 경우
    required String uid,
  }) async {
    try {
      final doc = await _ref.doc(tradeId).get();
      if (!doc.exists) throw Exception("해당 판매글이 존재하지 않습니다.");

      final data = doc.data() as Map<String, dynamic>;
      String imageUrl = data['imageUrl'];

      // 새 이미지가 있을 경우 Storage 업데이트
      if (newImageFile != null) {
        final oldImageRef = FirebaseStorage.instance.refFromURL(imageUrl);
        await oldImageRef.delete();

        final newImageRef = FirebaseStorage.instance
            .ref()
            .child('photo_trades/$uid/$tradeId.jpg');

        await newImageRef.putFile(newImageFile);
        imageUrl = await newImageRef.getDownloadURL();
      }

      // Firestore 필드 업데이트
      final updateData = {
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (price != null) 'price': price,
        if (tags != null) 'tags': tags,
        'imageUrl': imageUrl,
        'updatedAt': DateTime.now(),
      };

      await _ref.doc(tradeId).update(updateData);
      print("updateTrade 성공: $tradeId");
    } catch (e) {
      print("updateTrade 실패: $e");
      rethrow;
    }
  }


  // 판매글 삭제 (Storage 포함)
  Future<void> deleteTrade(String id, String uid) async {
    try {
      final doc = await _ref.doc(id).get();
      if (!doc.exists) return;
      final data = doc.data() as Map<String, dynamic>;
      final imageUrl = data['imageUrl'];

      // Storage 파일도 같이 삭제
      if (imageUrl != null && imageUrl.toString().isNotEmpty) {
        final ref = FirebaseStorage.instance.refFromURL(imageUrl);
        await ref.delete();
      }

      await _ref.doc(id).delete();
    } catch (e) {
      print("deleteTrade 실패: $e");
      rethrow;
    }
  }

  // 좋아요 내역 (마이페이지용)
  Stream<List<PhotoTradeModel>> getLikedTrades(String uid) {
    return _ref
        .where('likedBy', arrayContains: uid)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PhotoTradeModel.fromSnapshot(doc))
            .toList());
  }
}