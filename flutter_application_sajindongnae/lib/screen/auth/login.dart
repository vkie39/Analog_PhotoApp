import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_sajindongnae/screen/auth/Find_account.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController idController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isIdFilled = false;
  bool isPasswordFilled = false;
  String? idErrorText;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    idController.addListener(() {
      setState(() {
        isIdFilled = idController.text.isNotEmpty;
      });
    });

    passwordController.addListener(() {
      setState(() {
        isPasswordFilled = passwordController.text.isNotEmpty;
      });
    });
  }

  void _validateId(String value) {
    String? error;
    final RegExp startsWithNumber = RegExp(r'^[0-9]');
    final RegExp allowed = RegExp(r'^[a-zA-Z][a-zA-Z0-9]*$');

    if (value.isEmpty) {
      error = "아이디를 입력해주세요.";
    } else if (startsWithNumber.hasMatch(value)) {
      error = "아이디는 영문자로 시작해야 합니다.";
    } else if (!allowed.hasMatch(value)) {
      error = "영문과 숫자만 사용할 수 있습니다.";
    } else if (value.length < 6) {
      error = "아이디는 최소 6자 이상이어야 합니다.";
    } else if (value.length > 20) {
      error = "아이디는 최대 20자까지 가능합니다.";
    } else {
      error = null;
    }

    setState(() {
      idErrorText = error;
    });
  }

  @override
  void dispose() {
    idController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // 아이디 기반 로그인 (Firestore 조회 → FirebaseAuth 로그인)
  Future<void> _login() async {
    final id = idController.text.trim();
    final password = passwordController.text.trim();

    // 1. 입력 확인
    print("로그인 시도: ID=$id, PW=${password.isEmpty ? '(비어있음)' : '(입력됨)'}");

    if (id.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('아이디와 비밀번호를 모두 입력해주세요.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 2. Firestore에서 이메일 찾기
      print("Firestore 쿼리 실행 중...");
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .where('id_lower', isEqualTo: id.toLowerCase())
          .limit(1)
          .get();

      print("Firestore 결과 문서 수: ${snap.docs.length}");
      if (snap.docs.isEmpty) {
        print("해당 아이디 없음");
        throw FirebaseAuthException(code: 'user-not-found', message: '존재하지 않는 아이디입니다.');
      }

      final userData = snap.docs.first.data();
      print("Firestore 문서 데이터: $userData");

      final email = (userData['email'] as String?)?.trim();
      print("Firestore에서 추출한 이메일: $email");

      if (email == null || email.isEmpty) {
        print("이메일 필드 없음 또는 비어 있음");
        throw FirebaseAuthException(code: 'invalid-email', message: '해당 계정의 이메일 정보가 없습니다.');
      }

      // 3. FirebaseAuth 로그인 시도
      print("FirebaseAuth 로그인 시도 중...");
      final credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      print("FirebaseAuth 로그인 성공");
      print("로그인된 UID: ${credential.user?.uid}");
      print("로그인된 이메일: ${credential.user?.email}");

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException catch (e) {
      // FirebaseAuth 단계에서 발생한 예외 (아이디, 비밀번호, 이메일 관련)
      print("FirebaseAuthException 발생: code=${e.code}, message=${e.message}");

      final msg = switch (e.code) {
        'user-not-found'     => '존재하지 않는 아이디입니다.',
        'wrong-password'     => '비밀번호가 올바르지 않습니다.',
        'invalid-email'      => '계정 정보가 올바르지 않습니다.',
        _                    => e.message ?? '로그인에 실패했습니다.',
      };

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      // 그 외 일반 예외 (Firestore 접근, Navigator, 연결 문제 등)
      print("일반 예외 발생: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인 중 오류가 발생했습니다.')),
      );
    } finally {
      print("로그인 프로세스 종료");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFormFilled = isIdFilled && isPasswordFilled;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    "사진 동네",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 35,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFC2E19E),
                    ),
                  ),
                  const SizedBox(height: 50),
                  // 아이디 입력
                  TextField(
                    controller: idController,
                    onChanged: (value) {
                      _validateId(value);
                      setState(() => isIdFilled = value.isNotEmpty);
                    },
                    decoration: InputDecoration(
                      hintText: '아이디 입력',
                      errorText: idErrorText,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // 비밀번호 입력
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: '비밀번호 입력',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    ),
                  ),
                  const SizedBox(height: 15),
                  // 로그인 버튼
                  ElevatedButton(
                    onPressed: (!_isLoading && isFormFilled) ? _login : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDBEFC4),
                      foregroundColor: Colors.black,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text("로그인하기"),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, '/signup'),
                        child: const Text('회원가입'),
                      ),
                      const SizedBox(width: 10),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const FindAccountScreen(initialTab: 0),
                            ),
                          );
                        },
                        child: const Text('아이디 찾기'),
                      ),
                      const SizedBox(width: 10),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const FindAccountScreen(initialTab: 1),
                            ),
                          );
                        },
                        child: const Text('비밀번호 찾기'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
