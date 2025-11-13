import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:flutter_application_sajindongnae/models/request_model.dart';
import 'package:flutter_application_sajindongnae/screen/photo/request_detail.dart';
import 'package:flutter_application_sajindongnae/models/message_model.dart'; // [추가됨] Firestore Message 모델

class ChatDetailScreen extends StatefulWidget {
  final RequestModel request; // 이전 화면에서 넘겨받음
  const ChatDetailScreen({super.key, required this.request});

  @override
  _ChatDetailScreen createState() => _ChatDetailScreen();
}

class _ChatDetailScreen extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String? get _myUid => FirebaseAuth.instance.currentUser?.uid;

  // Firestore 인스턴스 [추가됨]
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 채팅방 정보 [추가됨]
  late final String _chatRoomId;
  late final String _requestId;
  late final String _requesterUid;
  late final String _requesterNickname;
  late final String _requestTitle;

  @override
  void initState() {
    super.initState();

    _requestId = widget.request.requestId;
    _requesterUid = widget.request.uid;
    _requesterNickname = widget.request.nickname;
    _requestTitle = widget.request.title;

    // [추가됨] 채팅방 ID 생성 규칙 (두 UID 정렬 후 연결)
    final sortedIds = [_myUid ?? 'unknown', _requesterUid]..sort();
    _chatRoomId = sortedIds.join('_');
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  // 의뢰글 상세 페이지로 이동
  void _openRequestDetail() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RequestDetailScreen(request: widget.request),
      ),
    );
  }

  // 메시지 전송 함수 [수정됨 → Firestore write로 변경]
  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    final senderId = _myUid ?? 'unknown';

    final messageData = {
      'senderId': senderId,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    };

    try {
      // Firestore에 메시지 추가
      await _db
          .collection('chats')
          .doc(_chatRoomId)
          .collection('messages')
          .add(messageData);

      // 채팅방의 최근 메시지 갱신
      await _db.collection('chats').doc(_chatRoomId).update({
        'lastMessage': text,
        'lastSenderId': senderId,
        'lastTimestamp': FieldValue.serverTimestamp(),
      });

      _messageController.clear();
    } catch (e) {
      debugPrint('메시지 전송 오류: $e');
    }
  }

  // 메시지 실시간 구독 [추가됨]
  Stream<QuerySnapshot<Map<String, dynamic>>> _messageStream() {
    return _db
        .collection('chats')
        .doc(_chatRoomId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final otherName = _requesterNickname;

    return Scaffold(
      appBar: AppBar(
        title: Text(otherName.isNotEmpty ? otherName : '채팅'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // 상단 의뢰글 영역
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _openRequestDetail,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDFF1D5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF7BC67B), width: 1),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '의뢰글',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _requestTitle,
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: Colors.black87,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // [수정됨] StreamBuilder로 Firestore 메시지 실시간 표시
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _messageStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('아직 메시지가 없습니다.'));
                }

                final messages = snapshot.data!.docs
                    .map((doc) => Message.fromDoc(doc))
                    .toList();

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.jumpTo(
                        _scrollController.position.maxScrollExtent);
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.senderId == _myUid;

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            vertical: 4.0, horizontal: 8.0),
                        padding: const EdgeInsets.all(12.0),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.72,
                        ),
                        decoration: BoxDecoration(
                          color: isMe
                              ? Colors.lightGreen[200]
                              : Colors.grey[300],
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(12),
                            topRight: const Radius.circular(12),
                            bottomLeft: isMe
                                ? const Radius.circular(12)
                                : const Radius.circular(0),
                            bottomRight: isMe
                                ? const Radius.circular(0)
                                : const Radius.circular(12),
                          ),
                        ),
                        child: Text(
                          msg.text,
                          style: const TextStyle(
                              fontSize: 15, color: Colors.black),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // 입력창
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: '메시지를 입력하세요',
                        filled: true,
                        fillColor: Color(0xFFF3F4F6),
                        border: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius:
                              BorderRadius.all(Radius.circular(24)),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
