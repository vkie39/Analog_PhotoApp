import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_sajindongnae/screen/auth/Find_account.dart';

import 'screen/post/list.dart';
import 'package:flutter_application_sajindongnae/screen/photo/photo_sell.dart';
import 'package:flutter_application_sajindongnae/screen/chat/chat_list.dart';
import 'package:flutter_application_sajindongnae/screen/mypage.dart';
import 'package:flutter_application_sajindongnae/screen/home.dart';
import 'component/bottom_nav.dart';



// MainPage: 하단 탭을 클릭할 때 바뀌는 UI. 
// MaterialApp에서 MainPage를 분리하여 하단바 클릭시 MainPage만 리빌드 되도록 함

// 화면 상태를 바꾸려면 StatelessWidget이 아니라 StatefulWidget을 사용해야 함
class Default extends StatefulWidget {
  const Default({super.key});

  @override
  State<Default> createState() => _DefaultState(); // _MainPageState라는 상태 객체 생성. 위젯에 변경사항이 있을때 build()를 호출하여 새로운 UI를 생성하고, setState()를 호출하여 변경 사항을 화면에 반영함
}

class _DefaultState extends State<Default> {
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