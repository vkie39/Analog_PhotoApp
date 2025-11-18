import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PointHistoryScreen extends StatelessWidget {
  const PointHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(
        title: const Text('포인트 내역'),
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: Colors.black,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('point_history')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('포인트 내역이 없습니다.'));
          }

          // 모델 없이 Map으로 바로 처리
          final histories = docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final amount = data['amount'] as int? ?? 0;
            final description = data['description'] as String? ?? '';
            final timestamp =
                (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
            return {
              'amount': amount,
              'description': description,
              'timestamp': timestamp,
            };
          }).toList();

          return ListView.separated(
            itemCount: histories.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final h = histories[index];
              final int amount = h['amount'] as int;
              final String description = h['description'] as String;
              final DateTime timestamp = h['timestamp'] as DateTime;

              return ListTile(
                title: Text(
                  description,
                  style: const TextStyle(fontSize: 16),
                ),
                trailing: Text(
                  '${amount > 0 ? '+' : ''}$amount',
                  style: TextStyle(
                    fontSize: 16,
                    color: amount > 0 ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')} '
                  '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
