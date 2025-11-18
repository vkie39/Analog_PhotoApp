import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:flutter_application_sajindongnae/screen/post/report.dart';
import 'package:flutter_application_sajindongnae/screen/photo/sell_write.dart';
import 'package:flutter_application_sajindongnae/screen/chat/chat_image_viewer.dart';
import 'package:flutter_application_sajindongnae/screen/mypage/mypage.dart';

import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_sajindongnae/models/photo_trade_model.dart';
import 'package:flutter_application_sajindongnae/services/photo_trade_service.dart';
import 'package:flutter_application_sajindongnae/services/image_service.dart';
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
          content: Text('사진을 구매하시겠습니까?'),
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
              onPressed: () async{
                Navigator.pop(context);
                await _handlePurchase(photo);
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.lightGreen, // lightGreen[200]은 materialColor이므로 바로 사용 가능
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
      isScrollControlled: false, // 필요하면 true로 조절 가능
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min, // 내용만큼만 높이 차지
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 텍스트 영역
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min, // 내용만큼만 높이 차지
                  crossAxisAlignment: CrossAxisAlignment.start,  // 왼쪽 정렬
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
                    Container(width: double.infinity, height: 0.8, color: Colors.grey[300],),  // 아주 연한 회색
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
                              photo.imageUrl, // 또는 photo.imageUrl
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // 판매글 제목과 가격
                        Column(
                          mainAxisSize: MainAxisSize.min, // 내용만큼만 높이 차지
                          crossAxisAlignment: CrossAxisAlignment.start,  // 왼쪽 정렬
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
                                //color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(width: double.infinity, height: 0.8, color: Colors.grey[300],),  // 아주 연한 회색
                    const SizedBox(height: 10),

                    // 3. 거래 후 잔액 표시 영역
                    Text(
                          '거래 후 잔액 : ${newBuyerBalanceBill}원',
                          style: const TextStyle(
                            //color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 버튼 1: 마이페이지로 이동 (가로 꽉 채우기)
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    // 바텀시트 닫기
                    Navigator.pop(context);
                    // 마이페이지로 이동
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

              // 버튼 2: 확인 (가로 꽉 채우기)
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context); // 바텀시트만 닫기
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
  



  Future<void> _handlePurchase(PhotoTradeModel photo) async {
    final buyer = FirebaseAuth.instance.currentUser; // 현재 로그인 = 구매자
    if (buyer == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('로그인이 필요합니다.')));
      return;
    }

    // ── 가격 파싱 ──────────────────────────────────────────────
    final int price;
    if (photo.price is int) {
      price = photo.price as int;
    } else if (photo.price is num) {
      price = (photo.price as num).toInt();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('잘못된 가격 정보입니다.')));
      return;
    }
    
    // 거래 후 잔액을 보여주기 위한 변수
    int? newBuyerBalanceBill;

    if (photo.id == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('잘못된 판매글입니다.')));
      return;
    }

    // ── UID 설정 ───────────────────────────────────────────────
    final String buyerUid = buyer.uid; // 구매자 uid
    final String sellerUid = photo.uid; // 판매자 uid (판매글 작성자)

    // 본인 사진은 구매 못하게
    if (buyerUid == sellerUid) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('자신의 사진은 구매할 수 없습니다.')));
      return;
    }

    // ── Firestore 참조 ─────────────────────────────────────────
    final buyerRef = FirebaseFirestore.instance
        .collection('users')
        .doc(buyerUid);
    final sellerRef = FirebaseFirestore.instance
        .collection('users')
        .doc(sellerUid);
    final tradeRef = FirebaseFirestore.instance
        .collection('photo_trades')
        .doc(photo.id);

    

    try {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        // 1) 구매자 포인트 조회
        final buyerSnap = await tx.get(buyerRef);
        if (!buyerSnap.exists) {
          throw Exception('NO_BUYER_DOC');
        }

        final buyerData = buyerSnap.data() as Map<String, dynamic>;
        final buyerPoint =
            (buyerData['point'] as Map<String, dynamic>?) ??
            <String, dynamic>{};
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
          // 잔액 부족
          throw Exception('INSUFFICIENT_POINT');
        }

        // 2) 판매자 포인트 조회 (문서/point 없으면 0으로 시작)
        final sellerSnap = await tx.get(sellerRef);
        Map<String, dynamic> sellerData = {};
        Map<String, dynamic> sellerPoint = {};
        int sellerBalance = 0;

        if (sellerSnap.exists) {
          sellerData = sellerSnap.data() as Map<String, dynamic>;
          sellerPoint =
              (sellerData['point'] as Map<String, dynamic>?) ??
              <String, dynamic>{};
          final dynamic sellerRawBalance = sellerPoint['balance'];
          if (sellerRawBalance is int) {
            sellerBalance = sellerRawBalance;
          } else if (sellerRawBalance is num) {
            sellerBalance = sellerRawBalance.toInt();
          }
        } else {
          // 판매자 문서가 아예 없으면 uid 정도는 기본으로 넣어줌
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

        // 3-1) 구매자 측 포인트 차감 완료시 (잔액을 표시하기 위한 변수에 newBuyerBalance저장)
        newBuyerBalanceBill = newBuyerBalance;
        dev.log(' 3-1 완료 ');

        // 4) 판매자 포인트 적립 (set + merge 로 문서 없어도 생성)
        tx.set(sellerRef, {
          ...sellerData,
          'point': {
            ...sellerPoint,
            'balance': newSellerBalance,
            'updatedAt': FieldValue.serverTimestamp(),
          },
        }, SetOptions(merge: true));

        // 5) 거래 정보 업데이트 (구매 완료 처리)
        tx.update(tradeRef, {
           'buyerUid': FieldValue.arrayUnion([buyerUid]),
          'sellerUid': sellerUid,
          'status': 'completed', // 프로젝트에서 쓰는 상태값에 맞게 조정 가능
          'purchasedAt': FieldValue.serverTimestamp(),
        });

        // 6) 포인트 내역 거래 기록
        // 구매자 기록
        tx.set(buyerRef.collection('point_history').doc(), {
          'amount': -price,
          'description': '사진 구매',
          'timestamp': FieldValue.serverTimestamp(),
        });

        //판매자 기록
        tx.set(
          sellerRef.collection('point_history').doc(),
          {
            'amount': price,
            'description': '사진 판매',
            'timestamp': FieldValue.serverTimestamp(),
          });
      });

      // 트랜잭션 성공 -> 이거 대신 바텀 시트 넣었습니다.
    /*  ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('구매가 완료되었습니다.')),
      );*/ 
      dev.log('트랜잭션 성공');
      
      // 거래 성공시 결제 완료에 대한 BottomSheet(안내문구, 구매한 사진 정보, 마이페이지로 이동 버튼 등) 띄움
      // 거래 후 잔액이 계산되어 있다면 BottomSheet 띄우기
      if (newBuyerBalanceBill != null) {
        dev.log('바텀 시트 보여줄 수 있도록 준비 완료');
        _showPaymentBottomSheet(newBuyerBalanceBill!);
      }
      dev.log('바텀 시트 보여주기 완료');



    } catch (e) {

      final msg = e.toString();
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
    // 네트워크 이미지 기준 (photo.imageUrl 이 Firebase Storage URL)
    await _imageService.saveImageToGallery2(
      context: context,
      imagePath: photo.imageUrl,
      isAsset: false,
      photoOwnerNickname: photo.nickname, // 파일명에 작가 닉네임 + sajindongnae 붙음
    );
  }


  @override
  Widget build(BuildContext context) {
    final sellDocId = photo.id ?? '';

    final tradeStream =
        (sellDocId.isEmpty)
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

        // [추가] 좋아요 여부는 DB(likedBy) 기준으로만 판단
        final bool isLiked = (photo.likedBy ?? []).contains(currentUserUid);

        // 좋아요 개수
        final int likeCount = photo.likeCount ?? 0;
        
        // 사진을 구매한 사용자인지 확인
        // buyerUid 리스트에 현재 로그인 유저가 포함되어 있으면 다운로드 가능
        final bool canDownload = photo.buyerUid.contains(currentUserUid);

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
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SellWriteScreen(
                              initialPhoto: photo, // <─ 이게 핵심!
                            ),
                          ),
                        );
                      break;
                    case MoreAction.delete:
                      dev.log('삭제하기 선택됨');
                      // 삭제 확인 다이얼로그 표시
                      final shouldDelete = await showDialog<bool>(
                        context: context,
                        builder:
                            (_) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              backgroundColor: Colors.white,
                              title: const Text('정말로 이 판매글을 삭제하시겠습니까?'),
                              content: const Text('삭제 후에는 복구할 수 없습니다.'),
                              actions: [
                                TextButton(
                                  onPressed:
                                      () => Navigator.of(context).pop(false),
                                  child: const Text(
                                    '취소',
                                    style: TextStyle(color: Colors.black),
                                  ),
                                ),
                                TextButton(
                                  onPressed:
                                      () => Navigator.of(context).pop(true),
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
                    backgroundImage:
                        (photo.profileImageUrl.isNotEmpty &&
                                !photo.profileImageUrl.startsWith('file:///'))
                            ? NetworkImage(photo.profileImageUrl)
                            : null,
                    child:
                        (photo.profileImageUrl.isEmpty ||
                                photo.profileImageUrl.startsWith('file:///'))
                            ? const Icon(Icons.person, color: Colors.grey)
                            : null,
                  ),
                  title: Text(
                    photo.nickname,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
                        children:
                            tags.map((tag) {
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
          // 좋아요 + 가격 + 구매 버튼
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
                        color:
                            isLiked
                                ? const Color.fromARGB(
                                  255,
                                  102,
                                  204,
                                  105,
                                ) // 좋아요 색상 (HEAD 유지)
                                : const Color.fromARGB(
                                  255,
                                  161,
                                  161,
                                  161,
                                ), // 기본색
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
                      style: const TextStyle(fontSize: 16, color: Colors.black),
                    ),
                  ],
                ),

                // 중간 여백 = 오른쪽으로 밀어내기
                const Spacer(),

                // 오른쪽: 가격 + 구매 버튼 (일렬 가로 배치)
                Row(
                  mainAxisSize: MainAxisSize.min, // 필요한 만큼만 차지
                  children: [
                    // 가격
                    Text(
                      '${photo.price} 원',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // 구매 버튼
                    ElevatedButton(
                    onPressed: () async {
                      if (canDownload) {
                        // ✅ 이미 구매한 유저 → 다운로드
                        dev.log('다운로드 버튼 클릭됨');
                        await _downloadPhoto(photo);
                      } else {
                        // ✅ 아직 구매 안 한 유저 → 결제 플로우
                        dev.log('구매하기 버튼 클릭됨');
                        _showPaymentDialog();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canDownload
                          ? Colors.lightGreen            // 다운로드 시 더 진한 초록
                          : const Color(0xFFDDECC7),    // 구매 전 기본 색
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
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
