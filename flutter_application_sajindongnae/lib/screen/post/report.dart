import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_sajindongnae/services/report_service.dart';

class ReportPostScreen extends StatefulWidget {
  final String postId;
  final String postType; // posts / photo_trades / requests 등
  final List<String> reasons; // 신고 사유 리스트

  const ReportPostScreen({
    required this.postId,
    required this.postType,
    required this.reasons,
    super.key,
  });

  @override
  State<ReportPostScreen> createState() => _ReportPostScreenState();
}

class _ReportPostScreenState extends State<ReportPostScreen> {
  String? selectedReason;
  final TextEditingController otherController = TextEditingController();

  @override
  void dispose() {
    otherController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '신고하기',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children:
                  widget.reasons.map((reason) {
                    return Column(
                      children: [
                        RadioListTile<String>(
                          title: Text(reason),
                          value: reason,
                          groupValue: selectedReason,
                          activeColor: const Color(0xFF84AC57),
                          onChanged:
                              (value) => setState(() {
                                selectedReason = value;
                              }),
                        ),
                        if (reason.toLowerCase().contains('기타') &&
                            selectedReason == reason)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF84AC57),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                onPressed: () async {
                  if (selectedReason == null ||
                      (selectedReason!.toLowerCase().contains('기타') &&
                          otherController.text.isEmpty)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('신고 사유를 선택해주세요')),
                    );
                    return;
                  }

                  final uid = FirebaseAuth.instance.currentUser?.uid;
                  if (uid == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('로그인이 필요합니다.')),
                    );
                    return;
                  }

                  final reasonText =
                      selectedReason!.toLowerCase().contains('기타')
                          ? otherController.text
                          : selectedReason!;

                  final alreadyReported = await ReportService().hasReported(
                    widget.postId,
                    uid,
                  );

                  if (alreadyReported) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('이미 신고한 게시글입니다.')),
                    );
                    return;
                  }

                  try {
                    await ReportService().submitReport(
                      postId: widget.postId,
                      postType: widget.postType,
                      reporterId: uid,
                      reason: reasonText,
                    );

                    if (!mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('신고가 접수되었습니다.')),
                    );
                    Navigator.of(context).pop();
                  } catch (e) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('신고 실패: $e')));
                  }
                },
                child: const Text(
                  '신고하기',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
