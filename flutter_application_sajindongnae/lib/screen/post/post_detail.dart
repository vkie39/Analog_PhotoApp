import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart'; 
import 'package:flutter_application_sajindongnae/models/post_model.dart';
import 'package:flutter_application_sajindongnae/component/comment_list.dart'; // 댓글 컴포넌트 분리한 위젯
import 'package:flutter_application_sajindongnae/models/comment_model.dart';     // ✅ 추가됨
import 'package:flutter_application_sajindongnae/services/comment_service.dart'; // ✅ 추가됨
import 'package:flutter_application_sajindongnae/services/post_service.dart';
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
  

    // 수정된 부분: 댓글 저장 방식 변경
  void _submitComment() async {
    FocusScope.of(context).unfocus();

    final commentText = _commentController.text.trim();
    if (commentText.isEmpty) return;
    
    final commentId = const Uuid().v4();  // UUID로 고유 ID 생성

     // 🔑 현재 로그인한 사용자 가져오기
    final user = FirebaseAuth.instance.currentUser; // ✅ 여기서 user 변수를 정의

    final newComment = CommentModel(     // CommentModel 객체 생성
      commentId: commentId,
      //uid: '임시유저ID', // 로그인 연동 시 교체
      uid: user?.uid ?? 'guest',
      nickname: user?.email ?? '익명', 
      profileImageUrl: '',
      content: commentText,
      timestamp: DateTime.now(),
    );

    try {
      await CommentService.addComment(widget.post.postId, newComment);  // CommentService 호출로 변경
      _commentController.clear();  // 입력창 비우기
    } catch (e) {
      print('댓글 업로드 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('댓글 등록에 실패했어요. 다시 시도해주세요.')),
      );
    }
  }

@override
void initState() {
  super.initState();
  likeCount = widget.post.likeCount;

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
/*
  void _toggleLike() async{
    setState(() {
      isLiked = !isLiked;
      likeCount += isLiked ? 1 : -1;
    });

    //await FirebaseFirestore.instance  // post_service로 옮길 내용
    //.collection('posts')
    //.doc(widget.post.postId)
    //.update({'likeCount': likeCount});
    try {
      await PostService.updateLikeCount(widget.post.postId, likeCount);
    } catch (e) {
      log('좋아요 업데이트 실패: $e');
    }
    
  }*/

  //좋아요 중복 방지를 위해 수정
  void _toggleLike() async {
  try {
    await PostService.toggleLike(widget.post.postId);

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() {
      // Firestore에 반영된 likedBy 기반으로 내 상태 토글
      if (widget.post.likedBy.contains(uid)) {
        widget.post.likedBy.remove(uid);
        likeCount -= 1;
        isLiked = false;
      } else {
        widget.post.likedBy.add(uid);
        likeCount += 1;
        isLiked = true;
      }
    });
  } catch (e) {
    log('좋아요 토글 실패: $e');
  }
}


/* 원래코드 주석처리
  @overridevoid _toggleLike() async {
  try {
    await PostService.toggleLike(widget.post.postId);

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() {
      // Firestore에 반영된 likedBy 기반으로 내 상태 토글
      if (widget.post.likedBy.contains(uid)) {
        widget.post.likedBy.remove(uid);
        likeCount -= 1;
        isLiked = false;
      } else {
        widget.post.likedBy.add(uid);
        likeCount += 1;
        isLiked = true;
      }
    });
  } catch (e) {
    log('좋아요 토글 실패: $e');
  }
}
*/
  Widget build(BuildContext context) { // build는 ui를 그리는 함수 (항상 Widget을 반환함)
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar( // 상단바(게시글 카테고리, 이전 버튼)
        title: Text('${widget.post.category} 게시판'), 
        centerTitle: true,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent, 
        foregroundColor: Colors.black,
        elevation: 0,
        ),

        body: Container(
          color: const Color.fromARGB(255, 255, 255, 255),
          child: ListView(
            //padding: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            children: [
              Row( // 글 작성자 정보
                children: [
                  CircleAvatar( // 프사
                    backgroundImage: NetworkImage(widget.post.profileImageUrl),
                    radius: 20,
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.post.nickname, // 닉네임
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      Text( // 작성 시간간
                        _getFormattedTime(widget.post.timestamp),
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                  //Icon(Icons.more_vert_rounded)
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
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: double.infinity, // 부모의 최대 너비까지
                          ),
                          child: Image.network(
                            widget.post.imageUrl!,
                            fit: BoxFit.fitWidth, // 너비에 맞추고, 세로는 비율대로 조정
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
              // 제목
              

              const SizedBox(height: 16),
              const Divider(height: 32, thickness: 0.5, color: Color.fromARGB(255, 180, 180, 180),),
              
              // 좋아요, 댓글 수 표시
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
                        Text('$likeCount', style: const TextStyle(color: Color.fromARGB(255, 161, 161, 161)),),
                      ],)
                  ),
                  const SizedBox(width: 80),
                  const Icon(Icons.comment, size: 30, color: Color.fromARGB(255, 191, 191, 191)),
                  const SizedBox(width: 6),
                  Text('${widget.post.commentCount}', style: const TextStyle(color: Color.fromARGB(255, 161, 161, 161))),
                ],
              ),

              // const Text('댓글', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 18),
              /// 댓글 리스트 위젯 (게시글 ID를 넘겨줘야 함!!)
              CommentList(postId: widget.post.postId), 
            ],
          ),
        ),

        // 댓글 입력용 입력필드
        bottomNavigationBar: Container(
          color: Colors.white,
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 5,
            left:16,
            right: 16,
            top:5,
          ),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8E8E8),
                      borderRadius:  BorderRadius.circular(100),
                    ),
                    child: TextField(
                      controller: _commentController,
                      decoration: const InputDecoration(
                        hintText: '댓글을 입력해주세요',
                        hintStyle: TextStyle(color: Color.fromARGB(255, 189, 189, 189), fontSize: 14),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ), 
                const SizedBox(width: 8),
                IconButton(
                    icon: const Icon(Icons.send, color:const Color.fromARGB(255, 102, 204, 105)),
                    onPressed: _submitComment,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }



String _getFormattedTime(DateTime time) {
  return '${time.year}/${_twoDigits(time.month)}/${_twoDigits(time.day)} '
         '${_twoDigits(time.hour)}:${_twoDigits(time.minute)}';
}

String _twoDigits(int n) => n.toString().padLeft(2, '0'); // 두 자리 채워주는 함수

}