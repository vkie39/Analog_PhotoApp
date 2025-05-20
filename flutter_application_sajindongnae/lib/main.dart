import 'package:flutter/material.dart';
import 'splash_screen.dart'; // 불러오기

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: SplashScreen(),  // 시작화면 설정
  ));
}

class MainPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(child: Text("메인 페이지입니다")),
    );
  }
}