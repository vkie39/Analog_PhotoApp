import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_sajindongnae/screen/mypage/setting/profileEdit.dart';
import 'package:flutter_application_sajindongnae/screen/mypage/setting/mypagePwfound.dart';
import 'package:flutter_application_sajindongnae/screen/mypage/setting/deleteAccount.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          '설정',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontSize: 20,
          ),
        ),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(0),
            children: [
              ListTile(
                title: const Text("프로필 설정"),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProfileEditScreen(),
                    ),
                  );
                },
              ),
              const Divider(),
              ListTile(
                title: const Text("비밀번호 변경"),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const mpPwfoundScreen()),
                  );
                },
              ),
              const Divider(),
              ListTile(
                title: const Text("로그아웃"),
                onTap: () {
                  _showLogoutDialog(context);
                },
              ),
              const Divider(),
              const SizedBox(height: 50),
            ],
          ),
          Positioned(
            bottom: 72,
            right: 32,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DeleteAccountScreen(),
                  ),
                );
              },
              child: const Text(
                "회원 탈퇴",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void _showLogoutDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: true, // 바깥 클릭 시 닫히도록
    builder:
        (_) => Dialog(
          backgroundColor: Colors.transparent, // 외부 영역 투명
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            height: 120,
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: Text(
                      '로그아웃 하시겠습니까?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                Divider(height: 1, color: Colors.grey[300]),
                SizedBox(
                  height: 50,
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            color: Colors.transparent,
                            child: Center(
                              child: Text(
                                '아니요',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Container(width: 1, color: Colors.grey[300]),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            // Todo : 실제 로그아웃 처리
                            
                          },
                          child: Container(
                            color: Colors.transparent,
                            child: Center(
                              child: Text(
                                '예',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
  );
}
