import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class UserService {
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  // 회원가입 직후 Firestore에 users/{uid} 문서를 생성
  // 현재 로그인한 유저의 uid를 키값으로 사용
  static Future<void> createUser({
    required String email,
    required String nickname,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("로그인이 필요합니다.");

    final newUser = UserModel(
      uid: user.uid,
      email: email,
      nickname: nickname,
      createdAt: DateTime.now(),
    );

    try {
      await _db.collection('users').doc(user.uid).set(newUser.toMap());
      log("유저 문서 생성 완료: ${user.uid}");
    } catch (e) {
      log("유저 문서 생성 실패: $e");
      rethrow;
    }
  }

  // 현재 로그인한 유저의 Firestore 문서를 가져옴
  static Future<UserModel?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _db.collection('users').doc(user.uid).get();
      if (!doc.exists) return null;
      return UserModel.fromMap(doc.data()!);
    } catch (e) {
      log("현재 유저 정보 불러오기 실패: $e");
      return null;
    }
  }

  // 특정 uid의 유저 문서를 가져옴
  static Future<UserModel?> getUserByUid(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (!doc.exists) return null;
      return UserModel.fromMap(doc.data()!);
    } catch (e) {
      log("유저 정보 불러오기 실패: $e");
      return null;
    }
  }

  // 닉네임 수정
  static Future<void> updateNickname(String uid, String newNickname) async {
    try {
      await _db.collection('users').doc(uid).update({'nickname': newNickname});
      log("닉네임 변경 완료");
    } catch (e) {
      log("닉네임 변경 실패: $e");
      rethrow;
    }
  }

  // 프로필 이미지 URL 수정
  static Future<void> updateProfileImage(String uid, String imageUrl) async {
    try {
      await _db.collection('users').doc(uid).update({'profileImageUrl': imageUrl});
      log("프로필 이미지 변경 완료");
    } catch (e) {
      log("프로필 이미지 변경 실패: $e");
      rethrow;
    }
  }
}
