import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_sajindongnae/models/request_model.dart';
import 'package:flutter_application_sajindongnae/services/request_service.dart';
import 'package:flutter_application_sajindongnae/screen/photo/request_detail.dart';

class LikedbuyScreen extends StatelessWidget {
  LikedbuyScreen({super.key});

  final RequestService _requestService = RequestService();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text("로그인이 필요합니다."));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: StreamBuilder<List<RequestModel>>(
        stream: _requestService.getLikedRequests(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("좋아요한 구매 사진이 없습니다."));
          }

          final likedRequests = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: likedRequests.length,
            itemBuilder: (context, index) {
              final request = likedRequests[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RequestDetailScreen(request: request),
                    ),
                  );
                },
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  child: ListTile(
                    leading: const Icon(Icons.image_outlined, size: 36),
                    title: Text(
                      request.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      request.location,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Text(
                      request.isFree ? "무료" : "₩${request.price}",
                      style: const TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
