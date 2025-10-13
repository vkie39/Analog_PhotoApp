import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter_application_sajindongnae/screen/auth/login.dart';
import 'signup_detail.dart';

class SignupStartScreen extends StatefulWidget {
  const SignupStartScreen({super.key});

  @override
  State<SignupStartScreen> createState() => _SignupStartScreenState();
}

class _SignupStartScreenState extends State<SignupStartScreen> {
  bool _isMsLoading = false;

  // 로그인 링크용 TapGestureRecognizer를 필드로 유지 후 dispose에서 해제
  late final TapGestureRecognizer _loginRecognizer;

  @override
  void initState() {
    super.initState();
    _loginRecognizer = TapGestureRecognizer()
      ..onTap = () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      };
  }

  @override
  void dispose() {
    _loginRecognizer.dispose(); // 메모리 누수 방지
    super.dispose();
  }

  /// Microsoft 계정으로 Firebase 로그인 (또는 신규 가입)
  Future<void> _signInWithMicrosoft() async {
    setState(() => _isMsLoading = true);
    try {
      // Firebase Auth의 OAuthProvider 사용 (microsoft.com)
      final provider = OAuthProvider('microsoft.com');

      // 기본 범위 (openid/profile/email) — 콘솔에도 등록 권장
      provider.addScope('openid');
      provider.addScope('profile');
      provider.addScope('email');
      // Graph API 예: provider.addScope('User.Read');

      // 허용 테넌트: common | consumers | organizations
      provider.setCustomParameters({'tenant': 'common'});

      // 통합 signInWithProvider
      final credential = await FirebaseAuth.instance.signInWithProvider(provider);
      final user = credential.user;

      if (user != null) {
        // Firestore 프로필 생성/갱신
        final users = FirebaseFirestore.instance.collection('users');
        final userRef = users.doc(user.uid);
        final snap = await userRef.get();

        final dataToMerge = {
          'uid': user.uid,
          'email': user.email,
          'nickname': user.displayName ?? '',
          'photoURL': user.photoURL,
          'provider': 'microsoft',
          if (!snap.exists) 'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        await userRef.set(dataToMerge, SetOptions(merge: true));

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microsoft 계정으로 로그인되었습니다.')),
        );

        // 추가정보 수집 화면으로 이동
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SignupDetailScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      var msg = e.message ?? '로그인 실패';
      if (e.code == 'account-exists-with-different-credential') {
        msg = '이미 다른 로그인 방식으로 가입된 이메일입니다. 기존 방식으로 로그인 후 계정 연결을 진행해 주세요.';
      } else if (e.code == 'operation-not-allowed') {
        msg = 'Firebase 콘솔에서 Microsoft 제공자 설정을 확인해 주세요.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Microsoft 로그인 실패: $msg')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Microsoft 로그인 중 오류: $e')),
      );
    } finally {
      if (mounted) setState(() => _isMsLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 시스템 UI(노치 등)를 피하기 위해 SafeArea 사용
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            // 키보드 대응 및 오버플로 방지
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    "처음 방문하셨나요?",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "회원가입을 위해 이메일을 입력해주세요",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
                  ),
                  const SizedBox(height: 25),

                  // 이메일로 시작하기
                  OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SignupDetailScreen(),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: const Color(0xFFDBEFC4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      side: BorderSide.none,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "이메일로 시작하기",
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  // 구분선
                  const Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          "  or  ",
                          style: TextStyle(
                            color: Color.fromARGB(255, 112, 112, 112),
                            fontWeight: FontWeight.w400,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),

                  const SizedBox(height: 25),

                  // Google (미구현 상태 - 주석 참고)
                  OutlinedButton(
                    onPressed: () {
                      // TODO: 구글 로그인 연결
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      side: const BorderSide(color: Color.fromARGB(255, 192, 192, 192)),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Google로 시작하기",
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 7),

                  // Microsoft 로그인
                  OutlinedButton(
                    onPressed: _isMsLoading ? null : _signInWithMicrosoft,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      side: const BorderSide(color: Color.fromARGB(255, 192, 192, 192)),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isMsLoading)
                            const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          if (_isMsLoading) const SizedBox(width: 8),
                          const Text(
                            "Microsoft로 시작하기",
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 로그인 이동 (RichText + TapGestureRecognizer)
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color.fromARGB(255, 128, 128, 128),
                        fontWeight: FontWeight.w300,
                      ),
                      children: [
                        const TextSpan(text: "이미 회원이신가요? "),
                        TextSpan(
                          text: " 로그인하기",
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w500,
                          ),
                          recognizer: _loginRecognizer,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 90),

                  // 비회원 진입: GestureDetector로 구현 (요청하신 방식)
                  GestureDetector(
                    onTap: () {
                      // 비회원 진입: 홈으로 이동 (라우트 이름은 프로젝트에 맞게)
                      Navigator.pushReplacementNamed(context, '/home');
                      // 또는 화면 클래스로 직접 이동하고 싶다면:
                      // Navigator.of(context).pushReplacement(
                      //   MaterialPageRoute(builder: (_) => const HomeScreen()),
                      // );
                    },
                    behavior: HitTestBehavior.translucent, // 작은 텍스트도 탭 잘 인식
                    child: const Text(
                      "건너뛰기",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Color.fromARGB(255, 185, 185, 185),
                        fontWeight: FontWeight.w300,
                      ),
                    ),
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
