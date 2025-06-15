// 게시글 리스트를 카드 형태로 디자인. 클릭하면 post_detail로 페이지 이동 및 postId 전달달 (실시간으로 firestore에서 정보 받아오는 코드는 list.dart에서 처리 예정)
import 'package:flutter/material.dart';
import '../models/post_model.dart';
import 'package:flutter_application_sajindongnae/screen/post/post_detail.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PostCard extends StatelessWidget {
  final PostModel post;

  const PostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // 비율 기반 설정값
    final imageSize = screenWidth * 0.18;
    final profileRadius = screenWidth * 0.04;
    final horizontalPadding = screenWidth * 0.06; // ≈ 25
    final verticalPadding = screenWidth * 0.013;  // ≈ 5
    final spacingBetweenProfileAndText = screenWidth * 0.04; // ≈ 15
    final topPaddingForAvatar = screenWidth * 0.011; // ≈ 4
    final contentSpacingSmall = screenWidth * 0.011; // ≈ 4
    final contentSpacingMedium = screenWidth * 0.015; // ≈ 6
    final spacingBetweenMeta = screenWidth * 0.02; // ≈ 8
    final dividerSpacing = screenWidth * 0.015; // ≈ 6

    final titleFontSize = screenWidth * 0.038;  // ≈ 14
    final contentFontSize = screenWidth * 0.033; // ≈ 12
    final metaFontSize = screenWidth * 0.027; // ≈ 10
    final imageBorderRadius = screenWidth * 0.015; // ≈ 6
    final iconSize = screenWidth * 0.06; // ≈ 24

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
                Expanded(
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
                          Text('좋아요 ${post.likeCount}   |', style: TextStyle(fontSize: metaFontSize, color: Colors.grey)),
                          SizedBox(width: spacingBetweenMeta),
                          Text('댓글 ${post.commentCount}   |', style: TextStyle(fontSize: metaFontSize, color: Colors.grey)),
                          SizedBox(width: spacingBetweenMeta),
                          Text(_getTimeAgo(post.timestamp), style: TextStyle(fontSize: metaFontSize, color: Colors.grey)),
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

/*
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final imageSize = screenWidth * 0.18;
    final profileRadius = screenWidth * 0.04;

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
                    radius: profileRadius,
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
                // imageUrl이 null이 아니고 빈 문자열도 아닐 경우에만 이미지 렌더링
                if (post.imageUrl != null && post.imageUrl!.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      width: imageSize,
                      height: imageSize,
                      color: Colors.white,
                      child: Image.network(
                        post.imageUrl!,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,

                        // 이미지 로딩 실패 시 기본 아이콘으로 대체
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.image_not_supported,
                          size: 24,
                          color: Colors.grey,
                        ),
                      ),
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
*/
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