import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LikedsellScreen extends StatelessWidget {
  const LikedsellScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '판매사진 그리드',
        style: TextStyle(fontSize: 16),
      ),
    );
  }
}
