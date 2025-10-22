import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_sajindongnae/screen/mypage/setting/settings.dart';
import 'package:flutter_application_sajindongnae/screen/mypage/contents/userContent.dart';
import 'package:flutter_application_sajindongnae/screen/mypage/userLikeds/likedList.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();

    print(FirebaseAuth.instance.currentUser);
  }

  // 백엔드 설정 ----------------------------------------------------------
  void _fetchUserProfile() async {
    // Firestore에서 닉네임, 프로필 이미지 URL 가져와야합니다람쥐
    // 임시값으로 UI 확인을 위해 코드 작성만 한 상태입니다람쥐
    setState(() {
      nickname = "리락쿠마";
      // nickname = null;

      profileImageUrl = null;

      // point = 5000;
      point = null;

      sellPhotoCount = 12;
      buyPhotoCount = 8;
      postCount = 5;
    });
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
                  _buildMenuItem('포인트 환전소', onTap: () {}),
                  _buildMenuDivider(),
                  _buildMenuItem('좋아요 내역', onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LikedListScreen()),
                    );
                  }),
                  _buildMenuDivider(),
                  _buildMenuItem('1:1 문의', onTap: () {}),
                  _buildMenuDivider(),
                  _buildMenuItem('자주 묻는 질문', onTap: () {}),
                  _buildMenuDivider(),
                  _buildMenuItem('공지 사항', onTap: () {}),
                  _buildMenuDivider(),
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
        style: const TextStyle(fontSize: 16 , fontWeight: FontWeight.bold),
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
