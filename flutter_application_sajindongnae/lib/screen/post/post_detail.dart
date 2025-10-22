import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_sajindongnae/screen/post/update.dart';

import 'package:uuid/uuid.dart'; 
import 'package:flutter_application_sajindongnae/models/post_model.dart';
import 'package:flutter_application_sajindongnae/component/comment_list.dart'; 
import 'package:flutter_application_sajindongnae/models/comment_model.dart';   
import 'package:flutter_application_sajindongnae/services/comment_service.dart';
import 'package:flutter_application_sajindongnae/services/post_service.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:developer';

class PostDetailScreen extends StatefulWidget {

  // model/post_model.dart에 정의한 데이터 클래스를 담을 PostModel 객체 post 
  final PostModel post; 
  const PostDetailScreen({super.key, required this.post});

  @override // 댓글 실시간 갱신
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final TextEditingController _commentController = TextEditingController(); // 댓글 컨트롤러
  bool isLiked = false; // 좋아요 상태 (색 채울지 말지)
  int likeCount = 0; // 좋아요 수 상태
  late PostModel _post; 

  // 수정된 부분: 댓글 저장 방식 변경
  void _submitComment() async {
    FocusScope.of(context).unfocus();

    final commentText = _commentController.text.trim();
    if (commentText.isEmpty) return;
    
    final commentId = const Uuid().v4();  // UUID로 고유 ID 생성

    final newComment = CommentModel(     // CommentModel 객체 생성
      commentId: commentId,
      userId: '임시유저ID', // 로그인 연동 시 교체
      nickname: '익명',
      profileImageUrl: '',
      content: commentText,
      timestamp: DateTime.now(),
    );

    try {
      await CommentService.addComment(_post.postId, newComment);  

      _commentController.clear();  // 입력창 비우기
    } catch (e) {
      print('댓글 업로드 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('댓글 등록에 실패했어요. 다시 시도해주세요.')),
      );
    }
  }

  @override
  void initState(){
    super.initState();
    _post = widget.post; 
    likeCount = _post.likeCount;
  }


  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _toggleLike() async{
    setState(() {
      isLiked = !isLiked;
      likeCount += isLiked ? 1 : -1;
    });

    try {
      await PostService.updateLikeCount(_post.postId, likeCount); 
    } catch (e) {
      log('좋아요 업데이트 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: Text('${_post.category} 게시판'), 
          centerTitle: true,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent, 
          foregroundColor: Colors.black,
          elevation: 0,

        ),

        body: Container(
          color: const Color.fromARGB(255, 255, 255, 255),
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundImage: NetworkImage(_post.profileImageUrl), 

                    radius: 20,
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_post.nickname, 
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(
                        _getFormattedTime(_post.timestamp),

                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                  const Spacer(),
                  PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'edit') {
                        final updatedPost = await Navigator.of(context).push<PostModel>(
                          MaterialPageRoute(
                            builder: (context) => UpdateScreen(existingPost: _post), 
                          ),
                        );

                        if (updatedPost != null) {
                          setState(() {
                            _post = updatedPost; 
                          });
                        }

                      } else if (value == 'delete') {
                        showDialog(
                          context: context,
                          builder: (dialogContext) {
                            return AlertDialog(
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              title: const Text(
                                '게시글 삭제',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.black87,
                                ),
                              ),
                              content: const Text(
                                '정말 이 게시글을 삭제하시겠어요?',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.black54,
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(dialogContext);
                                  },
                                  child: const Text(
                                    '취소',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    Navigator.of(dialogContext).pop();
                                    await PostService.deletePostWithImage(_post);
                                    Navigator.pop(context);

                                  },
                                  child: const Text(
                                    '삭제',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
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
                        child: Text(
                          '수정하기',
                          style: TextStyle(fontSize: 14, color: Colors.black87),
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text(
                          '삭제하기',
                          style: TextStyle(fontSize: 14, color: Colors.black87),
                        ),
                      ),
                    ],
                    color: Colors.white,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    icon: const Icon(Icons.more_vert_rounded, color: Colors.black),
                  ),
                ],
              ),

              const Divider(height: 32, thickness: 0.5, color: Color.fromARGB(255, 180, 180, 180)),
              const SizedBox(height: 10),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_post.title, 
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Text(_post.content, style: const TextStyle(fontSize: 15)), 
                    if (_post.imageUrl != null) ...[

                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: double.infinity,
                          ),
                          child: Image.network(
                            _post.imageUrl!, 
                            fit: BoxFit.fitWidth,

                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(child: CircularProgressIndicator());
                            },
                            errorBuilder: (context, error, stackTrace) => Container(
                              height: 200,
                              color: Colors.grey[200],
                              child: const Center(
                                child: Icon(Icons.broken_image, color: Colors.grey, size: 40),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),
              const Divider(height: 32, thickness: 0.5, color: Color.fromARGB(255, 180, 180, 180)),

              Row(

                children: [
                  InkWell(
                    onTap: _toggleLike,
                    child: Row(
                      children: [
                        Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          size: 30,
                          color: isLiked
                              ? const Color.fromARGB(255, 102, 204, 105)
                              : const Color.fromARGB(255, 161, 161, 161),
                        ),
                        const SizedBox(width: 6),
                        Text('$likeCount', style: const TextStyle(color: Color.fromARGB(255, 161, 161, 161))),
                      ],
                    ),

                  ),
                  const SizedBox(width: 80),
                  const Icon(Icons.comment, size: 30, color: Color.fromARGB(255, 191, 191, 191)),
                  const SizedBox(width: 6),
                  Text('${_post.commentCount}', style: const TextStyle(color: Color.fromARGB(255, 161, 161, 161))), 
                ],
              ),

              const SizedBox(height: 18),
              CommentList(postId: _post.postId), 

            ],
          ),
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
                        hintStyle: TextStyle(color: Color.fromARGB(255, 189, 189, 189), fontSize: 14),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16),

                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Color.fromARGB(255, 102, 204, 105)),
                  onPressed: _submitComment,

                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}




String _getFormattedTime(DateTime time) {
  return '${time.year}/${_twoDigits(time.month)}/${_twoDigits(time.day)} '
         '${_twoDigits(time.hour)}:${_twoDigits(time.minute)}';
}

String _twoDigits(int n) => n.toString().padLeft(2, '0'); // 두 자리 채워주는 함수


