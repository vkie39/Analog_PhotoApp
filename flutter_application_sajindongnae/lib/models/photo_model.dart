imporct 'package:cloud_firestore/cloud_firestore.dart';

/// 사진 판매 게시글 모델
/// Firestore 'photos' 컬렉션의 문서 구조를 정의
class PhotoModel {
  final String photoId;            // 문서 ID
  final String uid;                // 작성자 UID
  final String nickname;           // 작성자 닉네임
  final String profileImageUrl;    // 작성자 프로필 이미지
  final String title;              // 사진 제목
  final String imageUrl;           // 사진 이미지 URL
  final int price;                 // 가격
  final String description;        // 추가 설명 (nullable → 기본값 "")
  final String location;           // 위치 (nullable → 기본값 "")
  final List<String> tags;         // 태그 리스트
  final DateTime dateTime;         // 업로드 시간
  final List<String> likedBy;      // 좋아요 누른 사용자 UID 리스트
  final int likeCount;             // 좋아요 수 (캐싱용)

  PhotoModel({
    required this.photoId,
    required this.uid,
    required this.nickname,
    required this.profileImageUrl,
    required this.title,
    required this.imageUrl,
    required this.price,
    this.description = '',
    this.location = '',
    this.tags = const [],
    required this.dateTime,
    this.likedBy = const [],
    this.likeCount = 0,
  });

  /// Firestore Document → Model 변환
  factory PhotoModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return PhotoModel(
      photoId: doc.id,
      uid: data['uid'] ?? '',
      nickname: data['nickname'] ?? '익명',
      profileImageUrl: data['profileImageUrl'] ?? '',
      title: data['title'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      price: data['price'] ?? 0,
      description: data['description'] ?? '',
      location: data['location'] ?? '',
      tags: List<String>.from(data['tags'] ?? []),
      dateTime: (data['dateTime'] as Timestamp).toDate(),
      likedBy: List<String>.from(data['likedBy'] ?? []),
      likeCount: data['likeCount'] ?? 0,
    );
  }

  /// Model → Firestore 저장용 Map
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'nickname': nickname,
      'profileImageUrl': profileImageUrl,
      'title': title,
      'imageUrl': imageUrl,
      'price': price,
      'description': description,
      'location': location,
      'tags': tags,
      'dateTime': dateTime,
      'likedBy': likedBy,
      'likeCount': likeCount,
    };
  }
}
