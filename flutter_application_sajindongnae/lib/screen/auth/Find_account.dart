import 'package:flutter/material.dart';
import 'package:flutter_application_sajindongnae/screen/auth/Idfound.dart';
import 'package:flutter_application_sajindongnae/screen/auth/Pwfound.dart';

class FindAccountScreen extends StatefulWidget {
  final int initialTab; // 0 = 아이디 찾기, 1 = 비밀번호 찾기

  const FindAccountScreen({super.key, this.initialTab = 0});

  @override
  State<FindAccountScreen> createState() => _FindAccountScreenState();
}

class _FindAccountScreenState extends State<FindAccountScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab, // 버튼 클릭에 따라 탭 선택
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final tabWidth = screenWidth / 2;   // 탭 2개니까 절반
    const lineWidth = 170.0;             // 밑줄 원하는 길이
    final horizontalInset = (tabWidth - lineWidth) / 2;


    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "회원 정보 찾기", 
        style: TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold)
          ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        centerTitle: true,

        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          //선택된 탭 볼드체, 선택 안 된 탭 일반체
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 16),

          // 탭 길이 설정
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: UnderlineTabIndicator(
            borderSide: BorderSide(width: 2.5, color: Colors.black), // 줄 두께/색
            insets: EdgeInsets.symmetric(horizontal: horizontalInset), // << 줄 길이 줄이는 핵심
          ),
          tabs: const [
            Tab(text: "아이디 찾기"),
            Tab(text: "비밀번호 찾기"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          IdfoundScreen(),
          PwfoundScreen(),
        ],
      ),
    );
  }
}
