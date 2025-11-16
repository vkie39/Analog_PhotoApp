import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class Message {
  final String id;
  final String senderId;
  final String? text;      // 텍스트
  final String? imageUrl;  // Firestore에 들어가는 이미지 URL
  final DateTime createdAt;

  Message({
    required this.id,
    required this.senderId,
    this.text,
    this.imageUrl,
    required this.createdAt,
  });

  /// Firestore → Message
  factory Message.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return Message(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      text: data['text'],
      imageUrl: data['imageUrl'],
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// Message → Firestore 저장용
  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'text': text,
      'imageUrl': imageUrl,
      'createdAt': createdAt,
    };
  }
  /// 텍스트 포함 여부
  bool get hasText => text != null && text!.trim().isNotEmpty;

  /// 이미지 포함 여부
  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;

  /// UI가 요구하는 msg.image (XFile) 제공
  XFile? get image {
    if (!hasImage) return null;
    return XFile(imageUrl!);  // Image.network 대신 UI는 XFile을 사용하므로 이렇게 맞춤
  }
}
