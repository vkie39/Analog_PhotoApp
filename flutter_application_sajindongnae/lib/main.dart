import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_sajindongnae/screen/auth/Find_account.dart';

import 'screen/post/list.dart';
import 'package:flutter_application_sajindongnae/screen/photo/photo_sell.dart';
import 'package:flutter_application_sajindongnae/screen/chat/chat_list.dart';
import 'package:flutter_application_sajindongnae/screen/mypage.dart';

// import 'package:flutter_application_sajindongnae/screen/auth/login_screen.dart';

import 'package:flutter_application_sajindongnae/screen/auth/login.dart'; // 로그인 화면 (변경)
import 'package:flutter_application_sajindongnae/screen/auth/signup_start.dart'; // 회원가입 화면 (추가)
import 'package:flutter_application_sajindongnae/screen/auth/Idfound.dart'; // 아이디 찾는 화면
import 'package:flutter_application_sajindongnae/screen/auth/Pwfound.dart'; // 비밀번호 찾는 화면

import 'package:flutter_application_sajindongnae/screen/home.dart';
import 'component/bottom_nav.dart'; // bottom_nav.dart에서 UI 분리한 하단바

void main() async {
  // 앱 실행 전 firebase 초기화, 앱 루트 위젯으로 MyApp 실행
  WidgetsFlutterBinding.ensureInitialized(); // 바인딩/플러그인 초기화를 보장하여 비동기 작업을 안전하게 수행
  await Firebase.initializeApp();            // Firebase 전역 초기화 await로 초기화가 끝나기전에 다음으로 넘어가지 않도록 함
  runApp(const MyApp());                     // MyApp 클래스부터 어플 시작. runApp은 flutter프레임워크에 루트위젯을 전달하고, 위젯 트리를 화면에 렌더링함
}

class Globals{ // 아직 쓸 지 안 쓸 지 모름
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
}

// Firebase 인증(Firebase Auth) 사용해서 사용자의 로그인 상태 실시간으로 감지

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      //MaterialApp: Flutter앱의 최상위 위젯 트리, home 속성에 보여줄 첫 화면
      debugShowCheckedModeBanner: false,
      navigatorKey: Globals.navigatorKey,
      home: const LoginScreen(),

      // 화면 연결
      routes: {
        '/signup': (context) => const SignupStartScreen(),
        '/login': (context) => const LoginScreen(),
        '/find_account': (context) => const FindAccountScreen(),
        '/find_id':(context) => const IdfoundScreen(),
        '/find_password':(context) => const PwfoundScreen(),
      },

      //home: MainPage(), // 시작 시 보여줄 화면
      /*home: StreamBuilder<User?>(
        // authStateChanges()를 사용하여 Firebase 인증 상태의 변화를 감지
        stream: FirebaseAuth.instance.authStateChanges(), // 사용자가 로그인/로그아웃할 때마다 user 또는 null 반환
        builder: (context, snapshot) {
          // 로그인 상태 확인 중인 경우 로딩 중을 나타내는 circular progress indicator 표시
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // snapshot.hasData: 사용자가 로그인한 상태, MainPage로 이동
          if (snapshot.hasData) {
            return const MainPage();
          } else { // 로그인 안 되어 있으면 로그인 화면으로 이동
            return const LoginScreen();
          }
        },
      ),*/
    );
  }
}



