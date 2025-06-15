import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/comment_model.dart';
import '../services/comment_service.dart'; // CommentService 사용

/// 특정 게시글(postId)의 댓글 목록을 실시간으로 보여주는 위젯
class CommentList extends StatelessWidget {
  final String postId;

  const CommentList({super.key, required this.postId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CommentModel>>(
      stream: CommentService.getComments(postId), // 실시간 댓글 스트림
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator()); // 로딩 표시
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text('아직 댓글이 없습니다.', style: TextStyle(fontSize: 14, color: Colors.grey)),
          );
        }

        final comments = snapshot.data!;

        return Column(
          children: comments.map((comment) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8),
              child: Column(
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
                            Text(
                              comment.nickname,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(height: 0),
                            Text(
                              _getFormattedTime(comment.timestamp),
                              style: const TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              comment.content,
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(height: 15),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(
                    color: Color.fromARGB(255, 180, 180, 180),
                    thickness: 0.3,
                    height: 2,
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  /// 날짜 및 시간을 "YYYY/MM/DD HH:mm" 형식으로 포맷
  String _getFormattedTime(DateTime time) {
    return '${time.year}/${_twoDigits(time.month)}/${_twoDigits(time.day)} '
           '${_twoDigits(time.hour)}:${_twoDigits(time.minute)}';
  }

  /// 두 자리수로 포맷 (9 → 09)
  String _twoDigits(int n) => n.toString().padLeft(2, '0');
}
