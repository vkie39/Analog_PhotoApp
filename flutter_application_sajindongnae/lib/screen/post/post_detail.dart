import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_sajindongnae/models/post_model.dart';
import 'package:flutter_application_sajindongnae/component/comment_list.dart'; // 댓글 컴포넌트 분리한 위젯

class PostDetailScreen extends StatelessWidget {

  // model/post_model.dart에 정의한 데이터 클래스를 담을 PostModel 객체 post 
  final PostModel post; 


  const PostDetailScreen({super.key, required this.post});

  @override
  Widget build(BuildContext context) { // build는 ui를 그리는 함수 (항상 Widget을 반환함)
    return Scaffold(
      appBar: AppBar( // 상단바(게시글 카테고리, 이전 버튼)
        title: Text(post.category), 
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row( // 글 작성자 정보
            children: [
              CircleAvatar( // 프사
                backgroundImage: NetworkImage(post.profileImageUrl),
                radius: 20,
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(post.nickname, // 닉네임
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  Text( // 작성 시간간
                    _getTimeAgo(post.timestamp),
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          Text(post.title, // 제목
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          Text(post.content, style: const TextStyle(fontSize: 14)), // 본문

          if (post.imageUrl != null) ...[ // 본문 속 사진
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(post.imageUrl!),
            )
          ],

          const SizedBox(height: 16),

          Row( // 좋아요, 댓글 수 표시
            children: [
              const Icon(Icons.favorite_border, size: 20),
              const SizedBox(width: 6),
              Text('${post.likeCount}'),
              const SizedBox(width: 20),
              const Icon(Icons.comment, size: 20),
              const SizedBox(width: 6),
              Text('${post.commentCount}'),
            ],
          ),

          const Divider(height: 32),
          const Text('댓글', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          /// 댓글 리스트 위젯 (게시글 ID를 넘겨줘야 함!!)
          CommentList(postId: post.postId), 
        ],
      ),
    );
  }


  String _getTimeAgo(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return '방금 전';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    return '${diff.inDays}일 전';
  }
}
