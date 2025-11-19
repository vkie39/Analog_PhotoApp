import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_sajindongnae/models/inquiry_model.dart';

class InquiryAnswerScreen extends StatefulWidget {
  final InquiryModel inquiry;

  const InquiryAnswerScreen({super.key, required this.inquiry});

  @override
  State<InquiryAnswerScreen> createState() => _InquiryAnswerScreenState();
}

class _InquiryAnswerScreenState extends State<InquiryAnswerScreen> {
  late TextEditingController _answerController;

  @override
  void initState() {
    super.initState();
    _answerController = TextEditingController(text: widget.inquiry.answer ?? '');
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _saveAnswer() async {
    final answerText = _answerController.text.trim();
    if (answerText.isEmpty) return;

    await FirebaseFirestore.instance
        .collection('inquiries')
        .doc(widget.inquiry.inquiryId)
        .update({
      'answer': answerText,
      'answeredAt': DateTime.now(),
      'isAnswered': true,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('답변이 저장되었습니다.')),
    );

    Navigator.pop(context); // 뒤로가기
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '문의 답변',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.black, // 텍스트 색상
          ),
        ),
        centerTitle: true, // 중앙 정렬
        backgroundColor: Colors.white, // 배경색 흰색
        elevation: 0, // 그림자 약간만
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('[${widget.inquiry.category}] ${widget.inquiry.title}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            Text('작성자 : ${widget.inquiry.nickname}',
                style: const TextStyle(fontSize: 14, color: Colors.black)),
            const SizedBox(height: 16),
            Text(widget.inquiry.content, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 24),
            const Text('답변 작성', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _answerController,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: '답변을 입력하세요',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.black, width: 1.5), // 클릭 시 검정
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: _answerController,
                builder: (context, value, child) {
                  final isEnabled = value.text.trim().isNotEmpty;
                  return ElevatedButton(
                    onPressed: isEnabled ? _saveAnswer : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isEnabled ? const Color(0xFF84AC57) : Colors.grey,
                      foregroundColor: isEnabled ? Colors.white : Colors.black54,
                    ),
                    child: const Text('저장'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
