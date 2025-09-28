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

  @override
  void initState() {
    super.initState();
    likeCount = widget.post.likeCount;

    // ✅ HEAD 브랜치에서 있던 좋아요 초기화 로직 유지
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null && widget.post.likedBy.contains(uid)) {
      isLiked = true;
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // ✅ HEAD 브랜치에서 개선된 likedBy 기반 좋아요 토글 로직 반영
  void _toggleLike(PostModel post) async {
    try {
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
    } catch (e) {
      log('좋아요 토글 실패: $e');
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('댓글 등록에 실패했어요. 다시 시도해주세요.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      //자동 갱신 방식 (Firestore 실시간 스트림)
      stream: FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.post.postId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final post = PostModel.fromDocument(snapshot.data!);

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => FocusScope.of(context).unfocus(),
          child: Scaffold(
            appBar: AppBar(
              title: Text('${post.category} 게시판'),
              centerTitle: true,
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              foregroundColor: Colors.black,
              elevation: 0,
              actions: [
                // ✅ main 브랜치에서 추가된 게시글 수정/삭제 기능 유지
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'edit') {
                      final updatedPost =
                          await Navigator.of(context).push<PostModel>(
                        MaterialPageRoute(
                          builder: (context) =>
                              UpdateScreen(existingPost: post),
                        ),
                      );
                      if (updatedPost != null) {
                        // 자동 갱신이 있으니 여기선 setState 불필요
                      }
                    } else if (value == 'delete') {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            title: const Text('게시글 삭제',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.black87)),
                            content: const Text('정말 이 게시글을 삭제하시겠어요?',
                                style: TextStyle(
                                    fontSize: 15, color: Colors.black54)),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('취소',
                                    style: TextStyle(
                                        color: Colors.grey, fontSize: 14)),
                              ),
                              TextButton(
                                onPressed: () async {
                                  Navigator.of(context).pop();
                                  await PostService.deletePostWithImage(post);
                                  Navigator.pop(context);
                                },
                                child: const Text('삭제',
                                    style: TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14)),
                              ),
                            ],
                          );
                        },
                      );
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('수정하기',
                          style: TextStyle(
                              fontSize: 14, color: Colors.black87)),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('삭제하기',
                          style: TextStyle(
                              fontSize: 14, color: Colors.black87)),
                    ),
                  ],
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  icon: const Icon(Icons.more_vert_rounded,
                      color: Colors.black),
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
                        Text(post.nickname,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14)),
                        Text(_getFormattedTime(post.timestamp),
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                const Divider(
                    height: 32,
                    thickness: 0.5,
                    color: Color.fromARGB(255, 180, 180, 180)),
                const SizedBox(height: 10),
                Text(post.title,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text(post.content,
                    style: const TextStyle(fontSize: 15)),
                if (post.imageUrl != null) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      post.imageUrl!,
                      fit: BoxFit.fitWidth,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(
                            child: CircularProgressIndicator());
                      },
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 200,
                        color: Colors.grey[200],
                        child: const Center(
                          child: Icon(Icons.broken_image,
                              color: Colors.grey, size: 40),
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                const Divider(
                    height: 32,
                    thickness: 0.5,
                    color: Color.fromARGB(255, 180, 180, 180)),
                Row(
                  children: [
                    InkWell(
                      onTap: () => _toggleLike(post),
                      child: Row(
                        children: [
                          Icon(
                            isLiked
                                ? Icons.favorite
                                : Icons.favorite_border,
                            size: 30,
                            color: isLiked
                                ? const Color.fromARGB(255, 102, 204, 105)
                                : const Color.fromARGB(255, 161, 161, 161),
                          ),
                          const SizedBox(width: 6),
                          Text('$likeCount',
                              style: const TextStyle(
                                  color: Color.fromARGB(255, 161, 161, 161))),
                        ],
                      ),
                    ),
                    const SizedBox(width: 80),
                    const Icon(Icons.comment,
                        size: 30,
                        color: Color.fromARGB(255, 191, 191, 191)),
                    const SizedBox(width: 6),
                    Text('${post.commentCount}',
                        style: const TextStyle(
                            color: Color.fromARGB(255, 161, 161, 161))),
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
                                fontSize: 14),
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 16),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.send,
                          color: Color.fromARGB(255, 102, 204, 105)),
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
