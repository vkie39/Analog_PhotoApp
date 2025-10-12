import 'package:cloud_firestore/cloud_firestore.dart';

class PhotoModel {
  final String photoId;
  final String uid;
  final String nickname;
  final String profileImageUrl;
  final String title;
  final String imageUrl;
  final int price;
  final String description;
  final String location;
  final List<String> tags;
  final DateTime dateTime;
  final List<String> likedBy;
  final int likeCount;
  final int commentCount;
  final String category; //추가됨

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
    this.commentCount = 0,
    this.category = '', // 기본값
  });

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
      commentCount: data['commentCount'] ?? 0,
      category: data['category'] ?? '', //Firestore에서 category 읽기
    );
  }

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
      'commentCount': commentCount,
      'category': category, // Firestore 저장 시 포함
    };
  }
}
