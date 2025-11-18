import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReportListScreen extends StatelessWidget {
  final String postId;

  const ReportListScreen({
    required this.postId,
    super.key,
  });

  Stream<QuerySnapshot<Map<String, dynamic>>> _reportStream() {
    return FirebaseFirestore.instance
        .collection('reports')                // 전체 신고 컬렉션
        .where('postId', isEqualTo: postId)   // 해당 게시글 신고만 필터링
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '신고 내역',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      backgroundColor: Colors.white,
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _reportStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text("신고 목록을 불러올 수 없습니다."));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("신고 내역이 없습니다."));
          }

          final reports = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final data = reports[index].data();
              final reason = data['reason'] ?? '사유 없음';
              final reporter = data['reporterId'] ?? '익명';
              // final timestamp = data['timestamp']?.toDate();

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 4,
                      color: Colors.black.withOpacity(0.05),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "신고 사유: $reason",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text("신고자: $reporter"),
                    // if (timestamp != null)
                    //   Text(
                    //     "신고일: $timestamp",
                    //     style: TextStyle(color: Colors.grey[600]),
                    //   ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
