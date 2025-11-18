// lib/widgets/purchase_bottom_sheet.dart
import 'package:flutter/material.dart';

/// 결제 완료 후 띄우는 공용 바텀 시트
/// - postId: 어떤 게시글에 대한 결제인지 (필요하면 추후 사용 가능)
/// - imageUrl, title, price: 바텀시트에 보여줄 정보
/// - remainingBalance: 거래 후 잔액
/// - onTapMyPage: '마이페이지로 이동' 눌렀을 때 실행할 콜백 (화면마다 다르게 처리 가능)
Future<void> tradeBottomSheetService({
  required BuildContext context,
  required String postId,
  required String imageUrl,
  required String title,
  required int price,
  required int remainingBalance,
  VoidCallback? onTapMyPage,
}) {
  return showModalBottomSheet(
    context: context,
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
                    color: Color(0xFFe0e0e0),
                  ),
                  const SizedBox(height: 10),

                  // 2. 구매한 사진 정보 영역
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 구매한 사진 썸네일
                      ClipRRect(
                        borderRadius: BorderRadius.circular(0),
                        child: SizedBox(
                          width: 60,
                          height: 60,
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // 제목 + 가격
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$price원',
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
                    color: Color(0xFFe0e0e0),
                  ),
                  const SizedBox(height: 10),

                  // 3. 거래 후 잔액 표시 영역
                  Text(
                    '거래 후 잔액 : ${remainingBalance}원',
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
                  Navigator.pop(context); // 바텀시트 닫기
                  if (onTapMyPage != null) {
                    onTapMyPage();
                  }
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
