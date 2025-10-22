import 'package:flutter/material.dart';
import '../models/chat_list_model.dart';


class chatCard extends StatelessWidget {
  final chatModel chat;
  final VoidCallback? onTap;  // request 카드 클릭시 실행할 동작

  const chatCard({super.key, required this.chat, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,    // 왼쪽 정렬
          children: [
            // 프로필
            CircleAvatar(
              backgroundImage: NetworkImage(chat.requesterProfileImageUrl),
              radius: 18,
            ),

            // 텍스트 영역
            Expanded(         // Expanded는 프로필 이미지로 사용한 공간 제외 모두 쓰라는 의미
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // 대화 상대방 닉네임, 시간
                  Padding(
                    padding: const EdgeInsets.only(left:10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              chat.requesterNickname,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left:4.0),
                              child: Text(
                                _getTimeAgo(chat.dateTime),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color.fromARGB(255, 120, 119, 119),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height:4),

                        // 마지막 메세지
                        Text(
                          chat.lastChat,
                          style: const TextStyle(
                            fontSize: 12,
                          ),
                        ), 
                        const SizedBox(height:4),
                        
                      ],
                    ),
                  
                 ),

                ],
              )
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


