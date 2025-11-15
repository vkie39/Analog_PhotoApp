import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_sajindongnae/models/post_model.dart';
import 'package:flutter_application_sajindongnae/services/post_service.dart';
import 'package:flutter_application_sajindongnae/component/post_card.dart';

class LikedpostScreen extends StatelessWidget {
  LikedpostScreen({super.key});

  final _postService = PostService();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text("로그인이 필요합니다."));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: StreamBuilder<List<PostModel>>(
        stream: _postService.getLikedPosts(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("좋아요한 게시글이 없습니다."));
          }

          final likedPosts = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 10),
            itemCount: likedPosts.length,
            itemBuilder: (context, index) {
              return PostCard(post: likedPosts[index]);
            },
          );
        },
      ),
    );
  }
}
