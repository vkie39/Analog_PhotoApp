import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReportListScreen extends StatefulWidget {
  final String postId;

  const ReportListScreen({required this.postId, super.key});

  @override
  State<ReportListScreen> createState() => _ReportListScreenState();
}

class _ReportListScreenState extends State<ReportListScreen> {
  Map<String, String> _uidToNickname = {}; // UID → 닉네임 매핑

  // 신고 컬렉션 스트림
  Stream<QuerySnapshot<Map<String, dynamic>>> _reportStream() {
    return FirebaseFirestore.instance
        .collection('reports')
        .where('postId', isEqualTo: widget.postId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // UID 목록으로 닉네임 미리 불러오기
  Future<void> _preloadNicknames(List<String> uids) async {
    final unknownUids = uids.where((uid) => !_uidToNickname.containsKey(uid)).toList();
    if (unknownUids.isEmpty) return;

    final snapshots = await FirebaseFirestore.instance
        .collection('users')
        .where(FieldPath.documentId, whereIn: unknownUids)
        .get();

    for (var doc in snapshots.docs) {
      _uidToNickname[doc.id] = doc.data()['nickname'] ?? '익명';
    }

    // 없는 UID는 '익명' 처리
    for (var uid in unknownUids) {
      _uidToNickname[uid] ??= '익명';
    }
    setState(() {}); // 닉네임 매핑 갱신
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '신고 내역',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
          final reporterUids = reports.map((r) => r.data()['reporterId'] as String).toList();

          // 닉네임 미리 불러오기
          _preloadNicknames(reporterUids);

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: reports.length,
            separatorBuilder: (context, index) => const Divider(
              height: 1,
              color: Colors.grey,
            ),
            itemBuilder: (context, index) {
              final data = reports[index].data();
              final reason = data['reason'] ?? '사유 없음';
              final reporterUid = data['reporterId'] ?? '';
              final reporterName = _uidToNickname[reporterUid] ?? '로딩 중...';

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "신고 사유 : $reason",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text("신고자 : $reporterName"),
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
