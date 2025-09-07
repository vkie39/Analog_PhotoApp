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

  Future<void> _login() async {
    final email = idController.text.trim();
    final password = passwordController.text.trim();

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message ?? '로그인에 실패했습니다.')));
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
              padding: const EdgeInsets.symmetric(
                horizontal: 32.0,
                vertical: 40.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
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
                  TextField(
                    controller: idController,
                    onChanged: (value) {
                      _validateId(value); // 아이디 유효성 검사
                      setState(() {
                        isIdFilled = value.isNotEmpty;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: '아이디 입력',
                      hintStyle: const TextStyle(
                        color: Color.fromARGB(255, 128, 128, 128),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide(
                          color:
                              idErrorText != null
                                  ? Colors.red
                                  : const Color(0xFFC0C0C0),
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide(
                          color:
                              idErrorText != null ? Colors.red : Colors.black,
                          width: 1.5,
                        ),
                      ),
                      errorText: idErrorText,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: '비밀번호 입력',
                      hintStyle: const TextStyle(
                        color: Color.fromARGB(255, 128, 128, 128),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 12,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: const BorderSide(
                          color: Colors.black,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  ElevatedButton(
                    onPressed: isFormFilled ? _login : null,
                    style: ButtonStyle(
                      elevation: MaterialStateProperty.all(0),
                      backgroundColor: MaterialStateProperty.resolveWith<Color>(
                        (Set<MaterialState> states) {
                          if (states.contains(MaterialState.disabled)) {
                            return const Color(0xFFE0E0E0);
                          }
                          return const Color(0xFFDBEFC4);
                        },
                      ),
                      foregroundColor: MaterialStateProperty.resolveWith<Color>(
                        (Set<MaterialState> states) {
                          if (states.contains(MaterialState.disabled)) {
                            return const Color.fromARGB(255, 82, 82, 82);
                          }
                          return Colors.black;
                        },
                      ),
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    child: const Text("로그인하기"),
                  ),
                  const SizedBox(height: 15),

                  // 회원가입 / 아이디 찾기 / 비밀번호 찾기
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/signup');
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size(0, 0),
                          overlayColor: Colors.transparent,
                        ),
                        child: const Text(
                          '회원가입',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w300,
                            color: Color.fromARGB(255, 128, 128, 128),
                          ),
                        ),
                      ),

                      Container(
                        width: 1,
                        height: 12,
                        color: Colors.grey,
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                      ),

                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context, 
                            MaterialPageRoute(
                              builder: (context) => const FindAccountScreen(initialTab: 0),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size(0, 0),
                          overlayColor: Colors.transparent,
                        ),
                        child: const Text(
                          '아이디 찾기',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w300,
                            color: Color.fromARGB(255, 128, 128, 128),
                          ),
                        ),
                      ),

                      Container(
                        width: 1,
                        height: 12,
                        color: Colors.grey,
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                      ),

                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const FindAccountScreen(initialTab: 1),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size(0, 0),
                          overlayColor: Colors.transparent,
                        ),
                        child: const Text(
                          '비밀번호 찾기',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w300,
                            color: Color.fromARGB(255, 128, 128, 128),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  // 소셜 로그인 구분선
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
                  const SizedBox(height: 20),
                  // 구글 로그인
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      side: const BorderSide(
                        color: Color.fromARGB(255, 192, 192, 192),
                      ),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Center(
                      child: Text(
                        "Google로 시작하기",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 7),
                  // 마이크로소프트 로그인
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      side: const BorderSide(
                        color: Color.fromARGB(255, 192, 192, 192),
                      ),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Center(
                      child: Text(
                        "Mycrosoft로 시작하기",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
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
