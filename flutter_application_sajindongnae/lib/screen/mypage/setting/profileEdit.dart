import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileEditScreen extends StatelessWidget {
  const ProfileEditScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          '프로필 설정',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontSize: 20,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // 프로필 사진
            CircleAvatar(
              radius: 50,
              backgroundImage: const NetworkImage(
                  'https://cdn-icons-png.flaticon.com/512/3135/3135715.png'),
            ),
            const SizedBox(height: 16),
            // 닉네임 입력
            TextField(
              decoration: InputDecoration(
                labelText: "닉네임",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // 닉네임/사진 저장 기능 추후 구현
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDBEFC4),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                "저장",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}