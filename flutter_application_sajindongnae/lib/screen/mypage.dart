import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_application_sajindongnae/component/search.dart';


class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});
  
  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
} 


class _MyPageScreenState extends State<MyPageScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('마이페이지지'),),
    );
  }
}

/*
class _MyPageScreenState extends State<MyPageScreen> {
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('마이페이지'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          )
        ],
      ),
    );
  }
}
*/