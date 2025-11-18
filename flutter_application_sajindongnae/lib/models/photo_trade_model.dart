import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class PhotoTradeModel {
  final String? id; // 문서 ID (Firestore 자동 생성 or 수동)
  final String imageUrl; // Storage에 업로드된 이미지 URL
  final String title; // 사진 제목
  final String description; // 사진 설명
  final int price; // 판매 가격 (항상 0보다 큼)
  final String uid; // 판매자 UID
  final String nickname; // 판매자 닉네임
  final String profileImageUrl; // 판매자 프로필 이미지
  final bool isSold; // 판매 완료 여부
  final List<String> buyerUid; // 구매자 UID (거래 완료 시 저장)
  final List<String> tags; // 사진 태그 리스트
  final DateTime createdAt; // 업로드 시각
  final String category; // 사진 카테고리
  final String location; // 사진 촬영 장소
  final LatLng? position;
  final int reportCount; // 신고 횟수

  // -------------------------
  // 좋아요 기능 관련 필드 추가
  // likedBy  : 좋아요 누른 사용자 UID 목록
  // likeCount: 좋아요 수
  // 원래 없던 필드이며 SellDetail에서 좋아요 기능을 쓰기 위해 추가함
  // -------------------------
  final List<String> likedBy;
  final int likeCount;

  PhotoTradeModel({
    this.id,
    required this.imageUrl,
    required this.title,
    required this.description,
    required this.price,
    required this.uid,
    required this.nickname,
    required this.profileImageUrl,
    required this.isSold,
    this.buyerUid = const [],
    required this.tags,
    required this.createdAt,
    required this.category,
    required this.location,
    this.position,
    this.reportCount = 0,
    // -------------------------
    // [추가] 좋아요 기본값 설정 (nullable 제거)
    // null-safe 처리를 위해 기본값을 [] / 0으로 설정
    // -------------------------
    this.likedBy = const [],
    this.likeCount = 0,
  });

  // Firestore → Model 변환
  factory PhotoTradeModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PhotoTradeModel.fromMap(data, doc.id);
  }

  factory PhotoTradeModel.fromMap(Map<String, dynamic> data, [String? id]) {
    LatLng? latLng;
    final pos = data['position'];

    if (pos is GeoPoint) {
      latLng = LatLng(pos.latitude, pos.longitude);
    } else if (pos is Map<String, dynamic>) {
      latLng = LatLng(pos['lat'], pos['lng']);
    }

    // 🔹 imageUrl 이 String 이든 List 이든 안전하게 처리
    String _parseImageUrl(dynamic v) {
      if (v is String) return v;
      if (v is List && v.isNotEmpty) return v.first.toString();
      return '';
    }

    return PhotoTradeModel(
      id: id,
      imageUrl: _parseImageUrl(data['imageUrl']),
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      price: data['price'] ?? 0,
      uid: data['uid'] ?? '',
      nickname: data['nickname'] ?? '',
      profileImageUrl: data['profileImageUrl'] ?? '',
      isSold: data['isSold'] ?? false,

      buyerUid: data['buyerUid'] is String
          ? [data['buyerUid']]
          : List<String>.from(data['buyerUid'] ?? []),

      tags: List<String>.from(data['tags'] ?? []),
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      category: data['category'] ?? '판매',
      location: data['location'] ?? '',
      position: latLng,
      likedBy: List<String>.from(data['likedBy'] ?? []),
      likeCount: data['likeCount'] ?? 0,
      reportCount: data['reportCount'] ?? 0,
    );
  }


  // Model → Firestore 변환
  Map<String, dynamic> toMap() {
    return {
      'imageUrl': imageUrl,
      'title': title,
      'description': description,
      'price': price,
      'uid': uid,
      'nickname': nickname,
      'profileImageUrl': profileImageUrl,
      'isSold': isSold,
      'buyerUid': buyerUid,

      // -------------------------
      // [추가] 좋아요 관련 필드를 Firestore에 저장
      // -------------------------
      'likedBy': likedBy,
      'likeCount': likeCount,

      'tags': tags,
      'createdAt': Timestamp.fromDate(createdAt),
      'category': category,
      'location': location,
      if (position != null)
        'position': GeoPoint(position!.latitude, position!.longitude),
      'reportCount': reportCount,
    };
  }
}
