import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:flutter_application_sajindongnae/screen/post/report.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_sajindongnae/models/photo_trade_model.dart';
import 'package:flutter_application_sajindongnae/services/photo_trade_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// appBar 버튼에서 어떤 메뉴를 선택했는지 구분하기 위한 enum
enum MoreAction { report, edit, delete }

class SellDetailScreen extends StatefulWidget {
  final PhotoTradeModel photo;
  SellDetailScreen({super.key, required this.photo});

  // 실제 유저 정보로 변경
  final String currentUserUid = FirebaseAuth.instance.currentUser?.uid ?? 'uid';

  @override
  State<SellDetailScreen> createState() => _SellDetailScreenState();
}

class _SellDetailScreenState extends State<SellDetailScreen> {
  final PhotoTradeService _photoTradeService = PhotoTradeService();
  PhotoTradeModel get photo => widget.photo;
  String get currentUserUid => widget.currentUserUid;

  // Firebase Storage URL 네트워크 이미지 전용 빌더
  Widget _buildNetworkImage(String url) {
    // [추가] 잘못된 URL(file:///, 빈 문자열 등) 방어
    if (url.isEmpty || url.startsWith('file:///')) {
      return Container(
        height: 300,
        color: const Color(0xFFF2F2F2),
        alignment: Alignment.center,
        child: const Icon(Icons.broken_image, size: 48, color: Colors.grey),
      );
    }

    final fallback = Container(
      color: const Color(0xFFF2F2F2),
      alignment: Alignment.center,
      height: 300,
      child: const Icon(Icons.broken_image, size: 48, color: Colors.grey),
    );

    return Image.network(
      url,
      fit: BoxFit.cover,
      width: double.infinity,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        final total = progress.expectedTotalBytes;
        final loaded = progress.cumulativeBytesLoaded;
        return SizedBox(
          height: 300,
          child: Center(
            child: CircularProgressIndicator(
              value: total != null ? loaded / total : null,
            ),
          ),
        );
      },
      errorBuilder: (_, __, ___) => fallback,
    );
  }

  @override
  Widget build(BuildContext context) {
    final sellDocId = photo.id ?? '';

    final tradeStream = (sellDocId.isEmpty)
        ? Stream<PhotoTradeModel?>.value(widget.photo)
        : _photoTradeService.streamGetTradeById(sellDocId);

    return StreamBuilder<PhotoTradeModel?>(
      stream: tradeStream,
      initialData: widget.photo,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data;
        if (data == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('해당 판매글이 삭제되었거나 존재하지 않습니다.')),
            );
            Navigator.of(context).maybePop();
          });
          return const Scaffold(body: SizedBox.shrink());
        }

        final photo = data;

        final formattedDate =
            DateFormat('yyyy/MM/dd').format(photo.createdAt);

        final isOwner = photo.uid == currentUserUid;
        final tags = photo.tags;

        // [추가] 좋아요 여부는 DB(likedBy) 기준으로만 판단
        final bool isLiked =
            (photo.likedBy ?? []).contains(currentUserUid);

        // 좋아요 개수
        final int likeCount = photo.likeCount ?? 0;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0.5,

            // 더보기 버튼
            actions: [
              PopupMenuButton<MoreAction>(
                icon: const Icon(Icons.more_vert),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                color: Colors.white,
                elevation: 6,
                position: PopupMenuPosition.under,

                onSelected: (MoreAction action) async {
                  switch (action) {
                    case MoreAction.report:
                    dev.log('신고하기 선택됨');
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReportPostScreen(
                          postId: photo.id!,
                          postType: 'photo_trades',   // sales (sells 아님)
                          ),
                          ),
                          );
                          break;
                    case MoreAction.edit:
                      dev.log('수정하기 선택됨');
                      // 수정하기 로직 추가
                      break;
                    case MoreAction.delete:
                      dev.log('삭제하기 선택됨');
                      // 삭제 확인 다이얼로그 표시
                      final shouldDelete = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          backgroundColor: Colors.white,
                          title: const Text('정말로 이 판매글을 삭제하시겠습니까?'),
                          content: const Text('삭제 후에는 복구할 수 없습니다.'),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.of(context).pop(false),
                              child: const Text('취소',
                                  style: TextStyle(color: Colors.black)),
                            ),
                            TextButton(
                              onPressed: () =>
                                  Navigator.of(context).pop(true),
                              child: const Text('삭제',
                                  style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );

                      if (shouldDelete == true) {
                        dev.log('삭제 로직 실행됨');
                        // 실제 삭제 로직 추가
                        Navigator.of(context).pop(); // 삭제 후 이전 화면으로 돌아감
                      }
                      break;
                  }
                },

                itemBuilder: (context) {
                  if (isOwner) {
                    return const [
                      PopupMenuItem(
                        value: MoreAction.edit,
                        child: Text('수정하기'),
                      ),
                      PopupMenuDivider(height: 5),
                      PopupMenuItem(
                        value: MoreAction.delete,
                        child: Text('삭제하기'),
                      ),
                    ];
                  } else {
                    return const [
                      PopupMenuItem(
                        value: MoreAction.report,
                        child: Text('신고하기'),
                      ),
                    ];
                  }
                },
              ),
            ],
          ),

          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 사진
                SizedBox(
                  width: double.infinity,
                  child: _buildNetworkImage(photo.imageUrl),
                ),

                const SizedBox(height: 10),

                // 작가 정보
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: (photo.profileImageUrl.isNotEmpty &&
                            !photo.profileImageUrl.startsWith('file:///'))
                        ? NetworkImage(photo.profileImageUrl)
                        : null,
                    child: (photo.profileImageUrl.isEmpty ||
                            photo.profileImageUrl.startsWith('file:///'))
                        ? const Icon(Icons.person, color: Colors.grey)
                        : null,
                  ),
                  title: Text(
                    photo.nickname,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),

                const Divider(),

                // 제목
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    photo.title,
                    style: const TextStyle(
                        fontSize: 25, fontWeight: FontWeight.bold),
                  ),
                ),

                // 날짜
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Text(
                    formattedDate,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),

                // 태그들
                if (tags.isNotEmpty)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: tags.map((tag) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ActionChip(
                              label: Text(tag),
                              backgroundColor: Colors.white,
                              labelStyle:
                                  const TextStyle(color: Colors.black87),
                              side: const BorderSide(
                                  color: Color(0xFFE0E0E0), width: 1),
                              onPressed: () {},
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                // 장소
                if (photo.location.isNotEmpty)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          photo.location,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),

                // 내용
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    photo.description,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          // 좋아요 + 가격 + 구매 버튼
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 좋아요 + 가격 영역
                Row(
                children: [
          // 좋아요 버튼
          IconButton(
            icon: Icon(
              isLiked ? Icons.favorite : Icons.favorite_border,size: 30,
              color: isLiked
                  ? const Color.fromARGB(255, 102, 204, 105)   // 좋아요 색상 (HEAD 유지)
                  : const Color.fromARGB(255, 161, 161, 161),  // 기본색
            ),
            onPressed: () async {
              if (photo.id == null) return;

              try {
                await _photoTradeService.toggleLike(
                    photo.id!, currentUserUid);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('좋아요 처리 중 오류가 발생했습니다.')),
                );
              }
            },
          ),

          const SizedBox(width: 6),

          // 좋아요 개수
          Text(
            '$likeCount',
            style: const TextStyle(fontSize: 16, color: Colors.black),
          ),

          const SizedBox(width: 14),

          // 가격
          Text(
            '${photo.price} 원',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),

      // 구매 버튼
      ElevatedButton(
        onPressed: () {
          dev.log('구매하기 버튼 클릭됨');
          // TODO : 구매 기능
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFDDECC7), // HEAD 색상 유지
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: const Text('구매하기'),
      ),
    ],
  ),
),
        );
      },
    );
  }
}