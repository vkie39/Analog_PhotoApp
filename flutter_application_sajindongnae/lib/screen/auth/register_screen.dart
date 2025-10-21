import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'register_phoneNum.dart';

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

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nicknameController.dispose();
    super.dispose();
  }

  bool _validateInputs() {
    final email = emailController.text.trim();
    final pw = passwordController.text.trim();
    final nick = nicknameController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('올바른 이메일을 입력해 주세요.')),
      );
      return false;
    }
    if (pw.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('비밀번호는 6자 이상이어야 합니다.')),
      );
      return false;
    }
    if (nick.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('닉네임을 입력해 주세요.')),
      );
      return false;
    }
    return true;
  }

  Future<void> _register() async {
    if (!_validateInputs()) return;

    FocusScope.of(context).unfocus();
    setState(() => isLoading = true);
    try {
      // 1) Firebase Auth 회원가입
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      debugPrint('createUser OK: uid=${credential.user?.uid}');

      // 2) 화면 이동을 먼저 수행 (원인 분리)
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const RegisterPhoneNumScreen()),
      );

      // 3) Firestore 저장은 뒤에서 수행 (오류 나도 이동은 이미 됨)
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(credential.user!.uid)
            .set({
          'uid': credential.user!.uid,
          'email': emailController.text.trim(),
          'nickname': nicknameController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(), // 서버 시간 사용
          'providers': ['password'],
        }, SetOptions(merge: true));
        debugPrint('Firestore set OK');
      } catch (fe, st) {
        debugPrint('Firestore set error: $fe\n$st');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('프로필 저장 중 오류가 발생했지만 가입은 완료되었습니다.')),
          );
        }
      }
    } on FirebaseAuthException catch (e, st) {
      debugPrint('Register error: ${e.code} / ${e.message}\n$st');
      String msg = '회원가입 실패';
      if (e.code == 'email-already-in-use') msg = '이미 사용 중인 이메일입니다.';
      if (e.code == 'invalid-email') msg = '이메일 형식이 올바르지 않습니다.';
      if (e.code == 'weak-password') msg = '비밀번호가 너무 약합니다.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => isLoading = false);
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
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(labelText: '이메일'),
            ),
            TextField(
              controller: passwordController,
              obscureText: true,
              autofillHints: const [AutofillHints.password],
              decoration: const InputDecoration(labelText: '비밀번호 (6자 이상)'),
            ),
            TextField(
              controller: nicknameController,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(labelText: '닉네임'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: isLoading ? null : _register,
              child: isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('가입하기'),
            ),
          ],
        ),
      ),
    );
  }
}
