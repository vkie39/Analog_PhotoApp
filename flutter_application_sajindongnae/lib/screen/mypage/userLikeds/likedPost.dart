import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LikedpostScreen extends StatelessWidget {
  const LikedpostScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '작성한 게시글 리스트',
        style: TextStyle(fontSize: 16),
      ),
    );
  }
}
