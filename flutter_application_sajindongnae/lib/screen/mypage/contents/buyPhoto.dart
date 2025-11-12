import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_sajindongnae/models/request_model.dart';
import 'package:flutter_application_sajindongnae/services/request_service.dart';
import 'package:flutter_application_sajindongnae/component/request_card.dart';
import 'package:flutter_application_sajindongnae/screen/photo/request_detail.dart';

class BuyPhotoScreen extends StatelessWidget {
  BuyPhotoScreen({super.key});

  final RequestService _requestService = RequestService();

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Center(
        child: Text(
          '로그인이 필요합니다.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: StreamBuilder<List<RequestModel>>(
        stream: _requestService.getRequests(), // 모든 요청 불러오기
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("등록한 구매 의뢰글이 없습니다."));
          }

          // 현재 사용자 uid와 일치하는 글만 필터링
          final userRequests = snapshot.data!
              .where((r) => r.uid == currentUser.uid)
              .toList();

          if (userRequests.isEmpty) {
            return const Center(child: Text("등록한 구매 의뢰글이 없습니다."));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(8),
            itemCount: userRequests.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: Color(0xFFEFEFEF)),
            itemBuilder: (context, index) {
              final request = userRequests[index];
              return RequestCard(
                request: request,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RequestDetailScreen(request: request),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
