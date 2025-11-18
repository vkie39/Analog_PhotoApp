import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'package:flutter_application_sajindongnae/screen/post/update.dart';
import 'package:flutter_application_sajindongnae/models/post_model.dart';
import 'package:flutter_application_sajindongnae/component/comment_list.dart';
import 'package:flutter_application_sajindongnae/models/comment_model.dart';
import 'package:flutter_application_sajindongnae/services/comment_service.dart';
import 'package:flutter_application_sajindongnae/services/post_service.dart';
import 'package:flutter_application_sajindongnae/screen/post/report.dart';
import 'dart:developer' as dev;

enum MoreAction { report, edit, delete }

class PostDetailScreen extends StatefulWidget {
  final PostModel post;
  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  final uid = FirebaseAuth.instance.currentUser?.uid;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------------
  //
  // HEAD 브랜치에서 개선된 likedBy 기반 좋아요 토글 로직의 주석은 유지하지만,
  // 실제 구현은 min-branch 구조에 맞게 Firestore에 반영 후 StreamBuilder가 UI를 업데이트함.
  //
  // setState로 즉시 UI를 조작하는 부분은 Firestore 실시간 데이터와 충돌하므로 제거하였음.
  //
  // ----------------------------------------------------------------------------------

  void _toggleLike(BuildContext ctx, PostModel post) async {

    // ---------------------------------------------------------------------------------
    // 함경민이 11-16일에 수정한 부분 (주석 유지)
    // ---------------------------------------------------------------------------------

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(
          content: Text('로그인 후 이용해주세요.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      await PostService.toggleLike(post.postId);
    } catch (e) {
      dev.log('좋아요 토글 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('좋아요 업데이트에 실패했습니다. 잠시 후 다시 시도해주세요.')),
      );
    }

    // ---------------------------------------------------------------------------------
    // 수정 끝
    // ----------------------------------------------------------------------------------
  }

  // 댓글 등록
  void _submitComment(PostModel post) async {
    FocusScope.of(context).unfocus();
    final commentText = _commentController.text.trim();
    if (commentText.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final commentId = const Uuid().v4();

    // [수정] Firestore users 컬렉션에서 nickname, profileImageUrl 가져오기
    final userDoc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .get();

    final nickname = userDoc.data()?["nickname"] ?? "사용자";                 // [수정]
    final profileImageUrl = userDoc.data()?["profileImageUrl"]
                              ?? user.photoURL
                              ?? "";                                        // [수정]

    final newComment = CommentModel(
      commentId: commentId,
      uid: user.uid,
      nickname: nickname,                // [수정]
      profileImageUrl: profileImageUrl,  // [수정]
      content: commentText,
      timestamp: DateTime.now(),
    );

    try {
      await CommentService.addComment(post.postId, newComment);
      _commentController.clear();
    } catch (e) {
      dev.log('댓글 업로드 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('댓글 등록에 실패했어요. 다시 시도해주세요.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
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
        final isOwner = post.uid == uid;

        final bool isLiked = uid != null && post.likedBy.contains(uid);
        final int likeCount = post.likeCount;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => FocusScope.of(context).unfocus(),
          child: Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              title: Text('${post.category} 게시판'),
              centerTitle: true,
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 0.5,

              actions: [
                PopupMenuButton<MoreAction>(
                  icon: const Icon(Icons.more_vert),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  color: Colors.white,
                  elevation: 6,
                  position: PopupMenuPosition.under,

                  onSelected: (MoreAction action) async {
                    switch (action) {
                      case MoreAction.report:
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ReportPostScreen(
                              postId: post.postId,
                              postType: 'posts', // posts / photo_trades / requests 구분
                              reasons: [
                                '스팸홍보/도배글입니다.',
                                '음란물입니다.',
                                '불법정보를 포함하고 있습니다.',
                                '청소년에게 유해한 내용입니다.',
                                '욕설 및 혐오 표현입니다.',
                                '개인정보 노출 게시물입니다.',
                                '불쾌한 표현이 있습니다.',
                                '기타 내용',
                              ],
                            ),
                          ),
                        );
                        break;


                      case MoreAction.edit:
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                UpdateScreen(existingPost: post),
                          ),
                        );
                        break;

                      case MoreAction.delete:
                        final shouldDelete = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            backgroundColor: Colors.white,
                            title: const Text('정말로 이 판매글을 삭제하시겠습니까?'),
                            content: const Text('삭제 후에는 복구할 수 없습니다.'),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: const Text('취소', style: TextStyle(color: Colors.black)),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                child: const Text('삭제', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );

                        if (shouldDelete == true) {
                          await PostService.deletePostWithImage(post);
                          Navigator.of(context).pop();
                        }
                        break;
                    }
                  },

                  itemBuilder: (_) {
                    if (isOwner) {
                      return const [
                        PopupMenuItem(
                          value: MoreAction.edit,
                          child: Text('수정하기'),
                        ),
                        PopupMenuDivider(height: 5),
                        PopupMenuItem(
                          value: MoreAction.delete,
                          child: Text('삭제하기'),
                        ),
                      ];
                    } else {
                      return const [
                        PopupMenuItem(
                          value: MoreAction.report,
                          child: Text('신고하기'),
                        ),
                      ];
                    }
                  },
                ),
              ],
            ),

            body: Builder(
              builder: (innerCtx) {
                return ListView(
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
                                  fontSize: 14),
                            ),
                            Text(
                              _getFormattedTime(post.timestamp),
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 12),
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
                          fontSize: 22, fontWeight: FontWeight.bold),
                    ),

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
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return const Center(child: CircularProgressIndicator());
                          },
                          errorBuilder: (_, __, ___) => Container(
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
                      color: Color.fromARGB(255, 180, 180, 180),
                    ),

                    Row(
                      children: [
                        InkWell(
                          onTap: () => _toggleLike(innerCtx, post),
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
                              Text(
                                '$likeCount',
                                style: const TextStyle(
                                  color: Color.fromARGB(255, 161, 161, 161),
                                ),
                              )
                            ],
                          ),
                        ),
                        const SizedBox(width: 80),
                        const Icon(Icons.comment,
                            size: 30,
                            color: Color.fromARGB(255, 191, 191, 191)),
                        const SizedBox(width: 6),
                        Text(
                          '${post.commentCount}',
                          style: const TextStyle(
                            color: Color.fromARGB(255, 161, 161, 161),
                          ),
                        )
                      ],
                    ),

                    const SizedBox(height: 18),
                    CommentList(postId: post.postId),
                  ],
                );
              },
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
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 16),
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
                    )
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
