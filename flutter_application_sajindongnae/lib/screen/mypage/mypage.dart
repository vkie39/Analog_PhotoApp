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
  User? user = FirebaseAuth.instance.currentUser; // 로그인 사용자 정보

  String? nickname;              // DB 닉네임
  String? profileImageUrl;       // DB 프로필 이미지 URL
  int? sellPhotoCount;           // 판매 사진 수
  int? buyPhotoCount;            // 구매 사진 수
  int? postCount;                // 게시글 수

  StreamSubscription? _sellPhotoListener;
  StreamSubscription? _buyPhotoListener;
  StreamSubscription? _postListener;

  @override
  void initState() {
    super.initState();

    // 프레임 이후에 비동기 초기화(안전)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await migrateUserDocToUid();   // 과거 문서ID 정규화(있으면)
      await _ensurePointField();     // point 필드 없으면 생성
      await _fetchUserProfile();     // 닉네임/프로필 로드
      await _loadCounts();           // 판매/구매/게시글 수 로드
    });
  }

  // ─────────────────────────────────────────────────────────────────────
  // Firestore: users/{uid} 문서가 없거나 point가 없으면 보정
  Future<void> _ensurePointField() async {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) return;

    final ref = FirebaseFirestore.instance.doc('users/${u.uid}');
    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(ref);

      if (!snap.exists) {
        debugPrint('👉 users/${u.uid} 문서가 없어 새로 생성합니다.');
        tx.set(ref, {
          'uid': u.uid,
          'email': u.email,
          'point': {
            'balance': 0,
            'updatedAt': FieldValue.serverTimestamp(),
          },
        }, SetOptions(merge: true));
        return;
      }

      final data = snap.data();
      final hasPoint = (data?['point'] is Map) &&
          ((data!['point'] as Map).containsKey('balance'));

      if (!hasPoint) {
        debugPrint('👉 point.balance 없음 → 0으로 초기화');
        tx.update(ref, {
          'point': {
            'balance': 0,
            'updatedAt': FieldValue.serverTimestamp(),
          }
        });
      }
    });
  }

  // ─────────────────────────────────────────────────────────────────────
  // 과거: users 문서 ID가 uid가 아닌 경우 uid 문서로 복사
  Future<void> migrateUserDocToUid() async {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) return;

    final uidDoc = await FirebaseFirestore.instance.doc('users/${u.uid}').get();
    if (uidDoc.exists) {
      // 이미 uid 문서가 있으면 스킵
      return;
    }

    // 필드 uid 로 기존 문서를 찾아 복사
    final qs = await FirebaseFirestore.instance
        .collection('users')
        .where('uid', isEqualTo: u.uid)
        .limit(1)
        .get();

    if (qs.docs.isEmpty) return;

    final oldDoc = qs.docs.first;
    final data = oldDoc.data();
    final newDocRef =
    FirebaseFirestore.instance.collection('users').doc(u.uid);

    debugPrint('👉 기존(users/${oldDoc.id}) → users/${u.uid} 로 마이그레이션');
    await newDocRef.set(data, SetOptions(merge: true));
    // 필요하면 옛 문서 삭제:
    // await oldDoc.reference.delete();
  }

  // ─────────────────────────────────────────────────────────────────────
  /// 포인트 잔액 실시간 스트림 (없으면 0)
  Stream<int> _watchPointBalance() {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) return Stream<int>.value(0);
    final doc = FirebaseFirestore.instance.doc('users/${u.uid}');
    return doc.snapshots().map((s) {
      final data = s.data();
      debugPrint('📘 Firestore users/${u.uid} data: $data'); // 값 확인 로그
      final point = (data?['point'] as Map<String, dynamic>?);
      final dynamic raw = point?['balance'];
      if (raw is int) return raw;
      if (raw is num) return raw.toInt();
      return 0;
    });
  }

  // ─────────────────────────────────────────────────────────────────────
  // 프로필 로드: users/{uid} 에서 닉네임/프로필 이미지
  Future<void> _fetchUserProfile() async {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) return;

    final doc =
    await FirebaseFirestore.instance.doc('users/${u.uid}').get();
    final data = doc.data();

    setState(() {
      nickname = (data?['nickname'] as String?) ?? '닉네임 없음';
      profileImageUrl = data?['profileImageUrl'] as String?;
    });

    debugPrint('✅ 프로필 로드: nickname=$nickname, profileImageUrl=$profileImageUrl');
  }

  // ─────────────────────────────────────────────────────────────────────
  // 카운트 로드: posts / photo_trades 에서 uid기준 집계
  Future<void> _loadCounts() async {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) return;

    int posts = 0;
    int sells = 0;
    int buys  = 0;

    // 1) 게시글 수: posts 컬렉션 (authorId 또는 uid 어느쪽이든 존재하는 필드로 카운트)
    try {
      final postsColl = FirebaseFirestore.instance.collection('posts');

      // 우선 authorId
      var agg = await postsColl
          .where('authorId', isEqualTo: u.uid)
          .count()
          .get();
      posts = agg.count ?? 0;

      // authorId가 없다면 uid 필드 시도
      if (posts == 0) {
        agg = await postsColl.where('uid', isEqualTo: u.uid).count().get();
        posts = agg.count ?? 0;
      }
    } catch (e) {
      debugPrint('⚠️ posts 카운트 실패: $e');
    }

    // 2) 판매/구매 사진 수: photo_trades 컬렉션 가정
    //    필드명은 프로젝트에 따라 sellerUid/buyerUid 또는 sellerId/buyerId일 수 있으므로 둘 다 시도
    try {
      final trades = FirebaseFirestore.instance.collection('photo_trades');

      // 판매(내가 판매자)
      try {
        var agg = await trades.where('sellerUid', isEqualTo: u.uid).count().get();
        sells = agg.count ?? 0;
      } catch (_) {
        final agg = await trades.where('sellerId', isEqualTo: u.uid).count().get();
        sells = agg.count ?? 0;
      }

      // 구매(내가 구매자)
      try {
        var agg = await trades.where('buyerUid', isEqualTo: u.uid).count().get();
        buys = agg.count ?? 0;
      } catch (_) {
        final agg = await trades.where('buyerId', isEqualTo: u.uid).count().get();
        buys = agg.count ?? 0;
      }
    } catch (e) {
      debugPrint('⚠️ photo_trades 카운트 실패: $e');
    }

    setState(() {
      postCount = posts;
      sellPhotoCount = sells;
      buyPhotoCount = buys;
    });

    debugPrint('✅ 카운트 로드: posts=$posts, sells=$sells, buys=$buys');
  }

  // ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

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
          Transform.translate(
            offset: const Offset(8, 0),
            child: IconButton(
              icon: const Icon(Icons.notifications),
              iconSize: 30,
              color: Colors.black,
              onPressed: () {},
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
          // ── 프로필 ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(
              top: 8.0, left: 24.0, right: 16.0, bottom: 8.0,
            ),
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user!.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data == null) {
                  // 로딩 시 기본 UI
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CircleAvatar(
                        radius: 36,
                        backgroundImage: AssetImage('assets/images/default_profile.png'),
                      ),
                      const SizedBox(width: 16),
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Text(
                              '이름을 설정해주세요',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color.fromARGB(255, 156, 156, 156),
                              ),
                            ),
                            SizedBox(height: 4),
                          ],
                        ),
                      ),
                    ],
                  );
                }

                final data = snapshot.data!.data() as Map<String, dynamic>?;

                final nickname = data?['nickname'] ?? '이름을 설정해주세요';
                final profileImageUrl = data?['profileImageUrl'];

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundImage: profileImageUrl != null
                          ? NetworkImage(profileImageUrl)
                          : const AssetImage('assets/images/default_profile.png') as ImageProvider,
                    ),
                    const SizedBox(width: 16),
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            nickname,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: nickname == '이름을 설정해주세요'
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
                              // 포인트는 기존 StreamBuilder 유지
                              StreamBuilder<int>(
                                stream: _watchPointBalance(),
                                builder: (context, snapshot) {
                                  final balance = snapshot.data ?? 0;
                                  return Text(
                                    '$balance',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),


          const Divider(
            color: Color.fromARGB(255, 240, 240, 240),
            thickness: 8,
            height: 16,
          ),

          // ── 판매/구매/게시글 카운트 ─────────────────────────────────────
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

          // ── 칸 나누기 ──────────────────────────────────────────────────

          const Divider(
            color: Color.fromARGB(255, 240, 240, 240),
            thickness: 8,
            height: 16,
          ),

          // ── 메뉴 목록 ──────────────────────────────────────────────────
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
                  _buildMenuDivider(),
                  
                  _buildMenuItem('포인트 내역', onTap: () {}),
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
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

  // ─────────────────────────────────────────────────────────────────────
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
