import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(
    home: MainPage(), // 이걸 반드시 넣어줘야 화면이 보임
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
