import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_sajindongnae/models/post_model.dart';
import 'package:flutter_application_sajindongnae/services/post_service.dart';
import 'package:flutter_application_sajindongnae/component/post_card.dart';

class PostCountScreen extends StatelessWidget {
  const PostCountScreen({super.key});

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

    final userPostsStream = PostService.getPostsByUser(currentUser.uid);

    return Scaffold(
      backgroundColor: Colors.white, // 💡 배경 흰색
      body: StreamBuilder<List<PostModel>>(
        stream: userPostsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Firestore에 데이터가 없을 때
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                '작성한 게시글이 없습니다.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final posts = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 10),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              print("🔥 불러온 게시글: ${post.title}");
              // 💥 여기서 네가 만든 PostCard UI 그대로 재사용
              return PostCard(post: post);
            },
          );
        },
      ),
    );
  }
}
