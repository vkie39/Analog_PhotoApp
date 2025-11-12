import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_sajindongnae/screen/mypage/setting/settings.dart';
import 'package:flutter_application_sajindongnae/screen/mypage/contents/userContent.dart';
import 'package:flutter_application_sajindongnae/screen/mypage/userLikeds/likedList.dart';
import 'package:flutter_application_sajindongnae/screen/mypage/inquiry/inquiry.dart';
import 'package:flutter_application_sajindongnae/screen/mypage/faq.dart';

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  User? user = FirebaseAuth.instance.currentUser; // 로그인 사용자 정보 ..

  String? nickname; // 백엔드 닉네임 (실명X)
  String? profileImageUrl; // 백엔드 프로필 이미지 URL

  int? point; // 백엔드 포인트

  int? sellPhotoCount; // 백엔드 판매사진 갯수
  int? buyPhotoCount; // 백엔드 구매사진 갯수
  int? postCount; // 백엔드 작성한 게시글 갯수

  StreamSubscription? _sellPhotoListener;
  StreamSubscription? _buyPhotoListener;
  StreamSubscription? _postListener;

  @override
  void initState() {
    super.initState();
    _listenToSellPhotoCount(); // 실시간 판매글 수 추가
    _listenToBuyPhotoCount(); // 실시간 구매글 수 추가
    _listenToPostCount(); // 실시간 게시글 수 추가
    _fetchUserProfile(); // 기존 임시 데이터 불러오기 // 백엔드 연동할 경우 삭제해도 상관 X

    print(FirebaseAuth.instance.currentUser);
  }

  // 백엔드 임시 설정 ----------------------------------------------------------
  // 백엔드 연동할 경우 삭제해도 상관 X
  void _fetchUserProfile() async {
    // Firestore에서 닉네임, 프로필 이미지 URL 가져와야합니다람쥐
    // 임시값으로 UI 확인을 위해 코드 작성만 한 상태입니다람쥐
    setState(() {
      nickname = "리락쿠마";
      // nickname = null;

      profileImageUrl = null;

      // point = 5000;
      point = null;

      // sellPhotoCount = 12;
      // buyPhotoCount = 8;
      // postCount = 5;
    });
  }

  // 백엔드 설정 ----------------------------------------------------------

  // 실시간 판매 사진 수
  void _listenToSellPhotoCount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      _sellPhotoListener?.cancel();

      _sellPhotoListener = FirebaseFirestore.instance
          .collection('photo_trades')
          .where('sellerId', isEqualTo: user.uid)
          .snapshots()
          .listen(
            (snapshot) {
              setState(() {
                sellPhotoCount = snapshot.docs.length;
              });
            },
            onError: (error) {
              debugPrint("Firestore snapshot error (sellPhotoCount): $error");
              setState(() {
                sellPhotoCount = null;
              });
            },
          );
    } catch (e) {
      debugPrint("Firestore connection failed (sellPhotoCount): $e");
      setState(() {
        sellPhotoCount = null;
      });
    }
  }

  // 실시간 구매 사진 수
  void _listenToBuyPhotoCount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      _buyPhotoListener?.cancel();

      _buyPhotoListener = FirebaseFirestore.instance
          .collection('photo_trades')
          .where('buyerId', isEqualTo: user.uid)
          .snapshots()
          .listen(
            (snapshot) {
              setState(() {
                buyPhotoCount = snapshot.docs.length;
              });
            },
            onError: (error) {
              debugPrint("Firestore snapshot error (buyPhotoCount): $error");
              setState(() {
                buyPhotoCount = null;
              });
            },
          );
    } catch (e) {
      debugPrint("Firestore connection failed (buyPhotoCount): $e");
      setState(() {
        buyPhotoCount = null;
      });
    }
  }

  void _listenToPostCount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      _postListener?.cancel();

      _postListener = FirebaseFirestore.instance
          .collection('posts')
          .where('userId', isEqualTo: user.uid) // ← 로그인 사용자 기준 필터
          .snapshots()
          .listen(
            (snapshot) {
              setState(() {
                postCount = snapshot.docs.length;
              });
            },
            onError: (error) {
              // 🔹 Firestore 권한이 없거나 구조가 다를 경우 에러 발생
              debugPrint("Firestore snapshot error: $error");
              setState(() {
                postCount = null; // or 0
              });
            },
          );
    } catch (e) {
      debugPrint("Firestore connection failed: $e");
      setState(() {
        postCount = null; // 안전하게 초기화
      });
    }
  }

  // ---------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // 앱바 설정
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 24,
        title: const Text(
          '마이페이지',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontSize: 20,
          ),
        ),
        actions: [
          // 알림 아이콘
          Transform.translate(
            offset: const Offset(8, 0),
            child: IconButton(
              icon: const Icon(Icons.notifications),
              iconSize: 30,
              color: Colors.black,
              onPressed: () {
                print("알림 클릭됨");
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: const Icon(Icons.settings),
              iconSize: 30,
              color: Colors.black,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
          ),
        ],
      ),

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 프로필 -------------------------------------------------------------
          Padding(
            padding: const EdgeInsets.only(
              top: 8.0,
              left: 24.0,
              right: 16.0,
              bottom: 8.0,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundImage:
                      profileImageUrl != null
                          ? NetworkImage(profileImageUrl!)
                          : AssetImage('assets/images/default_profile.png')
                              as ImageProvider,
                ),
                const SizedBox(width: 16),

                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        nickname ?? '이름을 설정해주세요',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color:
                              nickname == null
                                  ? const Color.fromARGB(255, 156, 156, 156)
                                  : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Image.asset(
                            'assets/images/point.jpg',
                            width: 20,
                            height: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${point ?? 0}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // 칸 나누기 ----------------------------------------------------------
          const Divider(
            color: Color.fromARGB(255, 240, 240, 240),
            thickness: 8,
            height: 16,
          ),

          // 판매사진 / 구매사진 / 게시글 ------------------------------------------
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildContentButton(
                  context,
                  count: sellPhotoCount ?? 0,
                  title: '판매사진',
                  tabIndex: 0,
                ),
                _buildContentButton(
                  context,
                  count: buyPhotoCount ?? 0,
                  title: '구매사진',
                  tabIndex: 1,
                ),
                _buildContentButton(
                  context,
                  count: postCount ?? 0,
                  title: '게시글',
                  tabIndex: 2,
                ),
              ],
            ),
          ),

          // 칸 나누기 ----------------------------------------------------------
          const Divider(
            color: Color.fromARGB(255, 240, 240, 240),
            thickness: 8,
            height: 16,
          ),

          // 메뉴 목록 ----------------------------------------------------------
          const SizedBox(height: 4),
          Expanded(
            child: Container(
              color: Colors.white,
              child: Column(
                children: [
                  _buildMenuItem(
                    '좋아요 내역',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LikedListScreen(),
                        ),
                      );
                    },
                  ),
                  _buildMenuItem('포인트 내역', onTap: () {}),
                  _buildMenuDivider(),
                  _buildMenuDivider(),
                  _buildMenuItem(
                    '1:1 문의',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const InquiryScreen(),
                        ),
                      );
                    },
                  ),
                  _buildMenuDivider(),
                  _buildMenuItem(
                    '자주 묻는 질문',
                     onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const FaqScreen(),
                          )
                      );
                     }
                    ),
                  _buildMenuDivider(),
                  // _buildMenuItem('공지 사항', onTap: () {}),
                  // _buildMenuDivider(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 판매/구매/게시글 버튼 생성
  Expanded _buildContentButton(
    BuildContext context, {
    required int count,
    required String title,
    required int tabIndex,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => UserContentScreen(initialTab: tabIndex),
            ),
          );
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$count',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // 메뉴 항목 생성
  Widget _buildMenuItem(String title, {VoidCallback? onTap}) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      dense: true,
    );
  }

  // 메뉴 구분선
  Widget _buildMenuDivider() {
    return const Divider(
      color: Color.fromARGB(255, 240, 240, 240),
      height: 16,
      thickness: 1,
    );
  }
}
