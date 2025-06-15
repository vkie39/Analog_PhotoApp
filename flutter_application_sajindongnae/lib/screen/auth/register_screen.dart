import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../main.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nicknameController = TextEditingController();
  bool isLoading = false;

  Future<void> _register() async {
    setState(() => isLoading = true);
    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      await FirebaseFirestore.instance.collection('users').doc(credential.user!.uid).set({
        'uid': credential.user!.uid,
        'email': emailController.text.trim(),
        'nickname': nicknameController.text.trim(),
        'createdAt': DateTime.now(),
      });
      // 사용자는 회원가입 후 자동으로 로그인된 상태가 됩니다.
      // 홈 화면(MainPage)으로 이동하며 이전 화면 스택은 모두 제거합니다.
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainPage()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? '회원가입 실패')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('회원가입')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: '이메일'),
            ),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: '비밀번호'),
            ),
            TextField(
              controller: nicknameController,
              decoration: const InputDecoration(labelText: '닉네임'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: isLoading ? null : _register,
              child: isLoading
                  ? const CircularProgressIndicator()
                  : const Text('가입하기'),
            ),
          ],
        ),
      ),
    );
  }
}
