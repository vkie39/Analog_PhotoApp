import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:flutter_application_sajindongnae/screen/post/report.dart';
import 'package:flutter_application_sajindongnae/screen/photo/sell_write.dart';
import 'package:flutter_application_sajindongnae/screen/chat/chat_image_viewer.dart';
import 'package:flutter_application_sajindongnae/screen/mypage/mypage.dart';
import 'package:flutter_application_sajindongnae/screen/photo/watermarked_image.dart';
import 'package:flutter_application_sajindongnae/screen/photo/watermarked_single.dart';

import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_sajindongnae/models/photo_trade_model.dart';
import 'package:flutter_application_sajindongnae/services/photo_trade_service.dart';
import 'package:flutter_application_sajindongnae/services/image_service.dart';
import 'package:flutter_application_sajindongnae/services/user_service.dart';
import 'package:flutter_application_sajindongnae/models/user_model.dart';

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
  final ImageService _imageService = ImageService();
  PhotoTradeModel get photo => widget.photo;
  String get currentUserUid => widget.currentUserUid;

  late Future<UserModel?> _authorFuture;

  // Firebase Storage URL 네트워크 이미지 전용 빌더
  Widget _buildNetworkImage(String url) {
    // 잘못된 URL(file:///, 빈 문자열 등) 방어
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

  // 사진 위에 중앙 워터마크 한 번만 찍는 빌더
  Widget _waterMarkedImage(String url) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 화면 너비 기준으로 글자 크기 계산
        final double baseWidth = constraints.maxWidth;
        final double fontSize = (baseWidth * 0.6).clamp(16.0, 80.0);

        return Stack(
          alignment: Alignment.center,
          children: [
            // 원본 비율 유지하면서 가로 꽉 채우기
            Image.network(
              url,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            // 중앙 워터마크 텍스트
            Text(
              '${photo.nickname} \n사진동네',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: Colors.white.withOpacity(0.25),
                shadows: [
                  Shadow(
                    blurRadius: 4,
                    offset: const Offset(1, 1),
                    color: Colors.black.withOpacity(0.3),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    // photo.uid = 이 판매글을 올린 유저의 uid
    _authorFuture = UserService.getUserByUid(photo.uid);
  }

  // =========================================================================== 
  // 결제 확인 다이얼로그 (구매하기 버튼 누르면 뜸 -> 취소, 확인 버튼 있음)
  // ===========================================================================

  void _showPaymentDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.white,
          title: const Text(
            '구매 확인',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text('사진을 구매하시겠습니까?'),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // 취소 버튼
              style: TextButton.styleFrom(
                backgroundColor: Colors.grey[300], // 밝은 회색
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              child: const Text('취소', style: TextStyle(color: Colors.black)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _handlePurchase(photo);
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.lightGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              child: const Text('확인', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // =========================================================================== 
  // 결제 완료 후 띄울 바텀 시트 (결제 성공시 -> 확인/마이페이지로 이동 버튼 있음)
  // ===========================================================================

  void _showPaymentBottomSheet(int newBuyerBalanceBill) {
    showModalBottomSheet(
      context: context,
      // 위쪽만 둥글게
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      isScrollControlled: false,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 텍스트 영역
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. 안내 문구 영역
                    const Text(
                      '사진 구매 완료',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '구매한 사진은 마이페이지에서 확인할 수 있습니다.',
                      textAlign: TextAlign.start,
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      height: 0.8,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 10),

                    // 2. 구매한 사진 정보 영역
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 구매한 사진 (정사각형 미니 썸네일)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(0),
                          child: SizedBox(
                            width: 60,
                            height: 60,
                            child: Image.network(
                              photo.imageUrl,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // 판매글 제목과 가격
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              photo.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${photo.price}원',
                              style: const TextStyle(
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      height: 0.8,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 10),

                    // 3. 거래 후 잔액 표시 영역
                    Text(
                      '거래 후 잔액 : ${newBuyerBalanceBill}원',
                      style: const TextStyle(
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 버튼 1: 마이페이지로 이동
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MyPageScreen(),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    '마이페이지로 이동',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // 버튼 2: 확인
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.lightGreen,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    '확인',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // =================================================================== 
  // 사진 구매 트랜잭션
  // ===================================================================

  Future<void> _handlePurchase(PhotoTradeModel photo) async {
    final buyer = FirebaseAuth.instance.currentUser; // 현재 로그인 = 구매자
    if (buyer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인이 필요합니다.')),
      );
      return;
    }

    // 가격 파싱
    final int price;
    if (photo.price is int) {
      price = photo.price as int;
    } else if (photo.price is num) {
      price = (photo.price as num).toInt();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('잘못된 가격 정보입니다.')),
      );
      return;
    }

    int? newBuyerBalanceBill;

    if (photo.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('잘못된 판매글입니다.')),
      );
      return;
    }

    final String buyerUid = buyer.uid; // 구매자 uid
    final String sellerUid = photo.uid; // 판매자 uid

    if (buyerUid == sellerUid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('자신의 사진은 구매할 수 없습니다.')),
      );
      return;
    }

    final buyerRef =
        FirebaseFirestore.instance.collection('users').doc(buyerUid);
    final sellerRef =
        FirebaseFirestore.instance.collection('users').doc(sellerUid);
    final tradeRef =
        FirebaseFirestore.instance.collection('photo_trades').doc(photo.id);

    try {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        // 0) 이미 구매한 사용자면 막기
        final tradeSnap = await tx.get(tradeRef);
        final tradeData = tradeSnap.data() as Map<String, dynamic>? ?? {};
        final List<dynamic> buyerList = tradeData['buyerUid'] ?? [];

        if (buyerList.contains(buyerUid)) {
          throw Exception('ALREADY_PURCHASED');
        }

        // 1) 구매자 포인트 조회
        final buyerSnap = await tx.get(buyerRef);
        if (!buyerSnap.exists) {
          throw Exception('NO_BUYER_DOC');
        }

        final buyerData = buyerSnap.data() as Map<String, dynamic>;
        final buyerPoint =
            (buyerData['point'] as Map<String, dynamic>?) ?? <String, dynamic>{};
        final dynamic buyerRawBalance = buyerPoint['balance'];

        int buyerBalance;
        if (buyerRawBalance is int) {
          buyerBalance = buyerRawBalance;
        } else if (buyerRawBalance is num) {
          buyerBalance = buyerRawBalance.toInt();
        } else {
          buyerBalance = 0;
        }

        if (buyerBalance < price) {
          throw Exception('INSUFFICIENT_POINT');
        }

        // 2) 판매자 포인트 조회
        final sellerSnap = await tx.get(sellerRef);
        Map<String, dynamic> sellerData = {};
        Map<String, dynamic> sellerPoint = {};
        int sellerBalance = 0;

        if (sellerSnap.exists) {
          sellerData = sellerSnap.data() as Map<String, dynamic>;
          sellerPoint =
              (sellerData['point'] as Map<String, dynamic>?) ?? <String, dynamic>{};
          final dynamic sellerRawBalance = sellerPoint['balance'];
          if (sellerRawBalance is int) {
            sellerBalance = sellerRawBalance;
          } else if (sellerRawBalance is num) {
            sellerBalance = sellerRawBalance.toInt();
          }
        } else {
          sellerData = {'uid': sellerUid};
        }

        final int newBuyerBalance = buyerBalance - price;
        final int newSellerBalance = sellerBalance + price;

        // 3) 구매자 포인트 차감
        tx.update(buyerRef, {
          'point': {
            ...buyerPoint,
            'balance': newBuyerBalance,
            'updatedAt': FieldValue.serverTimestamp(),
          },
        });

        newBuyerBalanceBill = newBuyerBalance;
        dev.log(' 3-1 완료 ');

        // 4) 판매자 포인트 적립
        tx.set(
          sellerRef,
          {
            ...sellerData,
            'point': {
              ...sellerPoint,
              'balance': newSellerBalance,
              'updatedAt': FieldValue.serverTimestamp(),
            },
          },
          SetOptions(merge: true),
        );

        // 5) 거래 정보 업데이트
        tx.update(tradeRef, {
          'buyerUid': FieldValue.arrayUnion([buyerUid]),
          'sellerUid': sellerUid,
          'status': 'completed',
          'purchasedAt': FieldValue.serverTimestamp(),
        });

        // 6) 포인트 내역 거래 기록
        tx.set(
          buyerRef.collection('point_history').doc(),
          {
            'amount': -price,
            'description': '사진 구매',
            'timestamp': FieldValue.serverTimestamp(),
          },
        );

        tx.set(
          sellerRef.collection('point_history').doc(),
          {
            'amount': price,
            'description': '사진 판매',
            'timestamp': FieldValue.serverTimestamp(),
          },
        );
      });

      dev.log('트랜잭션 성공');

      if (newBuyerBalanceBill != null) {
        dev.log('바텀 시트 보여줄 수 있도록 준비 완료');
        _showPaymentBottomSheet(newBuyerBalanceBill!);
      }
      dev.log('바텀 시트 보여주기 완료');
    } catch (e) {
      final msg = e.toString();

      if (msg.contains('ALREADY_PURCHASED')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이미 구매한 사진입니다.')),
        );
        return;
      }
      if (msg.contains('INSUFFICIENT_POINT')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('포인트가 부족합니다. 충전 후 다시 시도해주세요.')),
        );
      } else if (msg.contains('NO_BUYER_DOC')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('구매자 정보가 존재하지 않습니다.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('구매 처리 중 오류가 발생했습니다.\n$e')),
        );
      }
    }
  }

  // =================================================================== 
  // 사진 다운로드 (결제 완료 후 활성화)
  // ===================================================================

  Future<void> _downloadPhoto(PhotoTradeModel photo) async {
    await _imageService.saveImageToGallery2(
      context: context,
      imagePath: photo.imageUrl,
      isAsset: false,
      photoOwnerNickname: photo.nickname,
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

        final formattedDate = DateFormat('yyyy/MM/dd').format(photo.createdAt);
        final isOwner = photo.uid == currentUserUid;
        final tags = photo.tags;

        final bool isLiked = (photo.likedBy ?? []).contains(currentUserUid);
        final int likeCount = photo.likeCount ?? 0;

        final bool canDownload = photo.buyerUid.contains(currentUserUid);

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            surfaceTintColor: Colors.transparent,
            elevation: 0.5,
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
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ReportPostScreen(
                            postId: photo.id!,
                            postType: 'photo_trades',
                            reasons: [
                              '무단 사진 도용',
                              '저작권 침해',
                              '불법 사진',
                              '기타',
                            ],
                          ),
                        ),
                      );
                      break;
                    case MoreAction.edit:
                      dev.log('수정하기 선택됨');
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SellWriteScreen(
                            initialPhoto: photo,
                          ),
                        ),
                      );
                      break;
                    case MoreAction.delete:
                      dev.log('삭제하기 선택됨');
                      final shouldDelete = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          backgroundColor: Colors.white,
                          title:
                              const Text('정말로 이 판매글을 삭제하시겠습니까?'),
                          content: const Text('삭제 후에는 복구할 수 없습니다.'),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.of(context).pop(false),
                              child: const Text(
                                '취소',
                                style: TextStyle(color: Colors.black),
                              ),
                            ),
                            TextButton(
                              onPressed: () =>
                                  Navigator.of(context).pop(true),
                              child: const Text(
                                '삭제',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );

                      if (shouldDelete == true) {
                        dev.log('삭제 로직 실행됨');
                        Navigator.of(context).pop();
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
                  child: _waterMarkedImage(photo.imageUrl),
                ),
                const SizedBox(height: 10),

                // 작가 정보 (users 컬렉션에서 프로필/닉네임 조회)
                FutureBuilder<UserModel?>(
                  future: _authorFuture,
                  builder: (context, snapshot) {
                    // photo에 들어있는 닉네임은 기본값으로 사용
                    String nickname = photo.nickname;
                    String? profileUrl;

                    if (snapshot.hasData) {
                      final user = snapshot.data!;
                      // user에 닉네임이 있으면 그걸 우선
                      nickname = user.nickname.isNotEmpty
                          ? user.nickname
                          : nickname;
                      profileUrl = user.profileImageUrl;
                    }

                    final bool hasValidProfile = profileUrl != null &&
                        profileUrl.isNotEmpty &&
                        profileUrl.startsWith('http');

                    return ListTile(
                      leading: CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage:
                            hasValidProfile ? NetworkImage(profileUrl!) : null,
                        child: hasValidProfile
                            ? null
                            : const Icon(
                                Icons.person,
                                color: Colors.grey,
                              ),
                      ),
                      title: Text(
                        nickname,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),

                const Divider(),

                // 제목
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    photo.title,
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // 날짜
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: Text(
                    formattedDate,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),

                // 태그들
                if (tags.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: tags.map((tag) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ActionChip(
                              label: Text(tag),
                              backgroundColor: Colors.white,
                              labelStyle: const TextStyle(
                                color: Colors.black87,
                              ),
                              side: const BorderSide(
                                color: Color(0xFFE0E0E0),
                                width: 1,
                              ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.grey,
                        ),
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

          // 좋아요 + 가격 + 구매/다운로드 버튼
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 18),
            child: Row(
              children: [
                // 왼쪽: 좋아요
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        size: 30,
                        color: isLiked
                            ? const Color.fromARGB(255, 102, 204, 105)
                            : const Color.fromARGB(255, 161, 161, 161),
                      ),
                      onPressed: () async {
                        if (photo.id == null) return;

                        try {
                          await _photoTradeService.toggleLike(
                            photo.id!,
                            currentUserUid,
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('좋아요 처리 중 오류가 발생했습니다.'),
                            ),
                          );
                        }
                      },
                    ),
                    Text(
                      '$likeCount',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                // 오른쪽: 가격 + 구매/다운로드 버튼
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${photo.price} 원',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () async {
                        if (canDownload) {
                          dev.log('다운로드 버튼 클릭됨');
                          await _downloadPhoto(photo);
                        } else {
                          dev.log('구매하기 버튼 클릭됨');
                          _showPaymentDialog();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: canDownload
                            ? Colors.lightGreen // 이미 구매 → 다운로드
                            : const Color(0xFFDDECC7), // 구매 전
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 12,
                        ),
                      ),
                      child: Text(
                        canDownload ? '다운로드' : '구매하기',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
