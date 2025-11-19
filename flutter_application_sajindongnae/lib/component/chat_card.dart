import 'package:flutter/material.dart';
import '../models/chat_list_model.dart';  // ✅ ChatRoom 모델 import (기존 동일)
import 'package:cloud_firestore/cloud_firestore.dart'; 

// 클래스명은 그대로 두어도 되지만, 대문자로 시작하는게 권장됨.
// 기존 chatModel → ChatRoom 으로 타입 변경
class ChatCard extends StatelessWidget {
  // chatModel → ChatRoom 으로 타입 변경
  final ChatRoom chatRoom; 
  final String currentUserUid;
  final VoidCallback? onTap;  // 카드 클릭시 실행할 동작

  // 생성자도 ChatRoom으로 변경
  const ChatCard({super.key, required this.chatRoom, required this.currentUserUid, this.onTap});

  // participants 중에서 "나"가 아닌 상대 uid 찾기
  String _getOtherUserUid() {
    if (chatRoom.participants.isEmpty) return currentUserUid;

    // 두 명 기준: 나가 아닌 사람
    return chatRoom.participants.firstWhere(
      (uid) => uid != currentUserUid,
      orElse: () => chatRoom.participants.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    final otherUid = _getOtherUserUid(); // 대화 상대방 ID

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users') // ⭐ users 컬렉션에서
          .doc(otherUid)
          .get(),
      builder: (context, snapshot) {
        // 기본값(혹시 못 불러왔을 때)
        String nickname = '알 수 없음';
        String? profileImageUrl;

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          nickname = data['nickname'] ?? nickname;        // 🔥 상대 닉네임
          profileImageUrl = data['profileImageUrl'];      // 🔥 상대 프로필 URL
        }

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start, // 왼쪽 정렬
          children: [
            // 프로필
            CircleAvatar(
                  radius: 18,
                  backgroundImage: (profileImageUrl != null &&
                          profileImageUrl.isNotEmpty)
                      ? NetworkImage(profileImageUrl!)
                      : null,
                  child: (profileImageUrl == null ||
                          profileImageUrl.isEmpty)
                      ? const Icon(Icons.person)
                      : null,
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
                                  nickname,
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
      },
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
