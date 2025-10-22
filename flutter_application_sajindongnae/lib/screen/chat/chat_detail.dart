import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:flutter_application_sajindongnae/models/request_model.dart';
import 'package:flutter_application_sajindongnae/screen/photo/request_detail.dart';

// 더미 메시지 모델 (내가 임시로 만든것)
class ChatMessage {
  final String id;
  final String senderId;
  final String text;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.createdAt,
  });
}

class ChatDetailScreen extends StatefulWidget {
  final RequestModel request; // 이전 화면에서 넘겨받음

  ChatDetailScreen({super.key, required this.request});  // firebase연동후엔 required this.requestId가 되어야 함
 
  @override
  _ChatDetailScreen createState() => _ChatDetailScreen();
}

class _ChatDetailScreen extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  // 현재 로그인한 사용자 uid 
  // TODO: 이거 나중에 전역변수로 바꿔야 할듯 
  String? get _myUid => FirebaseAuth.instance.currentUser?.uid;

  // 더미(임시) 대화 데이터들
  final List<ChatMessage> _messages = []; 

  // 의뢰글에서 받아온거 저장
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

    // 현재 사용자와 상대방 UID
    final otherUid = _requesterUid;
    final me = _myUid ?? 'dummy_me';

    // 더미 채팅 데이터 _messages
    _messages.addAll([
      ChatMessage(
        id: 'm1',
        senderId: me,
        text: '동미대 학식 바로 찍어드릴게여',
        createdAt: DateTime.now().subtract(const Duration(minutes: 3)),
      ),
      ChatMessage(
        id: 'm2',
        senderId: otherUid,
        text: '감사링 복받으셈',
        createdAt: DateTime.now().subtract(const Duration(minutes: 2, seconds: 40)),
      ),
    ]);

    // 화면 아래로 내려줌
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

  }
 
  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _openRequestDetail(){
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RequestDetailScreen(request: widget.request),
        // 만약 DB 설계에 따라 requestId만 넘겨야 하면 아래걸로 수정
        // builder: (_) => RequestDetailScreen(requestId: widget.request.requestId),
      ),
    );
  }
 
  // 화면을 포커스를 아래로 맞춰주는 함수(새로운 채팅이 올때 내려줘야 함)
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // 메세지 입력하고 버튼 누르면 _messages에 추가해줌 (이후엔 firestore에 저장하도록 수정해야 함)
  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final me = _myUid ?? 'dummy_me';

    setState(() {
      _messages.add(
        ChatMessage(
          id: 'local-${DateTime.now().millisecondsSinceEpoch}',
          senderId: me,
          text: text,
          createdAt: DateTime.now(),
        ),
      );
    });
    _messageController.clear();

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }
 
  @override
  Widget build(BuildContext context) {
    final otherName = _requesterNickname;

    return Scaffold(
      appBar: AppBar(
        title: Text(otherName.isNotEmpty? otherName: '채팅'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          // 상단 의뢰글 제목 명시
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child : Material(
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
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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

          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isMe = msg.senderId == (_myUid ?? 'dummy_me');  // 메세지 송신자가 나인지 확인해서, 나라면 오른쪽에 메세지 칸? 생성

                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                    padding: const EdgeInsets.all(12.0),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.72,
                    ),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.lightGreen[200] : Colors.grey[300],
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(12),
                        topRight: const Radius.circular(12),
                        bottomLeft: isMe ? const Radius.circular(12) : const Radius.circular(0),
                        bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(12),
                      ),
                    ),
                    child: Text(
                      msg.text,
                      style: const TextStyle(fontSize: 15, color: Colors.black),
                    ),
                  ),
                );
              },
            ),
          ),

          SafeArea( // 하단바 등을 피해서 배치
            top: false,
            child: 
              Padding(
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
                            borderRadius: BorderRadius.all(Radius.circular(24)),
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                        onSubmitted: (_) => _sendMessage(), // (_) 는 매개변수를 사용하지 않는다는 의미
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.send),
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