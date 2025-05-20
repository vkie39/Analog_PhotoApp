// lib/splash_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'main.dart'; // 스플래시 후 이동할 페이지 (예시)

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(Duration(seconds: 2), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => MainPage()), // 여기에 원하는 페이지 연결
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFDFF0C1),
      body: Center(
        child: Image.asset('assets/images/Logo.jpg', width: 200),
      ),
    );
  }
}
