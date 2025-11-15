import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'package:flutter_application_sajindongnae/screen/post/update.dart'; // ✅ main 브랜치에서 추가된 수정 화면
import 'package:flutter_application_sajindongnae/models/post_model.dart';
import 'package:flutter_application_sajindongnae/component/comment_list.dart';
import 'package:flutter_application_sajindongnae/models/comment_model.dart';
import 'package:flutter_application_sajindongnae/services/comment_service.dart';
import 'package:flutter_application_sajindongnae/services/post_service.dart';
import 'dart:developer';
import 'dart:developer' as dev;

enum MoreAction { report, edit, delete }

class PostDetailScreen extends StatefulWidget {
  final PostModel post; // 게시글 객체 받아옴
  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  bool isLiked = false; // 좋아요 상태
  int likeCount = 0; // 좋아요 수
  final uid = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    likeCount = widget.post.likeCount;

    // 브랜치에서 있던 좋아요 초기화 로직 유지
    if (uid != null && widget.post.likedBy.contains(uid)) {
      isLiked = true;
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // 브랜치에서 개선된 likedBy 기반 좋아요 토글 로직 반영
  void _toggleLike(PostModel post) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('로그인이 필요합니다.')));
      return;
    }
    try {
      // Firestore 좋아요 토글
      await PostService.toggleLike(post.postId);
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      setState(() {
        if (post.likedBy.contains(uid)) {
          post.likedBy.remove(uid);
          likeCount -= 1;
          isLiked = false;
        } else {
          post.likedBy.add(uid);
          likeCount += 1;
          isLiked = true;
        }
      });
    } catch (e, stack) {
      // 에러 잡기
      dev.log('좋아요 토글 실패: $e', stackTrace: stack);

      // 사용자 안내
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('좋아요 업데이트에 실패했습니다. 잠시 후 다시 시도해주세요.')),
      );
    }
  }

  // 댓글 등록
  void _submitComment(PostModel post) async {
    FocusScope.of(context).unfocus();
    final commentText = _commentController.text.trim();
    if (commentText.isEmpty) return;

    final commentId = const Uuid().v4();
    final user = FirebaseAuth.instance.currentUser;

    final newComment = CommentModel(
      commentId: commentId,
      uid: user?.uid ?? 'guest',
      nickname: user?.email ?? '익명',
      profileImageUrl: '',
      content: commentText,
      timestamp: DateTime.now(),
    );

    try {
      await CommentService.addComment(post.postId, newComment);
      _commentController.clear();
    } catch (e) {
      print('댓글 업로드 실패: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('댓글 등록에 실패했어요. 다시 시도해주세요.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      //자동 갱신 방식 (Firestore 실시간 스트림)
      stream:
          FirebaseFirestore.instance
              .collection('posts')
              .doc(widget.post.postId)
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final isOwner = widget.post.uid == uid;
        final post = PostModel.fromDocument(snapshot.data!);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => FocusScope.of(context).unfocus(),
          child: Scaffold(
            backgroundColor: const Color(0xFFFFFFFF),
            appBar: AppBar(
              title: Text('${post.category} 게시판'),
              centerTitle: true,
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 0.5,

              actions: [
                PopupMenuButton<MoreAction>(
                  icon: const Icon(Icons.more_vert), // 점 3개 아이콘 명시
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  color: Colors.white, // 메뉴 배경색
                  elevation: 6, // 그림자 깊이
                  position: PopupMenuPosition.under, // 메뉴가 버튼 아래에 나타나도록 설정
                  // 메뉴 항목 선택 시 처리
                  onSelected: (MoreAction action) async {
                    switch (action) {
                      case MoreAction.report:
                        dev.log('신고하기 선택됨');
                        // 신고하기 로직 추가
                        break;
                      case MoreAction.edit:
                        dev.log('수정하기 선택됨');
                        // 수정하기 로직 추가
                        final updatedPost = await Navigator.of(
                          context,
                        ).push<PostModel>(
                          MaterialPageRoute(
                            builder:
                                (context) => UpdateScreen(existingPost: post),
                          ),
                        );
                        if (updatedPost != null) {
                          // 자동 갱신이 있으니 여기선 setState 불필요
                        }
                        break;
                      case MoreAction.delete:
                        dev.log('삭제하기 선택됨');
                        // 삭제 확인 다이얼로그 표시
                        final shouldDelete = await showDialog<bool>(
                          context: context,
                          builder:
                              (context) => AlertDialog(
                                shape: RoundedRectangleBorder(
                                  // 모서리 둥글게
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                backgroundColor: Colors.white, // 배경색
                                title: const Text('정말로 이 판매글을 삭제하시겠습니까?'), // 제목
                                content: const Text('삭제 후에는 복구할 수 없습니다.'), // 내용
                                actions: [
                                  TextButton(
                                    onPressed:
                                        () => Navigator.of(context).pop(false),
                                    child: const Text(
                                      '취소',
                                      style: TextStyle(color: Colors.black),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed:
                                        () => Navigator.of(context).pop(true),
                                    child: const Text(
                                      '삭제',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                        );
                        // 사용자가 삭제를 확인했을 때 삭제 로직 실행
                        if (shouldDelete == true) {
                          dev.log('삭제 로직 실행됨');
                          await PostService.deletePostWithImage(post);
                          Navigator.of(context).pop(); // 삭제 후 이전 화면으로 돌아감
                        }
                        break;
                    }
                  },

                  // 메뉴 항목. 작성자와 비작성자에 따라 다르게 표시
                  itemBuilder: (BuildContext context) {
                    if (isOwner) {
                      return const [
                        PopupMenuItem<MoreAction>(
                          value: MoreAction.edit,
                          child: Text('수정하기'),
                        ),
                        PopupMenuDivider(height: 5), // 구분선

                        PopupMenuItem<MoreAction>(
                          value: MoreAction.delete,
                          child: Text('삭제하기'),
                        ),
                      ];
                    } else {
                      return const [
                        PopupMenuItem<MoreAction>(
                          value: MoreAction.report,
                          child: Text('신고하기'),
                        ),
                      ];
                    }
                  },
                ),
              ],
            ),
            body: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: NetworkImage(post.profileImageUrl),
                      radius: 20,
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.nickname,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          _getFormattedTime(post.timestamp),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(
                  height: 32,
                  thickness: 0.5,
                  color: Color.fromARGB(255, 180, 180, 180),
                ),
                const SizedBox(height: 10),
                Text(
                  post.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(post.content, style: const TextStyle(fontSize: 15)),
                if (post.imageUrl != null) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      post.imageUrl!,
                      fit: BoxFit.fitWidth,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(child: CircularProgressIndicator());
                      },
                      errorBuilder:
                          (context, error, stackTrace) => Container(
                            height: 200,
                            color: Colors.grey[200],
                            child: const Center(
                              child: Icon(
                                Icons.broken_image,
                                color: Colors.grey,
                                size: 40,
                              ),
                            ),
                          ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                const Divider(
                  height: 32,
                  thickness: 0.5,
                  color: Color.fromARGB(255, 180, 180, 180),
                ),
                Row(
                  children: [
                    InkWell(
                      onTap: () => _toggleLike(post),
                      child: Row(
                        children: [
                          Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            size: 30,
                            color:
                                isLiked
                                    ? const Color.fromARGB(255, 102, 204, 105)
                                    : const Color.fromARGB(255, 161, 161, 161),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$likeCount',
                            style: const TextStyle(
                              color: Color.fromARGB(255, 161, 161, 161),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 80),
                    const Icon(
                      Icons.comment,
                      size: 30,
                      color: Color.fromARGB(255, 191, 191, 191),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${post.commentCount}',
                      style: const TextStyle(
                        color: Color.fromARGB(255, 161, 161, 161),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                CommentList(postId: post.postId),
              ],
            ),
            bottomNavigationBar: Container(
              color: Colors.white,
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 5,
                left: 16,
                right: 16,
                top: 5,
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8E8E8),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: TextField(
                          controller: _commentController,
                          decoration: const InputDecoration(
                            hintText: '댓글을 입력해주세요',
                            hintStyle: TextStyle(
                              color: Color.fromARGB(255, 189, 189, 189),
                              fontSize: 14,
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(
                        Icons.send,
                        color: Color.fromARGB(255, 102, 204, 105),
                      ),
                      onPressed: () => _submitComment(post),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _getFormattedTime(DateTime time) {
    return '${time.year}/${_twoDigits(time.month)}/${_twoDigits(time.day)} '
        '${_twoDigits(time.hour)}:${_twoDigits(time.minute)}';
  }

  String _twoDigits(int n) => n.toString().padLeft(2, '0');
}
