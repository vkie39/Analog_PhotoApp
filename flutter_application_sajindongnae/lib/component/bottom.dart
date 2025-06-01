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
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      selectedFontSize: 12,
      unselectedFontSize: 12,
      items: const [
        BottomNavigationBarItem(
          icon: ImageIcon(AssetImage('assets/home_icon.png')),
          label: '홈',
        ),
        BottomNavigationBarItem(
          icon: ImageIcon(AssetImage('assets/post_icon.png')),
          label: '커뮤니티',
        ),
        BottomNavigationBarItem(
          icon: ImageIcon(AssetImage('assets/photo_icon.png')),
          label: '사진거래',
        ),
        BottomNavigationBarItem(
          icon: ImageIcon(AssetImage('assets/chat_icon.png')),
          label: '채팅',
        ),
        BottomNavigationBarItem(
          icon: ImageIcon(AssetImage('assets/mypage_icon.png')),
          label: '마이페이지',
        ),
      ],
    );
  }
}
