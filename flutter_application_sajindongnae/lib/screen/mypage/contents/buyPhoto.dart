import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BuyPhotoScreen extends StatelessWidget {
  const BuyPhotoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '구매사진 그리드',
        style: TextStyle(fontSize: 16),
      ),
    );
  }
}
