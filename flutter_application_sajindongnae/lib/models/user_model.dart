import 'package:cloud_firestore/cloud_firestore.dart';
class UserModel {
  final String userId;
  final String email;
  final String nickname;
  final DateTime createdAt;

  UserModel({
    required this.userId,
    required this.email,
    required this.nickname,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': userId,
      'email': email,
      'nickname': nickname,
      'createdAt': createdAt,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      userId: map['userId'],
      email: map['email'],
      nickname: map['nickname'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}
