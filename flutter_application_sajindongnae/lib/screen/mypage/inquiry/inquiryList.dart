import 'package:flutter/material.dart';

class InquiryListScreen extends StatefulWidget {
  const InquiryListScreen({super.key});

  @override
  State<InquiryListScreen> createState() => _InquiryListScreenState();
}

class _InquiryListScreenState extends State<InquiryListScreen> {
  bool showOnlyMine = false;

  final List<Map<String, String?>> _allInquiries = [
    {
      'user': '홍길동',
      'category': '회원문의',
      'title': '탈퇴 버튼 어디 있어요?',
      'content': '탈퇴하고 싶은데 못 찾겠어요 ㅜㅜ;;',
      'reply': '설정 > 개인정보관리 하단에 위치합니다. 감사합니다. ',
    },
    {
      'user': '김철수',
      'category': '결제문의',
      'title': '포인트 거래에 문제가 생겼어요!',
      'content': '상대방에게 돈이 안 들어왔는데 거래가 완료됐어요.. 제 돈 돌려주세요!',
      'reply': '확인했습니다. 포인트 내역 확인 부탁드립니다.',
    },
    {
      'user': '나',
      'category': '기타문의',
      'title': '홈 화면에 보이는 사진들',
      'content': '올라오는 기준이 뭔가요? 왜 제 사진은 안 올라가죠',
      'reply': '좋아요 누적 수에 따라 업데이트됩니다. 감사합니다.',
    },
    {
      'user': '이원희',
      'category': '서비스문의',
      'title': '제가 좋아요 누른 글이 안 보여요 ㅜㅜ',
      'content': '어제까진 분명 보였는데 갑자기 안 보여요..',
      'reply': '해당 서비스 복구됐습니다. 확인 부탁드립니다. 감사합니다.',
    },
    {
      'user': '모카',
      'category': '서비스문의',
      'title': '더 다양한 게시판을 원해요!',
      'content': '게시판 더 만들어주시면 안대여? ㅇㅅㅇ',
      'reply': '다양한 서비스 제공을 위해 업데이트 진행 예정입니다. 감사합니다.',
    },
    {
      'user': '로하',
      'category': '기타문의',
      'title': '게시글 신고했는데 왜 안 받아주세요!',
      'content': '김철수라는사람이자꾸못된게시글올리는데왜신고접수가안되나요',
      'reply': '확인 중에 있습니다. 감사합니다.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    List<Map<String, String?>> displayedInquiries =
        showOnlyMine
            ? _allInquiries.where((inq) => inq['user'] == '나').toList()
            : _allInquiries;

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 4, right: 16),
              child: TextButton(
                onPressed: () {
                  setState(() {
                    showOnlyMine = !showOnlyMine;
                  });
                },
                child: Text(
                  showOnlyMine ? '전체보기' : '나의 문의',
                  style: const TextStyle(
                    color: Color(0xFF84AC57),
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only (right: 16, left:16, ),
              itemCount: displayedInquiries.length,
              itemBuilder: (context, index) {
                final inquiry = displayedInquiries[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 255, 255, 255), // 질문 배경색 (연회색)
                    border: Border.all(
                      color: const Color(0xFFDADADA), // 테두리 색
                      width: 1.3,
                    ),
                    borderRadius: BorderRadius.circular(10), // 둥근 모서리
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '[${inquiry['category']}] ${inquiry['title']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        inquiry['content'] ?? '',
                        style: const TextStyle(
                          color: Color(0xFF555555),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (inquiry['reply'] != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          margin: const EdgeInsets.only(top: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F8E9), // 답변 배경 (연초록)
                            //border: Border.all(color: const Color(0xFFB2DFDB)),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '답변: ${inquiry['reply']}',
                            style: const TextStyle(
                              color: Color.fromARGB(255, 0, 0, 0),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
