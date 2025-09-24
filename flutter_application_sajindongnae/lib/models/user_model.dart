import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String nickname;
  final DateTime createdAt;
  final String? profileImageUrl; // 선택: 기본 null

  UserModel({
    required this.uid,
    required this.email,
    required this.nickname,
    required this.createdAt,
    this.profileImageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'nickname': nickname,
      'createdAt': Timestamp.fromDate(createdAt), // 🔹 안전하게 Timestamp 변환
      'profileImageUrl': profileImageUrl,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      nickname: map['nickname'] ?? '익명',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      profileImageUrl: map['profileImageUrl'],
    );
  }
}
