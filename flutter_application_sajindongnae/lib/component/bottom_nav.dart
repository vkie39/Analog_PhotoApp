

// 하단바 


import 'package:flutter/material.dart';

class BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap; //콜백함수

  const BottomNav({ //생성자
    super.key,
    required this.currentIndex,
    required this.onTap,
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
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Color.fromARGB(255, 33, 165, 13),
        unselectedItemColor: Colors.grey,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: const [
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
