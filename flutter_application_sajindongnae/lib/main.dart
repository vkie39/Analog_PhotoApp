import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

// ⚠️ 실제 로그인 화면: 이 파일만 씁니다.
import 'package:flutter_application_sajindongnae/screen/auth/login.dart';

// 아래 라우트들은 프로젝트에 이미 있는 파일을 그대로 쓰세요.
import 'package:flutter_application_sajindongnae/screen/auth/Find_account.dart';
import 'package:flutter_application_sajindongnae/screen/auth/signup_start.dart';
import 'package:flutter_application_sajindongnae/screen/auth/Idfound.dart';
import 'package:flutter_application_sajindongnae/screen/auth/Pwfound.dart';
import 'package:flutter_application_sajindongnae/default.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final app = Firebase.app();
  debugPrint('🔥 Firebase projectId = ${(app.options as FirebaseOptions).projectId}');

  runApp(const MyApp());
}

class Globals {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: Globals.navigatorKey,
      home: const LoginScreen(),

      // 필요 라우트 연결
      routes: {
        '/signup': (context) => const SignupStartScreen(),
        '/login': (context) => const LoginScreen(),
        '/find_account': (context) => const FindAccountScreen(),
        '/find_id': (context) => const IdfoundScreen(),
        '/find_password': (context) => const PwfoundScreen(),
        '/home': (context) => const Default(), // 로그인 성공 후 이동
      },
    );
  }
}
