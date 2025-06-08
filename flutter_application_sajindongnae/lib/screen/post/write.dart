import 'package:flutter/material.dart';

class WriteScreen extends StatelessWidget {
  final String category;

  const WriteScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context); // 뒤로가기
          },
        ),
        title: Text(
          category,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              // 완료 버튼 클릭 시 처리 (나중에 저장 로직 추가)
              print('완료 버튼 클릭됨');
            },
            child: const Text(
              '완료',
              style: TextStyle(
                color: Colors.green, // 완료 텍스트 색상 (예시로 연두 계열)
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: const Center(
        child: Text(
          '글쓰기 내용 작성 공간',
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }
}
