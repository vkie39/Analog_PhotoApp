import 'package:cloud_firestore/cloud_firestore.dart';

class PhotoTradeModel {
  final String? id;                 // 문서 ID (Firestore 자동 생성 or 수동)
  final String imageUrl;            // Storage에 업로드된 이미지 URL
  final String title;               // 사진 제목
  final String description;         // 사진 설명
  final int price;                  // 판매 가격 (항상 0보다 큼)
  final String uid;                 // 판매자 UID
  final String nickname;            // 판매자 닉네임
  final String profileImageUrl;     // 판매자 프로필 이미지
  final bool isSold;                // 판매 완료 여부
  final String? buyerUid;           // 구매자 UID (거래 완료 시 저장)
  final List<String> tags;          // 사진 태그 리스트
  final DateTime createdAt;         // 업로드 시각
  final String category;           // 사진 카테고리
  final String location;           // 사진 촬영 장소
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
    this.buyerUid,
    required this.tags,
    required this.createdAt,
    required this.category,
    this.location = '',
  });

  // Firestore → Model 변환
  factory PhotoTradeModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PhotoTradeModel.fromMap(data, doc.id);
  }

  factory PhotoTradeModel.fromMap(Map<String, dynamic> data, [String? id]) {
    return PhotoTradeModel(
      id: id,
      imageUrl: data['imageUrl'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      price: data['price'] ?? 0,
      uid: data['uid'] ?? '',
      nickname: data['nickname'] ?? '',
      profileImageUrl: data['profileImageUrl'] ?? '',
      isSold: data['isSold'] ?? false,
      buyerUid: data['buyerUid'],
      tags: List<String>.from(data['tags'] ?? []),
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      category: data['category'] ?? '판매',
      location: data['location'] ?? '',
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
      'tags': tags,
      'createdAt': Timestamp.fromDate(createdAt),
      'category': category,
    };
  }
}
