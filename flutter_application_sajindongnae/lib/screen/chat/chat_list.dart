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
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
            //.where('participants', arrayContains: currentUid)
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

              // ChatCard에 ChatRoom 직접 전달
              return ChatCard(
                chatRoom: room,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatDetailScreen(
                        request: RequestModel(
                          requestId: room.requestId,
                          uid: room.lastSenderId,
                          nickname: room.requesterNickname,
                          title: room.lastMessage,
                          profileImageUrl: room.requesterProfileImageUrl,
                          dateTime: room.lastTimestamp,
                          description: '',
                          price: 0,
                          isFree: true,         
                          location: '',
                          position: const LatLng(0, 0),
                          bookmarkedBy: [],
                          
                        ),
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
