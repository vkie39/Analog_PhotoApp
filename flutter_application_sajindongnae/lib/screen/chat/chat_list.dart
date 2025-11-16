import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Firestore 모델
import 'package:flutter_application_sajindongnae/models/chat_list_model.dart';
import 'package:flutter_application_sajindongnae/models/request_model.dart';

// 채팅 리스트 카드 위젯
import 'package:flutter_application_sajindongnae/component/chat_card.dart';

// 채팅 상세 페이지
import 'package:flutter_application_sajindongnae/screen/chat/chat_detail.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final currentUid = _auth.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          '채팅',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        scrolledUnderElevation: 0,
      ),

      // Firestore에서 채팅방 실시간 스트림 구독
      body: StreamBuilder<QuerySnapshot>(
        stream: _db
            .collection('chats')
            .orderBy('lastTimestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          // 로딩 상태 처리
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 데이터 없을 때
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            print('현재 로그인 UID: $currentUid');
            return const Center(child: Text('진행 중인 채팅이 없습니다.'));
          }

          // Firestore 문서를 ChatRoom 모델로 변환
          final chatRooms = snapshot.data!.docs
              .map((doc) => ChatRoom.fromDoc(doc))
              .toList();

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            itemCount: chatRooms.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: Color(0xFFEFEFEF)),
            itemBuilder: (context, index) {
              final room = chatRooms[index];

              return ChatCard(
                chatRoom: room,

                // 채팅방 클릭 시 처리
                onTap: () async {
                  final requestId = room.requestId;

                  // 의뢰글 Firestore에서 불러오기
                  final snap =
                      await _db.collection('requests').doc(requestId).get();

                  if (!snap.exists) {
                    print("의뢰글이 존재하지 않습니다: $requestId");
                    return;
                  }

                  // RequestModel로 변환
                  final request = RequestModel.fromMap(snap.data()!, snap.id);

                  // 채팅 상세 화면으로 이동
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatDetailScreen(
                        request: request, // 이제 정확한 RequestModel 전달
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
