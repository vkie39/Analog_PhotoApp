import 'package:cloud_firestore/cloud_firestore.dart';
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
  final bool isFree; // 무료/유료 여부 추가
  final String location;
  final LatLng position;
  final List<String> bookmarkedBy;
  final String status;
  final String? acceptedBy;
  final List<String> likedBy;
  final int likeCount;
  final int reportCount; // ← 추가한 필드

  RequestModel({
    required this.requestId,
    required this.uid,
    required this.nickname,
    required this.profileImageUrl,
    this.category,
    required this.dateTime,
    required this.title,
    required this.description,
    required this.price,
    required this.isFree,
    required this.location,
    required this.position,
    required this.bookmarkedBy,
    this.status = 'pending', // 요청 상태 기본값 설정
    this.acceptedBy,
    this.likedBy = const [],
    this.likeCount = 0,
    this.reportCount = 0, // ← 추가한 필드 기본값 설정
  });

  factory RequestModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    final geo = map['position'];
    LatLng latLng;
    if (geo is GeoPoint) {
      latLng = LatLng(geo.latitude, geo.longitude);
    } else if (geo is Map<String, dynamic>) {
      latLng = LatLng(geo['lat'], geo['lng']);
    } else {
      latLng = const LatLng(0, 0);
    }

    return RequestModel(
      requestId: docId ?? map['requestId'] ?? '',
      uid: map['uid'] ?? '',
      nickname: map['nickname'] ?? '',
      profileImageUrl: map['profileImageUrl'] ?? '',
      category: map['category'],
      dateTime:
          (map['dateTime'] is Timestamp)
              ? (map['dateTime'] as Timestamp).toDate()
              : DateTime.now(),
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      price: map['price'] ?? 0,
      isFree: map['isFree'] ?? false, // 추가
      location: map['location'] ?? '',
      position: latLng,
      bookmarkedBy: List<String>.from(map['bookmarkedBy'] ?? []),
      status: map['status'] ?? 'pending',
      acceptedBy: map['acceptedBy'],
      likedBy: List<String>.from(map['likedBy'] ?? []),
      likeCount: map['likeCount'] ?? 0,
      reportCount: map['reportCount'] ?? 0, // ← 추가한 필드
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'requestId': requestId,
      'uid': uid,
      'nickname': nickname,
      'profileImageUrl': profileImageUrl,
      'category': category,
      'dateTime': Timestamp.fromDate(dateTime),
      'title': title,
      'description': description,
      'price': price,
      'isFree': isFree, // 추가
      'location': location,
      'position': GeoPoint(position.latitude, position.longitude),
      'bookmarkedBy': bookmarkedBy,
      'status': status,
      'acceptedBy': acceptedBy,
      'likedBy': likedBy,
      'likeCount': likeCount,
      'reportCount': reportCount, // ← 추가한 필드
    };
  }
}
