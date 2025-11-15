import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController idController = TextEditingController();
  final TextEditingController pwController = TextEditingController();

  String? idError;
  String? pwError;
  bool isLoading = false;

  // 아이디 형식(영문 시작, 영문/숫자, 6~20자) — 가입 화면과 규칙 맞추기
  final _idRegex = RegExp(r'^[A-Za-z][A-Za-z0-9]{5,19}$');

  void _validateId(String v) {
    if (v.isEmpty) {
      idError = '아이디를 입력하세요.';
    } else if (!_idRegex.hasMatch(v)) {
      idError = '영문으로 시작, 영문/숫자 6~20자';
    } else {
      idError = null;
    }
    setState(() {});
  }

  void _validatePw(String v) {
    if (v.isEmpty) {
      pwError = '비밀번호를 입력하세요.';
    } else if (v.length < 6) {
      pwError = '비밀번호는 6자 이상';
    } else {
      pwError = null;
    }
    setState(() {});
  }

  bool get _formOK =>
      idController.text.isNotEmpty &&
          pwController.text.isNotEmpty &&
          idError == null &&
          pwError == null;

  Future<void> _login() async {
    final rawId = idController.text.trim();
    final pw = pwController.text;

    //(1) 유효성 검사
    _validateId(rawId);
    _validatePw(pw);
    if (!_formOK) return;

    //(2) 관리자 계정 하드코딩으로 분리
    if (rawId == 'admin123' && pw == 'admin123') {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/admin');
      return;  // ⛔ 여기서 바로 종료 → 아래 Firestore/FirebaseAuth 안 타게
    }

    setState(() => isLoading = true);
    try {
      final idLower = rawId.toLowerCase();

      // 1) Firestore에서 아이디 → 이메일 조회
      final qs = await FirebaseFirestore.instance
          .collection('users')
          .where('id_lower', isEqualTo: idLower)
          .limit(1)
          .get();

      if (qs.docs.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('존재하지 않는 아이디입니다.')),
        );
        return;
      }

      final data = qs.docs.first.data();
      final email = (data['email'] as String?)?.trim();
      if (email == null || email.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이 아이디에 연결된 이메일이 없습니다.')),
        );
        return;
      }

      // 2) 이메일/비밀번호로 실제 로그인
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: pw,
      );

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final msg = switch (e.code) {
        'wrong-password'           => '비밀번호가 일치하지 않습니다.',
        'user-not-found'           => '계정을 찾을 수 없습니다.',
        'user-disabled'            => '해당 계정은 비활성화되어 있습니다.',
        'too-many-requests'        => '시도가 많습니다. 잠시 후 다시 시도하세요.',
        'network-request-failed'   => '네트워크 오류입니다. 인터넷 연결을 확인하세요.',
        _                          => e.message ?? '로그인에 실패했습니다.',
      };
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } on FirebaseException catch (e) {
      // Firestore 권한/네트워크 오류 등
      if (!mounted) return;
      final msg = (e.code == 'permission-denied')
          ? '아이디 조회 권한이 없습니다. Firestore 보안 규칙을 확인하세요.'
          : (e.message ?? '아이디 조회 중 오류가 발생했습니다.');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('알 수 없는 오류가 발생했습니다.')),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    idController.dispose();
    pwController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const gray = Color(0xFF808080);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    "사진 동네",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 35, fontWeight: FontWeight.w900,
                      color: Color(0xFFC2E19E),
                    ),
                  ),
                  const SizedBox(height: 50),

                  // 아이디
                  TextField(
                    controller: idController,
                    textInputAction: TextInputAction.next,
                    onChanged: _validateId,
                    decoration: InputDecoration(
                      hintText: '아이디 입력 (영문/숫자 6~20자)',
                      hintStyle: const TextStyle(color: gray, fontSize: 14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide(
                          color: (idError != null) ? Colors.red : const Color(0xFFC0C0C0),
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide(
                          color: (idError != null) ? Colors.red : Colors.black,
                          width: 1.5,
                        ),
                      ),
                      errorText: idError,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 비밀번호
                  TextField(
                    controller: pwController,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    onChanged: _validatePw,
                    onSubmitted: (_) => _formOK ? _login() : null,
                    decoration: InputDecoration(
                      hintText: '비밀번호 입력',
                      hintStyle: const TextStyle(color: gray, fontSize: 14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                      enabledBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.black, width: 1.5),
                      ),
                      errorText: pwError,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // 로그인 버튼
                  ElevatedButton(
                    onPressed: (_formOK && !isLoading) ? _login : null,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: (_formOK) ? const Color(0xFFDBEFC4) : const Color(0xFFE0E0E0),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: isLoading
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text("로그인하기"),
                  ),

                  const SizedBox(height: 15),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, '/signup'),
                        child: const Text('회원가입',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w300, color: gray)),
                      ),
                      Container(width: 1, height: 12, color: Colors.grey, margin: const EdgeInsets.symmetric(horizontal: 10)),
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, '/find_id'),
                        child: const Text('아이디 찾기',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w300, color: gray)),
                      ),
                      Container(width: 1, height: 12, color: Colors.grey, margin: const EdgeInsets.symmetric(horizontal: 10)),
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, '/find_password'),
                        child: const Text('비밀번호 찾기',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w300, color: gray)),
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
