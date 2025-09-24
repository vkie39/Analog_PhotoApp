

// 하단바 



import 'package:flutter/material.dart';

class BottomNav extends StatelessWidget {  // BottomNav 위젯 정의. 고정된 UI를 그리기 때문에 StatelessWidget 상속
  final int currentIndex;                  // main.dart에서 _currentIndex를 받아 currentIndex에 저장
  final ValueChanged<int> onTap;           //콜백함수

  const BottomNav({ //생성자
    super.key,                   // 고유 식별자. 성능 최적화를 위해 필요
    required this.currentIndex,  // BottomNav를 만들때 필수로 받아야 함
    required this.onTap,         // 마찬가지 필수로 받아야 함
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey, width: 1.0), // 라인 효과
        ),
      ),
      child: BottomNavigationBar(
        backgroundColor: Colors.white,
        currentIndex: currentIndex,
        onTap: onTap,
        type: BottomNavigationBarType.fixed,                     // 고정된 크기 사용
        selectedItemColor: Color.fromARGB(255, 33, 165, 13),   // 선택되었을 때 스타일 
        unselectedItemColor: Colors.grey,                      // 선택되지 않았을 때 스타일
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: const [               // items에 각 버튼의 아이콘 모양과 라벨 이름 정의

          BottomNavigationBarItem(
            icon: ImageIcon(AssetImage('assets/icons/home_icon.png')),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: ImageIcon(AssetImage('assets/icons/post_icon.png')),
            label: '커뮤니티',
          ),
          BottomNavigationBarItem(
            icon: ImageIcon(AssetImage('assets/icons/photo_icon.png')),
            label: '사진거래',
          ),
          BottomNavigationBarItem(
            icon: ImageIcon(AssetImage('assets/icons/chat_icon.png')),
            label: '채팅',
          ),
          BottomNavigationBarItem(
            icon: ImageIcon(AssetImage('assets/icons/mypage_icon.png')),
            label: '마이페이지',
          ),
        ],
      ),
    );
  }
}
