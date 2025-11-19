import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InquiryListScreen extends StatefulWidget {
  const InquiryListScreen({super.key});

  @override
  State<InquiryListScreen> createState() => _InquiryListScreenState();
}

class _InquiryListScreenState extends State<InquiryListScreen> {
  bool showOnlyMine = false;

  Stream<QuerySnapshot<Map<String, dynamic>>> _inquiryListStream() {
    return FirebaseFirestore.instance
        .collection('inquiries')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _inquiryListStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text('문의 목록을 불러오는 중 오류가 발생했습니다.'),
            );
          }

          // Firestore에서 answer가 있는 문서만 필터링
          final inquiries = snapshot.data?.docs.where((doc) {
                final answer = doc.data()['answer'];
                return answer != null && answer.toString().trim().isNotEmpty;
              }).toList() ??
              [];

          if (inquiries.isEmpty) {
            return const Center(
              child: Text('답변 완료된 문의가 없습니다.'),
            );
          }

          // "나의 문의만 보기" 필터
          final displayedInquiries = showOnlyMine
              ? inquiries
                  .where((doc) => doc.data()['uid'] == '현재사용자UID') // 필요시 현재 로그인 UID
                  .toList()
              : inquiries;

          return Column(
            children: [
              // 전체보기 / 나의 문의 버튼
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  itemCount: displayedInquiries.length,
                  itemBuilder: (context, index) {
                    final doc = displayedInquiries[index];
                    final data = doc.data();
                    final category = data['category'] ?? '카테고리 없음';
                    final title = data['title'] ?? '제목 없음';
                    final content = data['content'] ?? '';
                    final answer = data['answer'] ?? '';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: const Color(0xFFDADADA),
                          width: 1.3,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 카테고리 + 제목
                          Text(
                            '[$category] $title',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF333333),
                            ),
                          ),
                          const SizedBox(height: 4),
                          // 문의 내용
                          Text(
                            content,
                            style: const TextStyle(
                              color: Color(0xFF555555),
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // 관리자 답변
                          if (answer.isNotEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(8),
                              margin: const EdgeInsets.only(top: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F8E9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '답변: $answer',
                                style: const TextStyle(
                                  color: Colors.black,
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
          );
        },
      ),
    );
  }
}
