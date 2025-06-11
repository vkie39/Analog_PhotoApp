import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_sajindongnae/models/post_model.dart';
import 'package:flutter_application_sajindongnae/component/comment_list.dart'; // 댓글 컴포넌트 분리한 위젯

class PostDetailScreen extends StatefulWidget {

  // model/post_model.dart에 정의한 데이터 클래스를 담을 PostModel 객체 post 
  final PostModel post; 
  const PostDetailScreen({super.key, required this.post});

  @override // 댓글 실시간 갱신신
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final TextEditingController _commentController = TextEditingController(); // 댓글 컨트롤러
  bool isLiked = false; // 좋아요 상태 (색 채울지 말지)
  int likeCount = 0; // 좋아요 수 상태태

  void _submitComment() async {
    final commentText = _commentController.text.trim();
    if (commentText.isEmpty) return;

    await FirebaseFirestore.instance.collection('comments').add({  // post_service로 옮길 내용용
      'postId': widget.post.postId,
      'nickname': '익명', 
      'profileImageUrl': '', 
      'content': commentText,
      'timestamp': DateTime.now(),
    });

    _commentController.clear();
  }

  @override
  void initState(){
    super.initState();
    likeCount = widget.post.likeCount; // DB에서 좋아요 수 가져오기
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

    await FirebaseFirestore.instance  // post_service로 옮길 내용
    .collection('posts')
    .doc(widget.post.postId)
    .update({'likeCount': likeCount});
  }


  @override
  Widget build(BuildContext context) { // build는 ui를 그리는 함수 (항상 Widget을 반환함)
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar( // 상단바(게시글 카테고리, 이전 버튼)
        title: Text('${widget.post.category} 게시판'), 
        centerTitle: true,
        backgroundColor: Colors.white,
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
                ],
              ),
              const Divider(height: 32, thickness: 0.5, color: Color.fromARGB(255, 180, 180, 180),),
              const SizedBox(height: 10),
              
              // 제목
              Text(widget.post.title, 
                  style:
                      const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              // 본문
              Text(widget.post.content, style: const TextStyle(fontSize: 15)), 
              // 본문 속 사진
              if (widget.post.imageUrl != null) ...[ 
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(widget.post.imageUrl!),
                )
              ],

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
                                 ? Colors.green
                                 : const Color.fromARGB(255, 161, 161, 161),
                        ),
                        const SizedBox(width: 6),
                        Text('$likeCount', style: const TextStyle(color: Color.fromARGB(255, 161, 161, 161)),),
                      ],)
                  ),
                  const SizedBox(width: 80),
                  const Icon(Icons.comment, size: 30, color: Color.fromARGB(255, 161, 161, 161)),
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
        bottomNavigationBar: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 10,
            left:16,
            right: 16,
            top:2,
          ),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 232, 232, 232),
                      borderRadius:  BorderRadius.circular(100),
                    ),
                    child: TextField(
                      controller: _commentController,
                      decoration: const InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        border: InputBorder.none,
                        //filled: true,
                        //fillColor: const Color.fromARGB(255, 195, 195, 195),
                      ),
                    ),
                  ),
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