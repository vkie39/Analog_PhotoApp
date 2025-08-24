import 'package:flutter/material.dart'; // flutter 기본 UI 사용하기 위한 패키지 ex)MaterialAPP, Scaffold, Text 등
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
    return MaterialApp(                    // MaterialApp: Flutter앱의 최상위 위젯 트리, home 속성에는 보여줄 첫 화면
      debugShowCheckedModeBanner: false,   // 기본으로 보이는 배너 없앰
      navigatorKey: Globals.navigatorKey,  // 지금 사용x
      home: MainPage(),                    // 시작 시 보여줄 화면. MainPage를 따로 빼서 만든 건 로그인 여부에 따라 보여줄 화면을 달리하기 위함

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


// MainPage: 하단 탭을 클릭할 때 바뀌는 UI. 
// MaterialApp에서 MainPage를 분리하여 하단바 클릭시 MainPage만 리빌드 되도록 함
// 화면 상태를 바꾸려면 StatelessWidget이 아니라 StatefulWidget을 사용해야 함
class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState(); // _MainPageState라는 상태 객체 생성. 위젯에 변경사항이 있을때 build()를 호출하여 새로운 UI를 생성하고, setState()를 호출하여 변경 사항을 화면에 반영함
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;              // 기본은 홈화면을 가리키는 인덱스 0

  final List<Widget> _pages = const [
    HomeScreen(),
    ListScreen(),
    PhotoSellScreen(),
    ChatListScreen(),
    MyPageScreen(),
  ];

  void _onTap(int index) {             // 전달받은 인덱스를 currentIndex로 사용하는 함수 
    setState(() {                      // build()를 호출하여 수정된 상태로 UI를 다시 그림
      _currentIndex = index;            
    });
  }
  
  // 사용자가 하단바를 클릭할 때마다 아래 build가 실행됨
  // 1. body의 내용이 선택된 _currentIndex에 따라 _pages[_currentIndex]로 바뀜
  // 2. BottomNav의 build 실행 -> 선택된 아이콘의 색상이 바뀜
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],     // _pages에 정의된 화면 중 선택된 것을 body에 보여줌
      bottomNavigationBar: BottomNav(  // 하단바 위젯 생성 (component/bottom_nav.dart에 정의됨, rebuild될 때 매번 새로 생성)
        currentIndex: _currentIndex,   // 어떤 탭이 선택되었는지 하단바 위젯에 전달함
        onTap: _onTap,                 // 콜백함수. BottomNav의 BottomNavigationBar 내부에서 탭 이벤트 발생 시 onTap
                                       // BottomNav가 부모인 MainPage에 onTap을 전달(선택된 items의 index도 함께). MainPage._onTap에서 setState발생
      ),
    );
  }
}
