import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_sajindongnae/screen/mypage/userLikeds/likedPost.dart';
import 'package:flutter_application_sajindongnae/screen/mypage/userLikeds/likedBuy.dart';
import 'package:flutter_application_sajindongnae/screen/mypage/userLikeds/likedSell.dart';

class LikedListScreen extends StatefulWidget {
  const LikedListScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<LikedListScreen> createState() => _LikedListScreenState();
}

class _LikedListScreenState extends State<LikedListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3, // 판매 / 구매 / 게시글
      vsync: this,
      initialIndex: widget.initialTab,
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
    final tabWidth = screenWidth / 3;
    const lineWidth = 110.0;
    final horizontalInset = (tabWidth - lineWidth) / 2;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '좋아요 내역',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: false,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 15),
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: UnderlineTabIndicator(
            borderSide: const BorderSide(width: 2.5, color: Colors.black),
            insets: EdgeInsets.symmetric(horizontal: horizontalInset),
          ),
          tabs: const [
            Tab(text: '판매사진'),
            Tab(text: '구매사진'),
            Tab(text: '게시글'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          LikedsellScreen(), 
          LikedbuyScreen(),
          LikedpostScreen(),
        ],
      ),
    );
  }
}
