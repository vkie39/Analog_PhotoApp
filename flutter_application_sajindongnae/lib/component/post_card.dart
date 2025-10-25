import 'package:flutter/material.dart';
import '../models/post_model.dart';
import 'package:flutter_application_sajindongnae/screen/post/post_detail.dart';

class PostCard extends StatelessWidget {
  final PostModel post;
  final VoidCallback? onTap;

  const PostCard({super.key, required this.post, this.onTap});

  
  @override
  Widget build(BuildContext context) {
    print(MediaQuery.of(context).size.width);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth <= 360;

    // 픽셀 기반 세부 조정
    final double imageSize = isSmallScreen ? 60 : 80;
    final double profileRadius = isSmallScreen ? 14 : 18;
    final double horizontalPadding = isSmallScreen ? 12 : 20;
    final double verticalPadding = isSmallScreen ? 6 : 10;
    final double spacingBetweenProfileAndText = 10;
    final double spacingBetweenTextAndImage = 12;
    final double contentSpacingSmall = 4;
    final double contentSpacingMedium = 6;
    final double dividerSpacing = 10;

    final double titleFontSize = isSmallScreen ? 14 : 16;
    final double contentFontSize = isSmallScreen ? 12 : 14;
    final double metaFontSize = isSmallScreen ? 10 : 12;
    final double imageBorderRadius = 8;
    final double iconSize = 30;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        child: Column(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final double availableWidth = constraints.maxWidth;
                final double thumbnailWidth =
                    (post.imageUrl != null && post.imageUrl!.isNotEmpty)
                        ? imageSize + spacingBetweenTextAndImage
                        : 0;
                final double textMaxWidth = availableWidth - thumbnailWidth - profileRadius * 2 - spacingBetweenProfileAndText - 10;

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 프로필
                    CircleAvatar(
                      backgroundImage: NetworkImage(post.profileImageUrl),
                      radius: profileRadius,
                    ),

                    SizedBox(width: spacingBetweenProfileAndText),

                    // 텍스트 영역
                    SizedBox(
                      width: textMaxWidth,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: titleFontSize,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: contentSpacingSmall),
                          Text(
                            post.content ?? '',
                            style: TextStyle(
                              fontSize: contentFontSize,
                              color: Colors.black87,
                            ),
                            maxLines: post.imageUrl != null ? 1 : 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: contentSpacingMedium),
                          Row(
                            children: [
                              Flexible(
                                child: Text('좋아요 ${post.likeCount} | ',
                                    style: TextStyle(fontSize: metaFontSize, color: Colors.grey),
                                    overflow: TextOverflow.ellipsis),
                              ),
                              Flexible(
                                child: Text('댓글 ${post.commentCount} | ',
                                    style: TextStyle(fontSize: metaFontSize, color: Colors.grey),
                                    overflow: TextOverflow.ellipsis),
                              ),
                              Flexible(
                                child: Text(_getTimeAgo(post.timestamp),
                                    style: TextStyle(fontSize: metaFontSize, color: Colors.grey),
                                    overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // 썸네일 이미지
                    if (post.imageUrl != null && post.imageUrl!.isNotEmpty) ...[
                      SizedBox(width: spacingBetweenTextAndImage),
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
                );
              },
            ),

            SizedBox(height: dividerSpacing),
            const Divider(thickness: 0.4),
          ],
        ),
      ),
    );
  }

  static String _getTimeAgo(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return '방금 전';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    return '${diff.inDays}일 전';
  }
}
