import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:flutter_application_sajindongnae/screen/auth/login.dart';
import 'signup_detail.dart';

class SignupStartScreen extends StatefulWidget {
  const SignupStartScreen({super.key});

  @override
  State<SignupStartScreen> createState() => _SignupStartScreenState();
}

class _SignupStartScreenState extends State<SignupStartScreen> {
  bool _isMsLoading = false;
  bool _isGoogleLoading = false;

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
    _loginRecognizer.dispose();
    super.dispose();
  }

  /// Firestore 사용자 문서 upsert
  Future<void> _upsertUser(User user, {required String provider}) async {
    final users = FirebaseFirestore.instance.collection('users');
    final ref = users.doc(user.uid);
    final snap = await ref.get();
    final data = {
      'uid': user.uid,
      'email': user.email,
      'nickname': user.displayName ?? '',
      'photoURL': user.photoURL,
      'provider': provider,
      if (!snap.exists) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await ref.set(data, SetOptions(merge: true));
  }

  /// Google 계정으로 로그인/가입
  Future<void> _signInWithGoogle() async {
    setState(() => _isGoogleLoading = true);
    try {
      // 1) 구글 계정 선택
      final GoogleSignInAccount? gUser = await GoogleSignIn().signIn();
      if (gUser == null) {
        // 사용자가 취소
        return;
      }

      // 2) 토큰 가져오기
      final gAuth = await gUser.authentication;

      // 3) Firebase Auth 크레덴셜 생성
      final credential = GoogleAuthProvider.credential(
        accessToken: gAuth.accessToken,
        idToken: gAuth.idToken,
      );

      // 4) Firebase 로그인
      final result =
      await FirebaseAuth.instance.signInWithCredential(credential);

      // 5) Firestore upsert
      final user = result.user;
      if (user != null) {
        await _upsertUser(user, provider: 'google');

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google 계정으로 로그인되었습니다.')),
        );

        // 추가 정보 수집 화면으로
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SignupDetailScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      var msg = e.message ?? '로그인 실패';
      if (e.code == 'account-exists-with-different-credential') {
        msg =
        '이미 다른 로그인 방식으로 가입된 이메일입니다. 기존 방식으로 로그인 후 계정 연결을 진행해 주세요.';
      } else if (e.code == 'operation-not-allowed') {
        msg = 'Firebase 콘솔에서 Google 제공자 설정을 확인해 주세요.';
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Google 로그인 실패: $msg')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google 로그인 중 오류: $e')),
      );
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  /// Microsoft 계정으로 로그인/가입
  Future<void> _signInWithMicrosoft() async {
    setState(() => _isMsLoading = true);
    try {
      final provider = OAuthProvider('microsoft.com');
      provider.addScope('openid');
      provider.addScope('profile');
      provider.addScope('email');
      provider.setCustomParameters({'tenant': 'common'});

      final credential = await FirebaseAuth.instance.signInWithProvider(provider);
      final user = credential.user;

      if (user != null) {
        await _upsertUser(user, provider: 'microsoft');

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microsoft 계정으로 로그인되었습니다.')),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SignupDetailScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      var msg = e.message ?? '로그인 실패';
      if (e.code == 'account-exists-with-different-credential') {
        msg =
        '이미 다른 로그인 방식으로 가입된 이메일입니다. 기존 방식으로 로그인 후 계정 연결을 진행해 주세요.';
      } else if (e.code == 'operation-not-allowed') {
        msg = 'Firebase 콘솔에서 Microsoft 제공자 설정을 확인해 주세요.';
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Microsoft 로그인 실패: $msg')));
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
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

                  // OR 구분선
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

                  // Google
                  OutlinedButton(
                    onPressed: _isGoogleLoading ? null : _signInWithGoogle,
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
                          if (_isGoogleLoading)
                            const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          if (_isGoogleLoading) const SizedBox(width: 8),
                          const Text(
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

                  // Microsoft
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

                  // 하단 링크
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

                  // 비회원 진입
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacementNamed(context, '/home');
                    },
                    behavior: HitTestBehavior.translucent,
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
