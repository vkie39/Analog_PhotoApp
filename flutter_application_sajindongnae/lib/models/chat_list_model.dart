// 진짜 보여주기 위한 임시 모델
// DB구조 신경 하나도 안쓰고 보여주는 용으로 만든거니까 신경쓰지 말고 만들어두면 알아서 프론트 수정할예정

// 채팅 리스트를 보여주기 위한 '임시' 채팅모델
class chatModel {
  final String requestId;
  final String requesterId;
  final String requesterNickname;
  final String requesterProfileImageUrl;
  final String accepterId;
  final DateTime dateTime;
  final String lastChat;

  chatModel({
    required this.requestId,
    required this.requesterId,
    required this.requesterNickname,
    required this.requesterProfileImageUrl,
    required this.accepterId,
    required this.dateTime,
    required this.lastChat,  
  });

    factory chatModel.fromMap(Map<String, dynamic> map) {
    return chatModel(
      requestId: map['requestId'],
      requesterId: map['requesterId'],
      requesterNickname: map['requesterNickname'],
      requesterProfileImageUrl: map['requesterProfileImageUrl'],
      accepterId: map['accepterId'],
      dateTime: DateTime.parse(map['dateTime']),
      lastChat: map['lastChat'],
    );
  }
}