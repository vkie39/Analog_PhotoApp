import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/message_model.dart';
import '../models/chat_model.dart';

class ChatService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseDatabase.instance.ref();

  /// 두 UID를 정렬하여 고유한 채팅방 ID 생성
  String _makeRoomId(String uid1, String uid2) {
    final list = [uid1, uid2]..sort();
    return "${list[0]}_${list[1]}";
  }

  /// 메시지 전송
  Future<void> sendMessage({
    required String receiverId,
    required String text,
  }) async {
    final senderId = _auth.currentUser!.uid;
    final roomId = _makeRoomId(senderId, receiverId);
    final msgRef = _db.child("chats/$roomId/messages").push();

    final message = MessageModel(
      senderId: senderId,
      text: text,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );

    final updates = {
      "chats/$roomId/messages/${msgRef.key}": message.toMap(),
      "chats/$roomId/members/$senderId": true,
      "chats/$roomId/members/$receiverId": true,
      "user_chats/$senderId/$receiverId": true,
      "user_chats/$receiverId/$senderId": true,
      "chats/$roomId/lastMessage": message.toMap(),
    };

    await _db.update(updates);
  }

  /// 실시간 메시지 스트림
  Stream<List<MessageModel>> listenMessages(String receiverId) {
    final senderId = _auth.currentUser!.uid;
    final roomId = _makeRoomId(senderId, receiverId);
    final ref = _db.child("chats/$roomId/messages");

    return ref.onValue.map((event) {
      final data = event.snapshot.value as Map?;
      if (data == null) return [];
      final list = data.values.map((e) {
        return MessageModel.fromMap(Map<dynamic, dynamic>.from(e));
      }).toList();
      list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return list;
    });
  }

  /// 내가 대화한 사용자 목록
  Future<List<String>> getChatPartners() async {
    final uid = _auth.currentUser!.uid;
    final snapshot = await _db.child("user_chats/$uid").get();
    if (!snapshot.exists) return [];
    return (snapshot.value as Map).keys.cast<String>().toList();
  }

  /// 실시간 채팅방 리스트 스트림
  Stream<List<ChatModel>> listenChatRooms() {
    final uid = _auth.currentUser!.uid;
    final ref = _db.child("user_chats/$uid");

    return ref.onValue.asyncMap((event) async {
      if (!event.snapshot.exists) return [];

      final partnerIds = (event.snapshot.value as Map).keys.cast<String>().toList();
      final rooms = <ChatModel>[];

      for (final partnerId in partnerIds) {
        final roomId = _makeRoomId(uid, partnerId);
        final chatSnap = await _db.child("chats/$roomId").get();
        if (!chatSnap.exists) continue;
        final chat = ChatModel.fromMap(roomId, Map<dynamic, dynamic>.from(chatSnap.value as Map));
        rooms.add(chat);
      }

      rooms.sort((a, b) {
        final t1 = a.lastMessage?.timestamp ?? 0;
        final t2 = b.lastMessage?.timestamp ?? 0;
        return t2.compareTo(t1);
      });

      return rooms;
    });
  }
}
