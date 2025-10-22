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

  bool isLoading = false;        // 가입 버튼 로딩
  bool isCheckingEmail = false;  // 이메일 중복확인 로딩

  // 이메일 정규식(Firebase 일반 포맷)
  final _emailRegex =
  RegExp(r'^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$');

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nicknameController.dispose();
    super.dispose();
  }

  // ---- 입력값 1차 검증 ----
  bool _validateInputs() {
    final email = emailController.text.trim();
    final pw = passwordController.text.trim();
    final nick = nicknameController.text.trim();

    if (email.isEmpty || !_emailRegex.hasMatch(email)) {
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

  // ---- 이메일 중복 확인 (Auth 기준) ----
  Future<void> _checkEmailDup() async {
    final email = emailController.text.trim();
    if (!_emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('유효한 이메일을 입력해 주세요.')),
      );
      return;
    }

    setState(() => isCheckingEmail = true);
    try {
      final methods =
      await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);

      if (methods.isNotEmpty) {
        // 이미 등록된 이메일 (password든 google.com이든 어떤 방식이든)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이미 사용 중인 이메일입니다. 가입 방식: ${methods.join(', ')}')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('사용 가능한 이메일입니다.')),
        );
      }
    } on FirebaseAuthException catch (e) {
      final msg = switch (e.code) {
        'invalid-email' => '이메일 형식이 올바르지 않습니다.',
        _ => e.message ?? '중복 확인 중 오류가 발생했습니다.',
      };
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => isCheckingEmail = false);
    }
  }

  // ---- 회원가입 ----
  Future<void> _register() async {
    if (!_validateInputs()) return;

    FocusScope.of(context).unfocus();
    setState(() => isLoading = true);
    try {
      // 최종 진실은 여기에서: 이미 있으면 email-already-in-use 발생
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      debugPrint('createUser OK: uid=${credential.user?.uid}');

      if (!mounted) return;
      // 다음 화면(휴대폰 번호 등록)으로 이동
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const RegisterPhoneNumScreen()),
      );

      // Firestore 프로필 저장(실패해도 가입은 완료된 상태)
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(credential.user!.uid)
            .set({
          'uid': credential.user!.uid,
          'email': emailController.text.trim(),
          'nickname': nicknameController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
          'providers': ['password'],
        }, SetOptions(merge: true));
        debugPrint('Firestore set OK');
      } catch (fe, st) {
        debugPrint('Firestore set error: $fe\n$st');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                Text('프로필 저장 중 오류가 발생했지만 가입은 완료되었습니다.')),
          );
        }
      }
    } on FirebaseAuthException catch (e, st) {
      debugPrint('Register error: ${e.code} / ${e.message}\n$st');
      String msg = '회원가입 실패';
      if (e.code == 'email-already-in-use') {
        msg = '이미 사용 중인 이메일입니다.';
      } else if (e.code == 'invalid-email') {
        msg = '이메일 형식이 올바르지 않습니다.';
      } else if (e.code == 'weak-password') {
        msg = '비밀번호가 너무 약합니다.';
      } else if (e.code == 'network-request-failed') {
        msg = '네트워크 오류입니다. 인터넷 권한/연결을 확인하세요.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
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
            // 이메일 + 중복확인 버튼
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(labelText: '이메일'),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: (isLoading || isCheckingEmail) ? null : _checkEmailDup,
                  child: isCheckingEmail
                      ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Text('중복 확인'),
                ),
              ],
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

            // 가입 버튼
            ElevatedButton(
              onPressed: isLoading ? null : _register,
              child: isLoading
                  ? const SizedBox(
                height: 20, width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Text('가입하기'),
            ),
          ],
        ),
      ),
    );
  }
}
