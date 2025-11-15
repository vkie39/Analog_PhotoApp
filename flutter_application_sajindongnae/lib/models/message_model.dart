// message_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Message 클래스는 한 개의 채팅 메시지를 표현한다.
/// Firestore의 messages 서브컬렉션 문서 구조를 그대로 반영한다.
/// 예시:
/// chats/{chatRoomId}/messages/{messageId}
/// ├── senderId: "user11"
/// ├── text: "사진 감사합니다!"
/// ├── createdAt: Timestamp(...)
class Message {
  /// Firestore 문서의 ID (messageId)
  final String id;

  /// 메시지를 보낸 사용자의 UID
  final String senderId;

  /// 실제 메시지 내용
  final String text;

  /// 메시지가 생성된 시간 (Firestore Timestamp → DateTime으로 변환)
  final DateTime createdAt;

  Message({
    required this.id,
    required this.senderId,
    required this.text,
    required this.createdAt,
  });

  /// Firestore 문서 데이터를 Message 객체로 변환
  /// DocumentSnapshot → Message
  factory Message.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return Message(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      text: data['text'] ?? '',
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// Firestore에 저장할 때 사용되는 Map 형태
  /// Message → Map<String, dynamic>
  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'text': text,
      'createdAt': createdAt,
    };
  }
}
