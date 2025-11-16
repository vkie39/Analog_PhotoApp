import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReportPostScreen extends StatefulWidget {
  final String postId;

  const ReportPostScreen({required this.postId, super.key});

  @override
  State<ReportPostScreen> createState() => _ReportPostScreenState();
}

class _ReportPostScreenState extends State<ReportPostScreen> {
  String? selectedReason;
  final TextEditingController otherController = TextEditingController();

  final List<String> reasons = [
    '스팸홍보/도배글입니다.',
    '음란물입니다.',
    '불법정보를 포함하고 있습니다.',
    '청소년에게 유해한 내용입니다.',
    '욕설 및 혐오 표현입니다.',
    '개인정보 노출 게시물입니다.',
    '불쾌한 표현이 있습니다.',
    '기타 내용',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '게시글 신고',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(0),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: reasons.map((reason) {
                  return Column(
                    children: [
                      RadioListTile<String>(
                        title: Text(reason),
                        value: reason,
                        groupValue: selectedReason,
                        activeColor: const Color(0xFF84AC57),
                        onChanged: (value) {
                          setState(() {
                            selectedReason = value;
                          });
                        },
                      ),
                      if (reason == '기타 내용' && selectedReason == '기타 내용')
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0), // 좌우 여백 24
                          child: TextField(
                            controller: otherController,
                            style: const TextStyle(color: Colors.black),
                            decoration: const InputDecoration(
                              hintText: '신고 사유를 입력해주세요',
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.black),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.black),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                }).toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 64.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF84AC57),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    textStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () async {
                    if (selectedReason == null ||
                        (selectedReason == '기타 내용' &&
                            otherController.text.isEmpty)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('신고 사유를 선택해주세요')),
                      );
                      return;
                    }

                    final uid = FirebaseAuth.instance.currentUser?.uid;
                    if (uid == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('로그인이 필요합니다.')),
                      );
                      return;
                    }

                    final reasonText = selectedReason == '기타 내용'
                        ? otherController.text
                        : selectedReason!;

                    try {
                      // Firestore에 신고 기록 추가
                      await FirebaseFirestore.instance
                          .collection('reports')
                          .add({
                        'postId': widget.postId,
                        'reporterId': uid,
                        'reason': reasonText,
                        'timestamp': FieldValue.serverTimestamp(),
                      });

                      // 게시글 신고 카운트 증가
                      await FirebaseFirestore.instance
                          .collection('posts')
                          .doc(widget.postId)
                          .update({
                        'reportCount': FieldValue.increment(1),
                      });

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('신고가 접수되었습니다.')),
                        );
                        Navigator.of(context).pop();
                      }
                    } on FirebaseException catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  '신고 실패: ${e.message ?? '권한이 없습니다.'}')),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('신고 실패: ${e.toString()}')),
                        );
                      }
                    }
                  },
                  child: const Text(
                    '신고하기',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
