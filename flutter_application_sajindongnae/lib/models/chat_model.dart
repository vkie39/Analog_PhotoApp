//채팅방 단위의 모델

import 'message_model.dart';

class ChatModel {
  final String roomId;
  final List<String> members;
  final MessageModel? lastMessage;

  ChatModel({
    required this.roomId,
    required this.members,
    this.lastMessage,
  });

  factory ChatModel.fromMap(String roomId, Map<dynamic, dynamic> map) {
    return ChatModel(
      roomId: roomId,
      members: (map['members'] as Map?)?.keys.cast<String>().toList() ?? [],
      lastMessage: map['lastMessage'] != null
          ? MessageModel.fromMap(Map<dynamic, dynamic>.from(map['lastMessage']))
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'roomId': roomId,
      'members': {for (var m in members) m: true},
      'lastMessage': lastMessage?.toMap(),
    };
  }
}
