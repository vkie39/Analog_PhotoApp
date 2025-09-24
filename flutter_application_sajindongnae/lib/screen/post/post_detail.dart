import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'package:flutter_application_sajindongnae/screen/post/update.dart';
=======
>>>>>>> origin/main
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
<<<<<<< HEAD
  late PostModel _post; 
=======
>>>>>>> origin/main

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
<<<<<<< HEAD
      await CommentService.addComment(_post.postId, newComment);  
=======
      await CommentService.addComment(widget.post.postId, newComment);  // CommentService 호출로 변경
>>>>>>> origin/main
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
<<<<<<< HEAD
    _post = widget.post; 
    likeCount = _post.likeCount;
  }

=======
    likeCount = widget.post.likeCount; // DB에서 좋아요 수 가져오기
  }


>>>>>>> origin/main
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

<<<<<<< HEAD
    try {
      await PostService.updateLikeCount(_post.postId, likeCount); 
    } catch (e) {
      log('좋아요 업데이트 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
=======
    //await FirebaseFirestore.instance  // post_service로 옮길 내용
    //.collection('posts')
    //.doc(widget.post.postId)
    //.update({'likeCount': likeCount});
    try {
      await PostService.updateLikeCount(widget.post.postId, likeCount);
    } catch (e) {
      log('좋아요 업데이트 실패: $e');
    }
    
  }


  @override
  Widget build(BuildContext context) { // build는 ui를 그리는 함수 (항상 Widget을 반환함)
>>>>>>> origin/main
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
<<<<<<< HEAD
        appBar: AppBar(
          title: Text('${_post.category} 게시판'), 
          centerTitle: true,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent, 
          foregroundColor: Colors.black,
          elevation: 0,
=======
        appBar: AppBar( // 상단바(게시글 카테고리, 이전 버튼)
        title: Text('${widget.post.category} 게시판'), 
        centerTitle: true,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent, 
        foregroundColor: Colors.black,
        elevation: 0,
>>>>>>> origin/main
        ),

        body: Container(
          color: const Color.fromARGB(255, 255, 255, 255),
          child: ListView(
<<<<<<< HEAD
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundImage: NetworkImage(_post.profileImageUrl), 
=======
            //padding: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            children: [
              Row( // 글 작성자 정보
                children: [
                  CircleAvatar( // 프사
                    backgroundImage: NetworkImage(widget.post.profileImageUrl),
>>>>>>> origin/main
                    radius: 20,
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
<<<<<<< HEAD
                      Text(_post.nickname, 
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(
                        _getFormattedTime(_post.timestamp),
=======
                      Text(widget.post.nickname, // 닉네임
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      Text( // 작성 시간
                        _getFormattedTime(widget.post.timestamp),
>>>>>>> origin/main
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
<<<<<<< HEAD
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
=======
                  const Spacer(), // 닉네임-시간과 메뉴 사이 간격을 벌리기
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        // TODO: 수정 로직
>>>>>>> origin/main
                      } else if (value == 'delete') {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
<<<<<<< HEAD
                              backgroundColor: Colors.white,
=======
                              backgroundColor: Colors.white, // 배경 흰색
>>>>>>> origin/main
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
<<<<<<< HEAD
                                    Navigator.pop(context);
=======
                                    Navigator.pop(context); // 다이얼로그 닫기
>>>>>>> origin/main
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
<<<<<<< HEAD
                                    Navigator.of(context).pop();
                                    await PostService.deletePostWithImage(_post);
                                    Navigator.pop(context);
=======
                                    Navigator.of(context).pop(); // 다이얼로그 닫기
                                    await PostService.deletePostWithImage(widget.post); // 삭제 실행
                                    Navigator.pop(context); // 게시글 상세 화면 닫기
>>>>>>> origin/main
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
<<<<<<< HEAD
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
=======
                      PopupMenuItem(
                        value: 'edit',
                        child: const Text(
                          '수정하기',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: const Text(
                          '삭제하기',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                    color: Colors.white, // 팝업 배경 흰색
>>>>>>> origin/main
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    icon: const Icon(Icons.more_vert_rounded, color: Colors.black),
                  ),
<<<<<<< HEAD
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
=======

                ],
              ),
                            
              const Divider(height: 32, thickness: 0.5, color: Color.fromARGB(255, 180, 180, 180),),
              const SizedBox(height: 10),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16), //좌우 패딩
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 제목
                    Text(
                      widget.post.title, 
                      style:const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    // 본문
                    Text(widget.post.content, style: const TextStyle(fontSize: 15)), 
                    // 본문 속 사진
                    if (widget.post.imageUrl != null) ...[
>>>>>>> origin/main
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
<<<<<<< HEAD
                            maxWidth: double.infinity,
                          ),
                          child: Image.network(
                            _post.imageUrl!, 
                            fit: BoxFit.fitWidth,
=======
                            maxWidth: double.infinity, // 부모의 최대 너비까지
                          ),
                          child: Image.network(
                            widget.post.imageUrl!,
                            fit: BoxFit.fitWidth, // 너비에 맞추고, 세로는 비율대로 조정
>>>>>>> origin/main
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
<<<<<<< HEAD
                  ],
                ),
              ),

              const SizedBox(height: 16),
              const Divider(height: 32, thickness: 0.5, color: Color.fromARGB(255, 180, 180, 180)),

              Row(
=======

                  ],
                ),
              ),
              // 제목
              

              const SizedBox(height: 16),
              const Divider(height: 32, thickness: 0.5, color: Color.fromARGB(255, 180, 180, 180),),
              
              // 좋아요, 댓글 수 표시
              Row( 
>>>>>>> origin/main
                children: [
                  InkWell(
                    onTap: _toggleLike,
                    child: Row(
                      children: [
                        Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
<<<<<<< HEAD
                          size: 30,
                          color: isLiked
                              ? const Color.fromARGB(255, 102, 204, 105)
                              : const Color.fromARGB(255, 161, 161, 161),
                        ),
                        const SizedBox(width: 6),
                        Text('$likeCount', style: const TextStyle(color: Color.fromARGB(255, 161, 161, 161))),
                      ],
                    ),
=======
                          size: 30, 
                          color: isLiked
                                 ? const Color.fromARGB(255, 102, 204, 105)
                                 : const Color.fromARGB(255, 161, 161, 161),
                        ),
                        const SizedBox(width: 6),
                        Text('$likeCount', style: const TextStyle(color: Color.fromARGB(255, 161, 161, 161)),),
                      ],)
>>>>>>> origin/main
                  ),
                  const SizedBox(width: 80),
                  const Icon(Icons.comment, size: 30, color: Color.fromARGB(255, 191, 191, 191)),
                  const SizedBox(width: 6),
<<<<<<< HEAD
                  Text('${_post.commentCount}', style: const TextStyle(color: Color.fromARGB(255, 161, 161, 161))), 
                ],
              ),

              const SizedBox(height: 18),
              CommentList(postId: _post.postId), 
=======
                  Text('${widget.post.commentCount}', style: const TextStyle(color: Color.fromARGB(255, 161, 161, 161))),
                ],
              ),

              // const Text('댓글', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 18),
              /// 댓글 리스트 위젯 (게시글 ID를 넘겨줘야 함!!)
              CommentList(postId: widget.post.postId), 
>>>>>>> origin/main
            ],
          ),
        ),

<<<<<<< HEAD
=======
        // 댓글 입력용 입력필드
>>>>>>> origin/main
        bottomNavigationBar: Container(
          color: Colors.white,
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 5,
<<<<<<< HEAD
            left: 16,
            right: 16,
            top: 5,
=======
            left:16,
            right: 16,
            top:5,
>>>>>>> origin/main
          ),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8E8E8),
<<<<<<< HEAD
                      borderRadius: BorderRadius.circular(100),
=======
                      borderRadius:  BorderRadius.circular(100),
>>>>>>> origin/main
                    ),
                    child: TextField(
                      controller: _commentController,
                      decoration: const InputDecoration(
                        hintText: '댓글을 입력해주세요',
                        hintStyle: TextStyle(color: Color.fromARGB(255, 189, 189, 189), fontSize: 14),
<<<<<<< HEAD
                        contentPadding: EdgeInsets.symmetric(horizontal: 16),
=======
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
>>>>>>> origin/main
                        border: InputBorder.none,
                      ),
                    ),
                  ),
<<<<<<< HEAD
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Color.fromARGB(255, 102, 204, 105)),
                  onPressed: _submitComment,
=======
                ), 
                const SizedBox(width: 8),
                IconButton(
                    icon: const Icon(Icons.send, color:const Color.fromARGB(255, 102, 204, 105)),
                    onPressed: _submitComment,
>>>>>>> origin/main
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
<<<<<<< HEAD
}
=======
>>>>>>> origin/main



String _getFormattedTime(DateTime time) {
  return '${time.year}/${_twoDigits(time.month)}/${_twoDigits(time.day)} '
         '${_twoDigits(time.hour)}:${_twoDigits(time.minute)}';
}

String _twoDigits(int n) => n.toString().padLeft(2, '0'); // 두 자리 채워주는 함수

<<<<<<< HEAD
=======
}
>>>>>>> origin/main
