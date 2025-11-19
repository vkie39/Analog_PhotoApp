import 'package:flutter/material.dart';
import 'package:flutter_application_sajindongnae/component/expandable_fab.dart';
import 'package:flutter_application_sajindongnae/component/action_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // 파이어베이스 연동
import 'package:flutter_application_sajindongnae/models/photo_trade_model.dart';
import 'package:flutter_application_sajindongnae/screen/post/reportList.dart';
import 'package:flutter_application_sajindongnae/models/inquiry_model.dart';
import 'package:flutter_application_sajindongnae/admin/InquiryAnswer.dart';
import 'package:flutter_application_sajindongnae/models/post_model.dart';
import 'package:flutter_application_sajindongnae/models/photo_trade_model.dart';
import 'package:flutter_application_sajindongnae/services/post_service.dart';
import 'package:flutter_application_sajindongnae/screen/post/update.dart';

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
          style: TextStyle(color: kTextColor, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: kTextColor),
      ),
      body: _pages[_selectedIndex],
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

/// ─────────────────────────────────────────────
///  계정 관리 탭
/// ─────────────────────────────────────────────
class _AccountManageTab extends StatefulWidget {
  const _AccountManageTab();

  @override
  State<_AccountManageTab> createState() => _AccountManageTabState();
}

class _AccountManageTabState extends State<_AccountManageTab> {
  String _keyword = '';

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
        _SearchBar(
          hintText: '닉네임, 이메일로 검색',
          onChanged: (value) {
            setState(() {
              _keyword = value.trim().toLowerCase();
            });
          },
        ),
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

              final allDocs = snapshot.data!.docs;

              // 🔍 검색어로 필터링 (닉네임 / 이메일)
              final filteredDocs =
                  allDocs.where((doc) {
                    if (_keyword.isEmpty) return true;

                    final data = doc.data();
                    final nickname =
                        (data['nickname'] ?? '').toString().toLowerCase();
                    final email =
                        (data['email'] ?? '').toString().toLowerCase();

                    return nickname.contains(_keyword) ||
                        email.contains(_keyword);
                  }).toList();

              if (filteredDocs.isEmpty && _keyword.isNotEmpty) {
                return const Center(child: Text('검색 결과가 없습니다.'));
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemCount: filteredDocs.length,
                itemBuilder: (context, index) {
                  final doc = filteredDocs[index];
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
                          color:
                              isBanned
                                  ? Colors.red.withOpacity(0.08)
                                  : Colors.green.withOpacity(0.1),
                          textColor:
                              isBanned ? Colors.red[700]! : Colors.green[700]!,
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.more_vert, size: 20),
                          onPressed: () async {
                            try {
                              final newStatus = isBanned ? 'normal' : 'banned';

                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(uid)
                                  .update({'status': newStatus});

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '회원 상태가 "$newStatus" 로 변경되었습니다.',
                                  ),
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

/// ─────────────────────────────────────────────
///  게시글 관리 탭 (커뮤니티 / 판매 사진 / 구매 사진) + 검색
/// ─────────────────────────────────────────────
class _PostManageTab extends StatefulWidget {
  const _PostManageTab();

  @override
  State<_PostManageTab> createState() => _PostManageTabState();
}

class _PostManageTabState extends State<_PostManageTab>
    with TickerProviderStateMixin {
  bool showReportedOnly = false;
  String _keyword = ''; // ★ 검색어 상태 추가

  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _postStream() {
    final collection = FirebaseFirestore.instance.collection('posts');
    if (showReportedOnly) {
      return collection
          .where('reportCount', isGreaterThan: 0)
          .orderBy('reportCount', descending: true)
          .snapshots();
    } else {
      return collection.orderBy('createdAt', descending: true).snapshots();
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _photoTradeStream() {
    final collection = FirebaseFirestore.instance.collection('photo_trades');
    if (showReportedOnly) {
      return collection
          .where('reportCount', isGreaterThan: 0)
          .orderBy('reportCount', descending: true)
          .snapshots();
    } else {
      return collection.orderBy('createdAt', descending: true).snapshots();
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _requestStream() {
    final collection = FirebaseFirestore.instance.collection('requests');
    if (showReportedOnly) {
      return collection
          .where('reportCount', isGreaterThan: 0)
          .orderBy('reportCount', descending: true)
          .snapshots();
    } else {
      return collection.orderBy('dateTime', descending: true).snapshots();
    }
  }


  // _PostManageTabState 클래스 안에 선언
  void _showDeleteDialog(BuildContext context, String postId, String collectionName) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
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
                    '게시글을 삭제하시겠습니까?',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
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
                          child: const Center(
                            child: Text(
                              '아니요',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(width: 1, color: Colors.grey[300]),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          Navigator.pop(context);
                          try {
                            await FirebaseFirestore.instance
                                .collection(collectionName)
                                .doc(postId)
                                .delete();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('게시글이 삭제되었습니다.')),
                            );
                          } catch (e) {
                            debugPrint('게시글 삭제 실패: $e');
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('삭제 실패')),
                            );
                          }
                        },
                        child: Container(
                          color: Colors.transparent,
                          child: const Center(
                            child: Text(
                              '예',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red),
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
  

  @override
  Widget build(BuildContext context) {
    final currentUserId = '로그인된 uid';
    final isAdmin = true;

    return Column(
      children: [
        _SearchBar(
          hintText: '제목, 닉네임, 태그로 검색',
          onChanged: (value) {
            setState(() {
              _keyword = value.trim().toLowerCase();
            });
          },
        ),

        // 내부 탭바
        TabBar(
          controller: _tabController,
          labelStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
          ),
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          indicator: const UnderlineTabIndicator(
            borderSide: BorderSide(width: 3, color: Colors.black),
            insets: EdgeInsets.symmetric(horizontal: 10),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
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
                  showReportedOnly ? '전체 보기' : '신고 게시글만',
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
              /// ── 1) 커뮤니티 게시물 ─────────────────
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

                  final allDocs = snapshot.data!.docs;

                  // 🔍 검색 필터링 (제목, 닉네임, 태그)
                  final docs =
                      allDocs.where((doc) {
                        if (_keyword.isEmpty) return true;

                        final data = doc.data();
                        final title =
                            (data['title'] ?? '').toString().toLowerCase();
                        final nickname =
                            (data['nickname'] ?? '').toString().toLowerCase();
                        final tagsField = data['tags'];
                        String tags = '';
                        if (tagsField is List) {
                          tags =
                              tagsField
                                  .map((e) => e.toString())
                                  .join(' ')
                                  .toLowerCase();
                        } else if (tagsField is String) {
                          tags = tagsField.toLowerCase();
                        }

                        return title.contains(_keyword) ||
                            nickname.contains(_keyword) ||
                            tags.contains(_keyword);
                      }).toList();

                  if (docs.isEmpty && _keyword.isNotEmpty) {
                    return const Center(child: Text('검색 결과가 없습니다.'));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 0,
                    ),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final model = PhotoTradeModel.fromSnapshot(docs[index]);

                      final doc = docs[index];
                      final data = doc.data();
                      final title = data['title'] ?? '제목 없음';
                      final author = data['nickname'] ?? '작성자 없음';
                      final authorId = data['authorId'] ?? '';
                      final reportCount = (data['reportCount'] ?? 0) as int;
                      final bool canDelete =
                          isAdmin || (currentUserId == authorId);

                      return _AdminCard(
                        title: title,
                        subtitle: '작성자: $author · 신고 $reportCount건',
                        onTap: () async {
                        final updatedPost = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => UpdateScreen(
                              existingPost: PostModel(
                                postId: doc.id,
                                uid: authorId,
                                nickname: author,
                                profileImageUrl: data['profileImageUrl'] ?? '',
                                category: data['category'] ?? '',
                                likeCount: data['likeCount'] ?? 0,
                                commentCount: data['commentCount'] ?? 0,
                                timestamp: data['createdAt']?.toDate() ?? DateTime.now(),
                                title: data['title'] ?? '',
                                content: data['content'] ?? '',
                                imageUrl: data['imageUrl'],
                              ),
                            ),
                          ),
                        );

                        // 수정 후 UI 갱신
                        if (updatedPost != null) {
                          setState(() {});
                        }
                      },

                      
                        // 신고 내역 확인
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              padding: EdgeInsets.zero, 
                              constraints: const BoxConstraints(), 
                              icon: const Icon(Icons.warning_amber_outlined, size: 27), 
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ReportListScreen(postId: doc.id),
                                  ),
                                );
                              },
                            ),
                            if (canDelete)
                              IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon: const Icon(Icons.delete_outline, size: 30),
                                onPressed: () {
                                  // 호출 예시
                                  _showDeleteDialog(context, model.id!, 'photo_trades');
                                },
                              ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),

              /// ── 2) 판매 사진 ─────────────────
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

                  final allDocs = snapshot.data!.docs;

                  final docs =
                      allDocs.where((doc) {
                        if (_keyword.isEmpty) return true;

                        final data = doc.data();
                        final title =
                            (data['title'] ?? '').toString().toLowerCase();
                        final nickname =
                            (data['nickname'] ?? '').toString().toLowerCase();

                        return title.contains(_keyword) ||
                            nickname.contains(_keyword);
                      }).toList();

                  if (docs.isEmpty && _keyword.isNotEmpty) {
                    return const Center(child: Text('검색 결과가 없습니다.'));
                  }

                  // _PostManageTabState 클래스 안, 판매 사진 ListView.builder(itemBuilder)
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final model = PhotoTradeModel.fromSnapshot(docs[index]);
                      final bool canDelete = isAdmin || (currentUserId == model.uid);

                      return Container(
                        height: 90, // 박스 높이 고정
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center, // 사진 + 텍스트 중앙 정렬
                          children: [
                            // 사진
                            Container(
                              width: 70,
                              height: 70,
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
                            const SizedBox(width: 16),

                            // 제목 + 작성자/신고 정보
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center, // 수직 중앙 정렬
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    model.title.length > 14
                                        ? '${model.title.substring(0, 14)}...'
                                        : model.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
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

                            // 신고 + 삭제 버튼
                            if (canDelete)
                              Padding(
                                padding: const EdgeInsets.only(right: 12), // 오른쪽 여백 추가
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ReportListScreen(postId: model.id!),
                                          ),
                                        );
                                      },
                                      child: const Icon(Icons.warning_amber_outlined, size: 23),
                                    ),
                                    const SizedBox(height: 16), // 아이콘 간격 조절
                                    GestureDetector(
                                      onTap: () => _showDeleteDialog(context, model.id!, 'photo_trades'),
                                      child: const Icon(Icons.delete_outline, size: 23),
                                    ),
                                  ],
                                ),
                              ),

                          ],
                        ),
                      );
                    },
                  );

                },
              ),

              /// ── 3) 구매 사진 ─────────────────
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _requestStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text('구매 사진(게시글)을 불러오는 중 오류가 발생했어요'),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('구매 사진(게시글)이 없습니다.'));
                  }

                  final allDocs = snapshot.data!.docs;

                  final docs = allDocs.where((doc) {
                    if (_keyword.isEmpty) return true;

                    final data = doc.data();
                    final title = (data['title'] ?? '').toString().toLowerCase();
                    final nickname = (data['nickname'] ?? '').toString().toLowerCase();

                    return title.contains(_keyword) || nickname.contains(_keyword);
                  }).toList();

                  if (docs.isEmpty && _keyword.isNotEmpty) {
                    return const Center(child: Text('검색 결과가 없습니다.'));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data();
                      final authorId = data['uid'] ?? '';
                      final canDelete = isAdmin || (currentUserId == authorId);

                      return _AdminCard(
                        title: data['title'] != null && data['title'].length > 14
                            ? '${data['title'].substring(0, 14)}...'
                            : data['title'] ?? '제목 없음',
                        subtitle:
                            '작성자: ${data['nickname'] ?? '작성자 없음'} · 신고 ${data['reportCount'] ?? 0}건',
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ReportListScreen(postId: docs[index].id),
                                  ),
                                );
                              },
                              child: const Icon(Icons.warning_amber_outlined, size: 23),
                            ),
                            if (canDelete) const SizedBox(width: 12),
                            if (canDelete)
                              GestureDetector(
                                onTap: () =>
                                    _showDeleteDialog(context, docs[index].id, 'requests'), // ← 컬렉션 이름 맞춤
                                child: const Icon(Icons.delete_outline, size: 23),
                              ),
                          ],
                        ),
                        onTap: () {
                          // 구매 사진 클릭 시 원하는 동작 넣을 수 있음
                        },
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

/// ─────────────────────────────────────────────
///  1:1 문의 관리 탭 + 검색
/// ─────────────────────────────────────────────
class _QnaManageTab extends StatefulWidget {
  const _QnaManageTab();

  @override
  State<_QnaManageTab> createState() => _QnaManageTabState();
}

class _QnaManageTabState extends State<_QnaManageTab> {
  String _keyword = '';
  bool showUnansweredOnly = false;

  Stream<List<InquiryModel>> _inquiryStream() {
    return FirebaseFirestore.instance
        .collection('inquiries')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => InquiryModel.fromDocument(doc))
                  .toList(),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SearchBar(
          hintText: '제목, 내용, 닉네임으로 검색',
          onChanged: (value) {
            setState(() {
              _keyword = value.trim().toLowerCase();
            });
          },
        ),

        // ── 전체보기 / 미답변만 보기 토글 ─────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    showUnansweredOnly = !showUnansweredOnly;
                  });
                },
                child: Text(
                  showUnansweredOnly ? '전체보기' : '미답변만 보기',
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
          child: StreamBuilder<List<InquiryModel>>(
            stream: _inquiryStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Center(child: Text('문의 목록을 불러오는 중 오류가 발생했습니다.'));
              }

              final inquiries = snapshot.data ?? [];

              // 전체 문의 + 미답변 필터
              final filtered = inquiries.where((inq) {
                // 필터
                if (_keyword.isNotEmpty) {
                  final title = inq.title.toLowerCase();
                  final content = inq.content.toLowerCase();
                  final nickname = inq.nickname.toLowerCase();
                  final category = inq.category.toLowerCase();
                  if (!(title.contains(_keyword) ||
                      content.contains(_keyword) ||
                      nickname.contains(_keyword) ||
                      category.contains(_keyword))) {
                    return false;
                  }
                }

                // 미답변만 보기 필터
                if (showUnansweredOnly && inq.isAnswered) {
                  return false;
                }

                return true;
              }).toList();


              if (filtered.isEmpty) {
                return const Center(child: Text('문의가 없습니다.'));
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final inq = filtered[index];
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(12),
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
                        // ── 왼쪽: 문의 정보 ─────────────
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 제목(15자 제한) + 카테고리
                              Text(
                                '[${inq.category}] ${inq.title}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                maxLines: 1, // 한 줄로 제한
                                overflow: TextOverflow.ellipsis, // 초과 시 ... 표시
                              ),

                              const SizedBox(height: 4),
                              // 작성자
                              Text(
                                '작성자 : ${inq.nickname}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                ),
                              ),

                              const SizedBox(height: 12),

                              // 문의 내용 (15자 제한)
                              Text(
                                inq.content,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // const SizedBox(width: 8),

                        // ── 오른쪽: 상태 + 답장 버튼 세로 배치 ─────────────
                        Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // 상태칩
                            _ChipLabel(
                              label: inq.isAnswered ? '답변 완료' : '미답변',
                              color: inq.isAnswered
                                  ? Colors.blue.withOpacity(0.1)
                                  : Colors.orange.withOpacity(0.1),
                              textColor: inq.isAnswered
                                  ? Colors.blue[700]!
                                  : Colors.orange[800]!,
                            ),

                            const SizedBox(height: 16),

                            // 답장 아이콘 (오른쪽 아래로 자동 이동)
                            Align(
                              alignment: Alignment.bottomRight,
                              child: IconButton(
                                icon: const Icon(Icons.edit_note_outlined, size: 40),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                tooltip: '답장하기',
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => InquiryAnswerScreen(inquiry: inq),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
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

/// ----------------------
/// 공통 위젯들
/// ----------------------
class _SearchBar extends StatelessWidget {
  final String hintText;
  final ValueChanged<String>? onChanged;

  const _SearchBar({required this.hintText, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      color: const Color(0xFFDBEFC4),
      child: TextField(
        onChanged: onChanged,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
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
  final String? subtitle; // 문자열은 선택사항
  final Widget? subtitleWidget; // 위젯 선택사항
  final Widget? trailing;
  final VoidCallback? onTap;
  final double? height;

  const _AdminCard({
    required this.title,
    this.subtitle,
    this.subtitleWidget,
    this.trailing,
    this.onTap,
    this.height,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: height,
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
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (subtitleWidget != null)
                    subtitleWidget!
                  else if (subtitle != null)
                    Text(
                      subtitle!,
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

class _ChipLabel extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;

  const _ChipLabel({
    required this.label,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
