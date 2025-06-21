import 'package:flutter/material.dart';

class SellWriteScreen extends StatelessWidget {
  const SellWriteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('사진 판매 작성'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              '사진 판매 글 작성 페이지입니다',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),

            // 아래는 이후에 사진 등록, 제목, 가격, 내용 작성 등의 위젯이 들어갈 자리입니다
            Text('사진, 제목, 가격, 내용 등의 입력 폼을 여기에 구성하세요.'),
          ],
        ),
      ),
    );
  }
}
