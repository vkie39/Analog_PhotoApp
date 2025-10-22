import 'package:flutter/material.dart';
import 'package:flutter_application_sajindongnae/models/chat_list_model.dart';
import 'package:flutter_application_sajindongnae/component/chat_card.dart';
import 'package:flutter_application_sajindongnae/screen/chat/chat_detail.dart';


class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});
  
  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
} 

class _ChatListScreenState extends State<ChatListScreen> {
  final List<chatModel> dummyChattings = [
    chatModel(
      requestId: '1',
      requesterId: 'user11',
      requesterNickname: '스폰지밥',
      requesterProfileImageUrl: 'assets/icons/parrot.png',
      accepterId:'user22',
      dateTime: DateTime.now().subtract(const Duration(hours: 1)),
      lastChat: '사진 너무 마음에 들어여 짱'
    ),
    chatModel(
      requestId: '2',
      requesterId: 'user33',
      requesterNickname: '징징이',
      requesterProfileImageUrl: 'assets/icons/racon.jpg',
      accepterId:'user45',
      dateTime: DateTime.now().subtract(const Duration(hours: 1)),
      lastChat: '님 예술성이 부족한듯'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,    // 전체 배경색
      // AppBar: 뒤로가기 버튼, 제목
      appBar: AppBar(
        title: const Text('채팅', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),),
        centerTitle: true,                // 제목 가운데 정렬
        backgroundColor: Colors.white,  // AppBar 배경색
        foregroundColor: Colors.black,  // AppBar 글자색
        elevation: 0.5,                   // AppBar 그림자
        scrolledUnderElevation: 0,        // 스크롤 시 그림자 제거 (앱바가 스크롤에 가려질 때 그림자 제거) -> surfaceTintColor: Colors.transparent 도 동일한 효과
      ),
    
      body: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) {
          FocusManager.instance.primaryFocus?.unfocus();
        },
        // 구매탭 TODO : firebase 연동후 실시간 스트림으로 바꿔야 함
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          itemCount: dummyChattings.length,
          separatorBuilder: (_, __) =>
            const Divider(height: 1, color: Color(0xFFEFEFEF)),
          itemBuilder: (context, index) {
            final c = dummyChattings[index];
            return chatCard(
              chat: c,
              onTap: () {
                print("${c.requesterNickname} 과의 채팅 클릭됨");
              },
            );
          },
        ),
      ),
    );
  
  }
}