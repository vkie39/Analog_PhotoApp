import 'package:cloud_firestore/cloud_firestore.dart';

class PhotoTradeModel {
  final String? id;                     // 문서 ID (nullable로 변경해 더 유연하게)
  final String imageUrl;               // Storage 이미지 URL
  final int price;                     // 가격
  final String userId;                 // 작성자 UID (통일된 이름)
  final String nickname;          // 작성자 닉네임 (UI 캐싱용)
  final List<String> tags;            // 태그
  final bool isSold;                  // 판매 완료 여부
  final DateTime? createdAt;          // 생성일

  PhotoTradeModel({
    this.id,
    required this.imageUrl,
    required this.price,
    required this.userId,
    required this.nickname,
    required this.tags,
    required this.isSold,
    required this.createdAt,
  });

  // Firestore 문서 snapshot으로부터 객체 생성
  factory PhotoTradeModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PhotoTradeModel.fromDocument(data, doc.id);
  }

  // 일반 Map → 객체
  factory PhotoTradeModel.fromDocument(Map<String, dynamic> doc, String docId) {
    return PhotoTradeModel(
      id: docId,
      imageUrl: doc['imageUrl'] ?? '',
      price: doc['price'] ?? 0,
      userId: doc['userId'] ?? '',
      nickname: doc['nickname'] ?? '',
      tags: List<String>.from(doc['tags'] ?? []),
      isSold: doc['isSold'] ?? false,
      createdAt: (doc['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  // 객체 → Firestore 저장용 Map
  Map<String, dynamic> toMap() {
    return {
      'imageUrl': imageUrl,
      'price': price,
      'userId': userId,
      'nickname': nickname,
      'tags': tags,
      'isSold': isSold,
      'createdAt': createdAt,
    };
  }

  // 필드 일부만 변경하고 새로운 인스턴스 반환
  PhotoTradeModel copyWith({
    String? id,
    String? imageUrl,
    int? price,
    String? userId,
    String? userNickname,
    List<String>? tags,
    bool? isSold,
    DateTime? createdAt,
  }) {
    return PhotoTradeModel(
      id: id ?? this.id,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
      userId: userId ?? this.userId,
      nickname: userNickname ?? this.nickname,
      tags: tags ?? this.tags,
      isSold: isSold ?? this.isSold,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
