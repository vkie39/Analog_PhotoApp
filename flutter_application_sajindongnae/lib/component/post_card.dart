import 'package:flutter/material.dart';
import '../models/post_model.dart';
import 'package:flutter_application_sajindongnae/screen/post/post_detail.dart';

class PostCard extends StatelessWidget {
  final PostModel post;

  const PostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PostDetailScreen(post: post)));
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 5),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top:4),
                  child: CircleAvatar(
                    backgroundImage: NetworkImage(post.profileImageUrl),
                    radius: 16,
                  ),
                ),
                const SizedBox(width: 15),

                // 왼쪽 영역: 제목, 내용, 메타정보 (세로)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        post.content ?? '',
                        style: const TextStyle(fontSize: 12, color: Colors.black87),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text('좋아요 ${post.likeCount}   |', style: _metaStyle),
                          const SizedBox(width: 8),
                          Text('댓글 ${post.commentCount}   |', style: _metaStyle),
                          const SizedBox(width: 8),
                          Text(_getTimeAgo(post.timestamp), style: _metaStyle),
                        ],
                      ),
                    ],
                  ),
                ),

                // 오른쪽 썸네일 이미지
                if (post.imageUrl != null) ...[
                  const SizedBox(width: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      post.imageUrl!,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),
            const Divider(thickness: 0.4),
          ],
        ),
      ),
    );
  }

  static const TextStyle _metaStyle = TextStyle(
    fontSize: 10,
    color: Colors.grey,
  );

  static String _getTimeAgo(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) return '방금 전';
    if (difference.inMinutes < 60) return '${difference.inMinutes}분 전';
    if (difference.inHours < 24) return '${difference.inHours}시간 전';
    return '${difference.inDays}일 전';
  }
}
