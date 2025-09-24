import 'package:google_maps_flutter/google_maps_flutter.dart';

class RequestModel {
  final String requestId;
  final String uid;
  final String nickname;
  final String profileImageUrl;
  final String? category;
  final DateTime dateTime;
  final String title;
  final String description;
  final int price;
  final String location;
  final LatLng position;
  final List<String> bookmarkedBy; // 북마크한 uid 리스트

  RequestModel({
    required this.requestId,
    required this.uid,
    required this.nickname,
    required this.profileImageUrl,
    this.category,
    required this.dateTime,
    required this.title,
    required this.description,
    required this.price,         // 무료면 0 으로 저장
    required this.location,
    required this.position,
    required this.bookmarkedBy,
  });

  factory RequestModel.fromMap(Map<String, dynamic> map) {
    return RequestModel(
      requestId: map['requestId'],
      uid: map['uid'],
      nickname: map['nickname'],
      profileImageUrl: map['profileImageUrl'],
      category: map['category'],
      dateTime: DateTime.parse(map['dateTime']),
      title: map['title'],
      description: map['description'],
      price: map['price'],
      location: map['location'],
      position: map['position'],
      bookmarkedBy: map['bookmarkedBy'],
    );
  }
}