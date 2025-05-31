import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(
    home: MainPage(), 
  ));
}

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(child: Text("메인 페이지입니다")),
    );
  }
}
