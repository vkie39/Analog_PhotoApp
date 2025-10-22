import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/chat_service.dart';
import '../../models/message_model.dart';
import '../../models/chat_model.dart';

class ChatTestPage extends StatefulWidget {
  const ChatTestPage({super.key});

  @override
  State<ChatTestPage> createState() => _ChatTestPageState();
}

class _ChatTestPageState extends State<ChatTestPage> {
  final chatService = ChatService();
  final auth = FirebaseAuth.instance;

  final receiverIdController = TextEditingController();
  final msgController = TextEditingController();

  List<MessageModel> messages = [];
  Stream<List<MessageModel>>? messageStream;

  void startChat() {
    final receiverId = receiverIdController.text.trim();
    if (receiverId.isEmpty) return;

    messageStream = chatService.listenMessages(receiverId);
    messageStream!.listen((msgs) {
      setState(() => messages = msgs);
    });
  }

  void sendMessage() async {
    final receiverId = receiverIdController.text.trim();
    final text = msgController.text.trim();
    if (text.isEmpty || receiverId.isEmpty) return;
    await chatService.sendMessage(receiverId: receiverId, text: text);
    msgController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final uid = auth.currentUser?.uid ?? "(로그인 필요)";
    return Scaffold(
      appBar: AppBar(title: const Text("DM 테스트")),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text("내 UID: $uid", style: const TextStyle(color: Colors.grey)),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: receiverIdController,
                  decoration: const InputDecoration(labelText: "상대 UID 입력"),
                ),
              ),
              ElevatedButton(onPressed: startChat, child: const Text("채팅 시작")),
            ]),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: messages.length,
                itemBuilder: (context, i) {
                  final msg = messages[i];
                  final isMine = msg.senderId == uid;
                  return Align(
                    alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 6),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isMine ? Colors.blue[100] : Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(msg.text),
                    ),
                  );
                },
              ),
            ),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: msgController,
                  decoration: const InputDecoration(hintText: "메시지 입력"),
                ),
              ),
              IconButton(icon: const Icon(Icons.send), onPressed: sendMessage),
            ]),
          ],
        ),
      ),
    );
  }
}
