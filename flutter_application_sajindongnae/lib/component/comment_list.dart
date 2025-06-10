

// 댓글을 실시간으로 불러와 보여주는 리스트 위젯. post_detail.dart에서 사용
// 댓글DB의 Model설계를 추가해서 수정할 예정. lib/models에 comment_model? 같은 게 필요함
// 지금은 임시데이터

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_sajindongnae/models/comment_model.dart';


class CommentList extends StatelessWidget {
  final String postId; // 해당 게시글의 postId를 받아옴

  const CommentList({super.key, required this.postId});

  /*
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>( // StreamBuilder란 Firestore처럼 실시간 데이터 변화를 감지할 수 있는 위젯
      stream: FirebaseFirestore.instance
          .collection('comments') // post라는 DB의 컬렉션으로 comments라는 DB를 갖는 다는 가정하에 만든 코드
          .where('postId', isEqualTo: postId) // DB쿼리 : postId(comments) == postId(현재 post) 인 comment를 가져옴 (postId가 일치하는 댓글만 가져옴)
          .orderBy('timestamp') // 시간순으로 정렬렬
          .snapshots(), // 실시간으로 가져옴
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator(); // 데이터 없을 시 로딩 표시(flutter 기본 내장 위젯)

        final comments = snapshot.data!.docs; //댓글 리스트 저장. 각 댓글 정보가 DocumentSnapshot

        return ListView.builder(
          shrinkWrap: true, // 부모 위젯의 크기에 맞게 줄어듦
          physics: const NeverScrollableScrollPhysics(), // 내부 스크롤 비활성화 (부모 스크롤에 위임), 댓글 리스트가 포함될 post_detail위젯에 이미 스크롤이 있음음
          itemCount: comments.length, // 렌더링할 댓글 수
          itemBuilder: (context, index) {
            final data = comments[index].data() as Map<String, dynamic>;

            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundImage: NetworkImage(data['profileImage']),
              ),
              title: Text(data['nickname'],
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data['content']),
                  const SizedBox(height: 4),
                  Text(
                    _getTimeAgo((data['timestamp'] as Timestamp).toDate()),
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
*/
  // Firestore 연동 전 임시 댓글 데이터
  @override
  Widget build(BuildContext context) {
    final List<CommentModel> comments = List.generate(
      5,
      (index) => CommentModel(
        commentId: 'comment_$index',
        postId: postId, // 전달받은 postId와 매칭
        userId: 'user_$index',
        nickname: '댓글 작성자$index',
        profileImageUrl: 'https://via.placeholder.com/150',
        content: '이것은 $index번째 임시 댓글입니다.',
        timestamp: DateTime.now().subtract(Duration(minutes: index * 7)),
      ),
    );

    return Column(
      children: comments.map((comment) {
        // 본문
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8),
          child: Column (
            children: [ 
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: CircleAvatar(
                      radius: 16,
                      backgroundImage: NetworkImage(comment.profileImageUrl),
                    ),
                  ),
                  const SizedBox(width: 13),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 1),
                        Text(comment.nickname,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 0),
                        Text(_getFormattedTime(comment.timestamp),
                            style: const TextStyle(
                                fontSize: 10, color: Colors.grey)),
                        const SizedBox(height: 3),
                        Text(comment.content,
                            style: const TextStyle(fontSize: 12)),
                        const SizedBox(height: 15),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(
                color: Color.fromARGB(255, 180, 180, 180), // 회색 줄
                thickness: 0.3,     // 줄의 두께
                height: 2,          // 위아래 간격
              ),
            ],
          ),
        );
      }).toList(),
    );
  }


String _getFormattedTime(DateTime time) {
  return '${time.year}/${_twoDigits(time.month)}/${_twoDigits(time.day)} '
         '${_twoDigits(time.hour)}:${_twoDigits(time.minute)}';
}

String _twoDigits(int n) => n.toString().padLeft(2, '0'); // 두 자리 채워주는 함수수

}
