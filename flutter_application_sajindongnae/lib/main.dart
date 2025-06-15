import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screen/post/list.dart';
import 'package:flutter_application_sajindongnae/screen/photo/photo_sell.dart';
import 'package:flutter_application_sajindongnae/screen/chat/chat_list.dart';
import 'package:flutter_application_sajindongnae/screen/mypage.dart';
import 'package:flutter_application_sajindongnae/screen/auth/login_screen.dart';
import 'package:flutter_application_sajindongnae/screen/home.dart';
import 'component/bottom_nav.dart'; // bottom_nav.dart에서 UI 분리한 하단바

void main() async {
  // 앱 실행 전 firebase 초기화, 앱 루트 위젯으로 MyApp 실행
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp()); // MyApp 클래스부터 어플 시작
}

class Globals{ // 아직 쓸 지 안 쓸 지 모름
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
}

//Firebase 인증(Firebase Auth) 사용해서 사용자의 로그인 상태 실시간으로 감지
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp( //MaterialApp: Flutter앱의 최상위 위젯 트리, home 속성에 보여줄 첫 화면
      debugShowCheckedModeBanner: false,
      navigatorKey: Globals.navigatorKey, 
      home: MainPage(), // 시작 시 보여줄 화면
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


//MainPage: 하단 탭을 클릭할 때 바뀌는 UI. 
// 화면 상태를 바꾸려면 StatelessWidget이 아니라 StatefulWidget을 사용해야 함
class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomeScreen(),
    ListScreen(),
    PhotoSellScreen(),
    ChatListScreen(),
    MyPageScreen(),
  ];

  void _onTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNav(
        currentIndex: _currentIndex,
        onTap: _onTap,
      ),
    );
  }
}
