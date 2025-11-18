import 'package:flutter/material.dart';
import 'package:flutter_application_sajindongnae/screen/mypage/inquiry/inquiryList.dart';
import 'package:flutter_application_sajindongnae/screen/mypage/inquiry/inquiryForm.dart';

class InquiryScreen extends StatefulWidget {
  const InquiryScreen({super.key});

  @override
  State<InquiryScreen> createState() => _InquiryScreenState();
}

class _InquiryScreenState extends State<InquiryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this); // 내부 탭 2개
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final tabWidth = screenWidth / 2; // 2개의 탭
    const lineWidth = 160.0;
    final horizontalInset = (tabWidth - lineWidth) / 2;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '1:1 문의',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: false,
          tabs: const [
            Tab(text: '문의하기'),
            Tab(text: '문의 내역'),
          ],
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 15),
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: UnderlineTabIndicator(
            borderSide: const BorderSide(width: 2.5, color: Colors.black),
            insets: EdgeInsets.symmetric(horizontal: horizontalInset),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          InquiryFormScreen(), // 문의하기
          InquiryListScreen(), // 문의내역
        ],
      ),
    );
  }
}