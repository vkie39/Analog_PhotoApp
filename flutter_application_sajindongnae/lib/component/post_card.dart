import 'package:flutter/material.dart';
import '../models/post_model.dart';

class PostCard extends StatelessWidget {
  final PostModel post;

  const PostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: CircleAvatar(
            backgroundImage: NetworkImage(post.profileImageUrl),
          ),
          title: Text(post.title, style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(post.nickname),
          trailing: Text(
            _getTimeAgo(post.timestamp),
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
        if (post.imageUrl != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(post.imageUrl!),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Text('좋아요 ${post.likeCount}'),
              SizedBox(width: 10),
              Text('댓글 ${post.commentCount}'),
            ],
          ),
        ),
        Divider(thickness: 1),
      ],
    );
  }

  String _getTimeAgo(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    if (difference.inMinutes < 1) return '방금 전';
    if (difference.inMinutes < 60) return '${difference.inMinutes}분 전';
    if (difference.inHours < 24) return '${difference.inHours}시간 전';
    return '${difference.inDays}일 전';
  }
}
