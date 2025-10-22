import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_sajindongnae/screen/mypage/setting/profileEdit.dart';


class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          '설정',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontSize: 20,
          ),
        ),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text("프로필 설정"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileEditScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            title: const Text("개인정보 관리"),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            title: const Text("알림 설정"),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}