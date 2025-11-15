import 'package:flutter/material.dart';
import 'package:flutter_application_sajindongnae/component/expandable_fab.dart';
import 'package:flutter_application_sajindongnae/component/action_button.dart';

/// 사진동네 관리자 페이지
/// - 계정 관리
/// - 게시글 관리
/// - Q&A 관리
/// 대표색: #DBEFC4
class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  static const Color kBrandColor = Color(0xFFDBEFC4);
  static const Color kTextColor = Color.fromARGB(255, 48, 49, 48);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
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
          bottom: const TabBar(
            labelColor: kTextColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: kTextColor,
            tabs: [
              Tab(text: '계정 관리', icon: Icon(Icons.person_outline)),
              Tab(text: '게시글 관리', icon: Icon(Icons.photo_library_outlined)),
              Tab(text: 'Q&A 관리', icon: Icon(Icons.question_answer_outlined)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _AccountManageTab(),
            _PostManageTab(),
            _QnaManageTab(),
          ],
        ),
        // 기존 앱의 FloatingActionButton 스타일을 이어서 확장형 FAB 사용
        floatingActionButton: ExpandableFab(
          distance: 80,
          children: const [
            // 계정 관련 액션 (예: 관리자 추가)
            ActionButton(
              onPressed: _AdminActions.onTapAddAdmin,
              icon: Icons.admin_panel_settings_outlined,
            ),
            // 게시글 관련 액션 (예: 신고글 목록)
            ActionButton(
              onPressed: _AdminActions.onTapReportedPosts,
              icon: Icons.report_problem_outlined,
            ),
            // Q&A 관련 액션 (예: 미답변 보기)
            ActionButton(
              onPressed: _AdminActions.onTapUnansweredQna,
              icon: Icons.mark_unread_chat_alt_outlined,
            ),
          ],
        ),
      ),
    );
  }
}

/// 실제 기능은 아직 없고, 나중에 Navigator / Dialog 등 연결할 때 여기만 수정하면 됨.
class _AdminActions {
  static void onTapAddAdmin() {
    // TODO: 관리자 추가 화면으로 이동
    debugPrint('관리자 추가 버튼 클릭');
  }

  static void onTapReportedPosts() {
    // TODO: 신고 게시글 목록으로 이동
    debugPrint('신고된 게시글 목록 버튼 클릭');
  }

  static void onTapUnansweredQna() {
    // TODO: 미답변 Q&A 목록으로 이동
    debugPrint('미답변 Q&A 버튼 클릭');
  }
}

/// ----------------------
/// 각 탭 UI
/// ----------------------

class _AccountManageTab extends StatelessWidget {
  const _AccountManageTab();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _SearchBar(hintText: '닉네임, 이메일로 검색'),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: 10, // TODO: 실제 계정 데이터 개수로 변경
            itemBuilder: (context, index) {
              return _AdminCard(
                title: 'user_$index 닉네임',
                subtitle: 'email$index@example.com',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ChipLabel(
                      label: index % 2 == 0 ? '일반회원' : '정지회원',
                      color: index % 2 == 0
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.08),
                      textColor:
                      index % 2 == 0 ? Colors.green[700]! : Colors.red[700]!,
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.more_vert, size: 20),
                      onPressed: () {
                        // TODO: 계정 상세/정지/해제 액션
                      },
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

class _PostManageTab extends StatelessWidget {
  const _PostManageTab();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _SearchBar(hintText: '제목, 닉네임, 태그로 검색'),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: 10, // TODO: 실제 게시글 데이터 개수로 변경
            itemBuilder: (context, index) {
              return _AdminCard(
                title: '사진 게시글 제목 $index',
                subtitle: '작성자: user_$index · 신고  ${index % 3}건',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.visibility_outlined, size: 20),
                      onPressed: () {
                        // TODO: 게시글 상세보기
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      onPressed: () {
                        // TODO: 게시글 삭제
                      },
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
            itemCount: 10, // TODO: 실제 Q&A 데이터 개수로 변경
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
                      color: answered
                          ? Colors.blue.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                      textColor: answered
                          ? Colors.blue[700]!
                          : Colors.orange[800]!,
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.edit_note_outlined, size: 22),
                      onPressed: () {
                        // TODO: 답변 작성/수정 화면
                      },
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

  const _AdminCard({
    required this.title,
    required this.subtitle,
    this.trailing,
  });

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
          // 왼쪽 텍스트 영역
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
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
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
