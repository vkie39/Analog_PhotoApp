class PhotoModel {
  final String photoId;
  final String uid;
  final String nickname;
  final String profileImageUrl;
  final String? category;
  final int likeCount;
  final int commentCount;
  final DateTime dateTime;
  final String title;
  final String? description;
  final String imageUrl;
  final int price;
  final String? location;

  PhotoModel({
    required this.photoId,
    required this.uid,
    required this.nickname,
    required this.profileImageUrl,
    this.category,
    required this.likeCount,
    required this.commentCount,
    required this.dateTime,
    required this.title,
    this.description,
    required this.imageUrl,
    required this.price,
    this.location,
  });

  factory PhotoModel.fromMap(Map<String, dynamic> map) {
    return PhotoModel(
      photoId: map['photoId'],
      uid: map['uid'],
      nickname: map['nickname'],
      profileImageUrl: map['profileImageUrl'],
      category: map['category'],
      likeCount: map['likeCount'] ?? 0,
      commentCount: map['commentCount'] ?? 0,
      dateTime: DateTime.parse(map['dateTime']),
      title: map['title'],
      description: map['description'],
      imageUrl: map['imageUrl'],
      price: map['price'],
      location: map['location'],
    );
  }
}
