import 'package:flutter/material.dart';
import 'package:flutter_application_sajindongnae/component/expandable_fab.dart';
import 'package:flutter_application_sajindongnae/component/action_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // 파이어베이스 연동
import 'package:flutter_application_sajindongnae/models/photo_trade_model.dart';


/// 사진동네 관리자 페이지 (BottomNavigationBar 버전)
/// 대표색: #DBEFC4
class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  int _selectedIndex = 0;

  static const Color kBrandColor = Color(0xFFDBEFC4);
  static const Color kTextColor = Color.fromARGB(255, 48, 49, 48);

  final List<Widget> _pages = const [
    _AccountManageTab(),
    _PostManageTab(),
    _QnaManageTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBrandColor,
      appBar: AppBar(
        backgroundColor: kBrandColor,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          '사진동네 관리자',
          style: TextStyle(
            color: kTextColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: kTextColor),
      ),
      body: _pages[_selectedIndex],

      // ── bottomNavigationBar ───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: const Color.fromARGB(255, 33, 165, 13),
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        elevation: 8,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: '계정 관리',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.photo_library_outlined),
            label: '게시글 관리',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.question_answer_outlined),
            label: 'Q&A 관리',
          ),
        ],
      ),
      // floatingActionButton: ExpandableFab(
      //   distance: 80,
      //   children: const [
      //     ActionButton(
      //       onPressed: _AdminActions.onTapAddAdmin,
      //       icon: Icons.admin_panel_settings_outlined,
      //     ),
      //     ActionButton(
      //       onPressed: _AdminActions.onTapReportedPosts,
      //       icon: Icons.report_problem_outlined,
      //     ),
      //     ActionButton(
      //       onPressed: _AdminActions.onTapUnansweredQna,
      //       icon: Icons.mark_unread_chat_alt_outlined,
      //     ),
      //   ],
      // ),
    );
  }
}

/// 관리자 액션
class _AdminActions {
  static void onTapAddAdmin() {
    debugPrint('관리자 추가 버튼 클릭');
  }

  static void onTapReportedPosts() {
    debugPrint('신고된 게시글 목록 버튼 클릭');
  }

  static void onTapUnansweredQna() {
    debugPrint('미답변 Q&A 버튼 클릭');
  }
}

// ── 계정 관리 ───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
class _AccountManageTab extends StatelessWidget {
  const _AccountManageTab();

  Stream<QuerySnapshot<Map<String, dynamic>>> _userStream() {
    return FirebaseFirestore.instance
        .collection('users')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _SearchBar(hintText: '닉네임, 이메일로 검색'),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _userStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Center(child: Text('계정 목록을 불러오는 중 오류가 발생했어요 😢'));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('등록된 계정이 없습니다.'));
              }

              final docs = snapshot.data!.docs;
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data();
                  final uid = doc.id;
                  final nickname = data['nickname'] ?? '닉네임 없음';
                  final email = data['email'] ?? '';
                  final status = data['status'] ?? 'normal';
                  final bool isBanned = status == 'banned';

                  return _AdminCard(
                    title: nickname,
                    subtitle: email.isNotEmpty ? email : '정보 없음',
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ChipLabel(
                          label: isBanned ? '정지회원' : '일반회원',
                          color: isBanned ? Colors.red.withOpacity(0.08) : Colors.green.withOpacity(0.1),
                          textColor: isBanned ? Colors.red[700]! : Colors.green[700]!,
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.more_vert, size: 20),
                          onPressed: () async {
                            try {
                              final newStatus = isBanned ? 'normal' : 'banned';
                              await FirebaseFirestore.instance.collection('users').doc(uid).update({'status': newStatus});
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('회원 상태가 "$newStatus" 로 변경되었습니다.'),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            } catch (e) {
                              debugPrint('회원 상태 변경 실패: $e');
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('상태 변경 실패: 권한 또는 네트워크 문제'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── 게시글 관리 (커뮤니티/사진판매/사진거래) ───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
class _PostManageTab extends StatefulWidget {
  const _PostManageTab();

  @override
  State<_PostManageTab> createState() => _PostManageTabState();
}

class _PostManageTabState extends State<_PostManageTab> with TickerProviderStateMixin {
  bool showReportedOnly = false;

  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _postStream() {
    final collection = FirebaseFirestore.instance.collection('posts');
    if (showReportedOnly) {
      return collection.where('reportCount', isGreaterThan: 0).orderBy('reportCount', descending: true).snapshots();
    } else {
      return collection.orderBy('createdAt', descending: true).snapshots();
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _photoTradeStream() {
    final collection = FirebaseFirestore.instance.collection('photo_trades');
    if (showReportedOnly) {
      // 신고가 1건 이상인 글만, 신고순 + 최신순 정렬
      return collection
          .where('reportCount', isGreaterThan: 0)
          .orderBy('reportCount', descending: true)
          .orderBy('createdAt', descending: true)
          .snapshots();
    } else {
      // 전체 보기, 최신순
      return collection.orderBy('createdAt', descending: true).snapshots();
    }
  }

  // ── 구매 사진 스트림 메서드 ──
  Stream<QuerySnapshot<Map<String, dynamic>>> _requestStream() {
    final collection = FirebaseFirestore.instance.collection('requests');
    if (showReportedOnly) {
      return collection
          .where('reportCount', isGreaterThan: 0)
          .orderBy('reportCount', descending: true)
          .orderBy('dateTime', descending: true)
          .snapshots();
    } else {
      return collection.orderBy('dateTime', descending: true).snapshots();
    }
  }


  @override
  Widget build(BuildContext context) {
    final currentUserId = '로그인된 uid';
    final isAdmin = true;

    return Column(
      children: [
        const _SearchBar(hintText: '제목, 닉네임, 태그로 검색'),

        // 내부 탭바
        TabBar(
          controller: _tabController,
          // 선택된 탭 텍스트 스타일
          labelStyle: const TextStyle(
            fontSize: 16,           // 선택된 탭 글자 크기
            fontWeight: FontWeight.bold, // 선택된 탭 글자 굵기
          ),
          // 선택되지 않은 탭 텍스트 스타일
          unselectedLabelStyle: const TextStyle(
            fontSize: 14,           // 선택되지 않은 탭 글자 크기
            fontWeight: FontWeight.normal, // 선택되지 않은 탭 글자 굵기
          ),
          labelColor: Colors.black,          // 선택된 탭 텍스트 색상
          unselectedLabelColor: Colors.grey, // 선택되지 않은 탭 텍스트 색상
          indicator: const UnderlineTabIndicator(
            borderSide: BorderSide(
              width: 3,       // 인디케이터 굵기
              color: Colors.black,
            ),
            insets: EdgeInsets.symmetric(horizontal: 10), // 인디케이터 길이를 탭에 맞게
          ),
          indicatorSize: TabBarIndicatorSize.tab, // 인디케이터가 탭 전체 폭
          tabs: const [
            Expanded(child: Tab(text: '게시물')),
            Expanded(child: Tab(text: '판매 사진')),
            Expanded(child: Tab(text: '구매 사진')),
          ],
        ),


        // 신고글 필터
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    showReportedOnly = !showReportedOnly;
                  });
                },
                child: Text(
                  showReportedOnly ? "전체 보기" : "신고 게시글만",
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // ── 커뮤니티 ───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _postStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Center(child: Text('게시글을 불러오는 중 오류가 발생했어요'));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('게시글이 없습니다.'));
                  }

                  final docs = snapshot.data!.docs;
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 0),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data();
                      final title = data['title'] ?? '제목 없음';
                      final author = data['nickname'] ?? '작성자 없음';
                      final authorId = data['authorId'] ?? '';
                      final reportCount = (data['reportCount'] ?? 0) as int;
                      final bool canDelete = isAdmin || (currentUserId == authorId);

                      return _AdminCard(
                        title: title,
                        subtitle: '작성자: $author · 신고 $reportCount건',
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.visibility_outlined, size: 20),
                              onPressed: () {},
                            ),
                            if (canDelete)
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 20),
                                onPressed: () async {
                                  try {
                                    await FirebaseFirestore.instance.collection('posts').doc(doc.id).delete();
                                  } catch (e) {
                                    debugPrint('게시글 삭제 실패: $e');
                                  }
                                },
                              ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),

              // ── 판매 사진 ───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _photoTradeStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Center(child: Text('판매 사진을 불러오는 중 오류가 발생했어요'));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('판매 사진이 없습니다.'));
                  }

                  final docs = snapshot.data!.docs;
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final model = PhotoTradeModel.fromSnapshot(docs[index]);
                      final bool canDelete = isAdmin || (currentUserId == model.uid);

                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                              color: Colors.black.withOpacity(0.05),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 정사각형 이미지
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.grey[200],
                                image: model.imageUrl.isNotEmpty
                                    ? DecorationImage(
                                        image: NetworkImage(model.imageUrl),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // 제목 + 작성자·신고
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    model.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '작성자: ${model.nickname} · 신고 ${model.reportCount}건',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // 삭제 버튼
                            if (canDelete)
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 22),
                                onPressed: () async {
                                  try {
                                    await FirebaseFirestore.instance
                                        .collection('photo_trades')
                                        .doc(model.id)
                                        .delete();
                                  } catch (e) {
                                    debugPrint('사진 삭제 실패: $e');
                                  }
                                },
                              ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),


              // 세 번째 탭: 구매 사진
              // ── 구매 사진 탭 ──
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('requests')
                    .orderBy('dateTime', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Center(child: Text('구매 사진(게시글)을 불러오는 중 오류가 발생했어요'));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('구매 사진(게시글)이 없습니다.'));
                  }

                  final docs = snapshot.data!.docs;
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 0),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data();
                      final title = data['title'] ?? '제목 없음';
                      final author = data['nickname'] ?? '작성자 없음';
                      final authorId = data['uid'] ?? '';
                      final reportCount = (data['reportCount'] ?? 0) as int;
                      final bool canDelete = isAdmin || (currentUserId == authorId);

                      return _AdminCard(
                        title: title,
                        subtitle: '작성자: $author · 신고 $reportCount건',
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.visibility_outlined, size: 20),
                              onPressed: () {},
                            ),
                            if (canDelete)
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 20),
                                onPressed: () async {
                                  try {
                                    await FirebaseFirestore.instance
                                        .collection('requests')
                                        .doc(doc.id)
                                        .delete();
                                  } catch (e) {
                                    debugPrint('구매 사진(게시글) 삭제 실패: $e');
                                  }
                                },
                              ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),

            ],
          ),
        ),
      ],
    );
  }
}

// ── 1:1 문의 관리 ───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
class _QnaManageTab extends StatelessWidget {
  const _QnaManageTab();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _SearchBar(hintText: '제목, 내용, 닉네임으로 검색'),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: 10,
            itemBuilder: (context, index) {
              final bool answered = index % 2 == 0;
              return _AdminCard(
                title: 'Q&A 제목 $index',
                subtitle: answered ? '답변 완료 · user_$index' : '미답변 · user_$index',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ChipLabel(
                      label: answered ? '답변 완료' : '미답변',
                      color: answered ? Colors.blue.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                      textColor: answered ? Colors.blue[700]! : Colors.orange[800]!,
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.edit_note_outlined, size: 22),
                      onPressed: () {},
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// ----------------------
/// 공통 위젯들
/// ----------------------

class _SearchBar extends StatelessWidget {
  final String hintText;
  const _SearchBar({required this.hintText});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      color: const Color(0xFFDBEFC4),
      child: TextField(
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          hintText: hintText,
          filled: true,
          fillColor: Colors.white,
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _AdminCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;
  const _AdminCard({required this.title, required this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            blurRadius: 4,
            spreadRadius: 0,
            offset: const Offset(0, 2),
            color: Colors.black.withOpacity(0.05),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[700]), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _ChipLabel extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  const _ChipLabel({required this.label, required this.color, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
      child: Text(label, style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.w500)),
    );
  }
}
