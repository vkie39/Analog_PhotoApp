// chat_list_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// ChatRoom 클래스는 하나의 채팅방(대화 상대 단위)을 나타낸다.
/// Firestore 상위 컬렉션인 chats 문서를 반영한다.
/// 예시:
/// chats/{chatRoomId}
/// ├── participants: [userA_uid, userB_uid]
/// ├── requestId: "의뢰글 ID"
/// ├── lastMessage: "감사링 복받으셈"
/// ├── lastSenderId: "user11"
/// ├── lastTimestamp: Timestamp(...)
/// ├── requesterNickname: "스폰지밥"
/// ├── requesterProfileImageUrl: "https://~.png"
class ChatRoom {
  /// Firestore 문서 ID (chatRoomId)
  final String requestId;

  /// 채팅에 참여한 두 명의 UID
  final List<String> participants;
  final String chatRoomId; 

  /// 마지막 메시지 내용 (채팅 목록에서 미리보기용)
  final String lastMessage;

  /// 마지막 메시지를 보낸 사람 UID
  final String lastSenderId;

  /// 마지막 메시지 전송 시각
  final DateTime lastTimestamp;

  /// 대화 상대 닉네임 (UI 표시용)
  final String requesterNickname;

  /// 대화 상대 프로필 이미지 URL
  final String requesterProfileImageUrl;

  ChatRoom({
    required this.chatRoomId,
    required this.participants,
    required this.requestId,
    required this.lastMessage,
    required this.lastSenderId,
    required this.lastTimestamp,
    required this.requesterNickname,
    required this.requesterProfileImageUrl,
  });

  /// Firestore 문서 → ChatRoom 객체 변환
  factory ChatRoom.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return ChatRoom(
      chatRoomId: doc.id,
      participants: List<String>.from(data['participants'] ?? []),
      requestId: data['requestId'] ?? '',
      lastMessage: data['lastMessage'] ?? '',
      lastSenderId: data['lastSenderId'] ?? '',
      lastTimestamp: (data['lastTimestamp'] is Timestamp)
          ? (data['lastTimestamp'] as Timestamp).toDate()
          : DateTime.now(),
      requesterNickname: data['requesterNickname'] ?? '',
      requesterProfileImageUrl: data['requesterProfileImageUrl'] ?? '',
    );
  }

  /// ChatRoom 객체 → Firestore에 저장할 Map 형태
  Map<String, dynamic> toMap() {
    return {
      'participants': participants,
      'requestId': requestId,
      'lastMessage': lastMessage,
      'lastSenderId': lastSenderId,
      'lastTimestamp': lastTimestamp,
      'requesterNickname': requesterNickname,
      'requesterProfileImageUrl': requesterProfileImageUrl,
    };
  }
}
