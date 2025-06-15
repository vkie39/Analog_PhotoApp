import 'package:flutter/material.dart';
import '../models/post_model.dart';
import 'package:flutter_application_sajindongnae/screen/post/post_detail.dart';

class PostCard extends StatelessWidget {
  final PostModel post;

  const PostCard({super.key, required this.post});

  
  @override
  Widget build(BuildContext context) {
    print(MediaQuery.of(context).size.width);

    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth <= 360;

    // 비율 기반 설정값 (작은 화면이면 더 작게 조정)
    final imageSize = screenWidth * (isSmallScreen ? 0.15 : 0.18);
    final profileRadius = screenWidth * (isSmallScreen ? 0.035 : 0.04);
    final horizontalPadding = screenWidth * (isSmallScreen ? 0.04 : 0.06);
    final verticalPadding = screenWidth * (isSmallScreen ? 0.01 : 0.013);
    final spacingBetweenProfileAndText = screenWidth * (isSmallScreen ? 0.03 : 0.04);
    final topPaddingForAvatar = screenWidth * 0.011;
    final contentSpacingSmall = screenWidth * 0.009;
    final contentSpacingMedium = screenWidth * 0.013;
    final spacingBetweenMeta = screenWidth * 0.018;
    final dividerSpacing = screenWidth * 0.012;

    final titleFontSize = screenWidth * (isSmallScreen ? 0.035 : 0.038);
    final contentFontSize = screenWidth * (isSmallScreen ? 0.030 : 0.033);
    final metaFontSize = screenWidth * (isSmallScreen ? 0.02 : 0.027);
    final imageBorderRadius = screenWidth * 0.015;
    final iconSize = screenWidth * 0.055;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PostDetailScreen(post: post)),
        );
      },
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: topPaddingForAvatar),
                  child: CircleAvatar(
                    backgroundImage: NetworkImage(post.profileImageUrl),
                    radius: profileRadius,
                  ),
                ),
                SizedBox(width: spacingBetweenProfileAndText),

                /// 텍스트 영역
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: titleFontSize,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: contentSpacingSmall),
                      Text(
                        post.content ?? '',
                        style: TextStyle(
                          fontSize: contentFontSize,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: contentSpacingMedium),
                      Row(
                        children: [
                          Text('좋아요 ${post.likeCount}   |',
                              style: TextStyle(fontSize: metaFontSize, color: Colors.grey)),
                          SizedBox(width: spacingBetweenMeta),
                          Text('댓글 ${post.commentCount}   |',
                              style: TextStyle(fontSize: metaFontSize, color: Colors.grey)),
                          SizedBox(width: spacingBetweenMeta),
                          Text(_getTimeAgo(post.timestamp),
                              style: TextStyle(fontSize: metaFontSize, color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                ),

                /// 썸네일 이미지
                if (post.imageUrl != null && post.imageUrl!.isNotEmpty) ...[
                  SizedBox(width: spacingBetweenMeta),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(imageBorderRadius),
                    child: Container(
                      width: imageSize,
                      height: imageSize,
                      color: Colors.white,
                      child: Image.network(
                        post.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.image_not_supported,
                          size: iconSize,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            SizedBox(height: dividerSpacing),
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
