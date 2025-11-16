import 'package:flutter/material.dart';
import '../models/chat_list_model.dart';  // ✅ ChatRoom 모델 import (기존 동일)

// 클래스명은 그대로 두어도 되지만, 대문자로 시작하는게 권장됨.
// 기존 chatModel → ChatRoom 으로 타입 변경
class ChatCard extends StatelessWidget {
  // chatModel → ChatRoom 으로 타입 변경
  final ChatRoom chatRoom; 
  final VoidCallback? onTap;  // 카드 클릭시 실행할 동작

  // 생성자도 ChatRoom으로 변경
  const ChatCard({super.key, required this.chatRoom, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start, // 왼쪽 정렬
          children: [
            // 프로필
            CircleAvatar(
              // 필드명 변경: chat → chatRoom, requesterProfileImageUrl 유지
              backgroundImage: NetworkImage(chatRoom.requesterProfileImageUrl),
              radius: 18,
            ),

            // 텍스트 영역
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 대화 상대방 닉네임, 시간
                  Padding(
                    padding: const EdgeInsets.only(left: 10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // 필드명 변경: chat → chatRoom, requesterNickname 유지
                            Text(
                              chatRoom.requesterNickname,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 4.0),
                              child: Text(
                                // dateTime → lastTimestamp 로 교체 (ChatRoom 구조 기준)
                                _getTimeAgo(chatRoom.lastTimestamp),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color.fromARGB(255, 120, 119, 119),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),

                        // 마지막 메시지
                        // 필드명 변경: lastChat → lastMessage
                        Text(
                          chatRoom.lastMessage,
                          style: const TextStyle(
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 글 작성 시간 포맷
  static String _getTimeAgo(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return '방금 전';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    return '${diff.inDays}일 전';
  }
}
