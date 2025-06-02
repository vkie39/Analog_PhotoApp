import 'package:flutter/material.dart';
import 'screen/post/list.dart';
import 'package:flutter_application_sajindongnae/screen/photo/photo_sell.dart';
import 'package:flutter_application_sajindongnae/screen/chat/chat_list.dart';
import 'package:flutter_application_sajindongnae/screen/mypage.dart';
import 'component/bottom_nav.dart'; // bottom_nav.dart에서 UI 분리한 하단바

void main() {
  runApp(const MyApp()); // MyApp 클래스부터 어플 시작
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MainPage(), // 시작 시 보여줄 화면
    );
  }
}

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

// 홈 화면 
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('홈 화면입니다'));
  }
}
