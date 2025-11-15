import 'package:flutter/material.dart';

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  String _selectedCategory = '전체';

  final List<String> _categories = [
    '전체',
    '회원',
    '결제',
    '서비스',
    '거래',
    '기타',
  ];

  final List<Map<String, String>> _faqList = [
    {'category': '회원', 'question': '비밀번호를 잊어버렸어요.', 'answer': '로그인 화면에서 "비밀번호 찾기"를 눌러 재설정할 수 있습니다.'},
    {'category': '회원', 'question': '회원 탈퇴는 어떻게 하나요?', 'answer': '설정 > 계정관리 > 회원탈퇴 메뉴에서 가능합니다.'},
    {'category': '결제', 'question': '결제가 실패했어요.', 'answer': '카드 잔액을 확인 후 다시 시도해주세요.'},
    {'category': '결제', 'question': '환불은 어떻게 진행되나요?', 'answer': '결제 후 7일 이내에 고객센터로 문의해주세요.'},
    {'category': '서비스', 'question': '사진 업로드가 안돼요.', 'answer': '앱을 최신 버전으로 업데이트 후 다시 시도해주세요.'},
    {'category': '거래', 'question': '판매자와 연락이 안돼요.', 'answer': '거래 중 문제가 생기면 고객센터로 신고해주세요.'},
    {'category': '기타', 'question': '앱이 자꾸 종료돼요.', 'answer': '캐시를 지우거나 앱을 재설치해보세요.'},
  ];

  @override
  Widget build(BuildContext context) {
    final filteredFAQs = _selectedCategory == '전체'
        ? _faqList
        : _faqList.where((faq) => faq['category'] == _selectedCategory).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          '자주 묻는 질문',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          // 카테고리 버튼 2x3 그리드
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: GridView.count(
              shrinkWrap: true,
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 3.0,
              physics: const NeverScrollableScrollPhysics(),
              children: _categories.map((cat) {
                final bool isSelected = _selectedCategory == cat;
                return ElevatedButton(
                  onPressed: () => setState(() => _selectedCategory = cat),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSelected ? const Color(0xFF84AC57) : Colors.white,
                    foregroundColor: isSelected ? Colors.white : const Color.fromARGB(255, 122, 122, 122),
                    side: BorderSide(
                      color: isSelected ? const Color(0xFF84AC57) : Colors.grey.shade400,
                      width: 1.2,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: Text(
                    cat, 
                    style: 
                    TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 15
                    )
                  ),
                );
              }).toList(),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: const Divider(
              thickness: 0.5,
              height: 1,
              color: Colors.grey,
            ),
          ),

          // FAQ 리스트
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              itemCount: filteredFAQs.length,
              itemBuilder: (context, index) {
                final faq = filteredFAQs[index];
                bool isExpanded = false;

                return StatefulBuilder(
                  builder: (context, setInnerState) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          dividerColor: Colors.transparent, // 내부 Divider 제거
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                        ),
                        child: ExpansionTile(
                          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          backgroundColor: Colors.white,
                          collapsedBackgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          onExpansionChanged: (expanded) => setInnerState(() => isExpanded = expanded),
                          iconColor: Colors.black,
                          collapsedIconColor: Colors.black,
                          title: Text(
                            '[${faq['category']}] ${faq['question']}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: Colors.black,
                            ),
                          ),
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8F8F8),
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(8),
                                  bottomRight: Radius.circular(8),
                                ),
                                border: Border(
                                  top: BorderSide(color: Colors.grey.shade300),
                                ),
                              ),
                              child: Text(
                                faq['answer']!,
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
