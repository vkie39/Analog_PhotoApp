import 'package:flutter/material.dart';
import 'package:flutter_application_sajindongnae/component/post_card.dart';
import 'package:flutter_application_sajindongnae/models/post_model.dart';
import 'package:flutter_application_sajindongnae/services/post_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 50,
        backgroundColor: Colors.white,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Image.asset(
            'assets/icons/app_icon.png',
            width: 40,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Image.asset(
              'assets/icons/alarm_icon.png',
              width: 34,
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 사진 베스트 제목
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
              child: Text(
                '사진 베스트',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),

            // 베스트 사진 4장
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.count(
                crossAxisCount: 2,
                childAspectRatio: 1.3, 
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: List.generate(4, (index) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'assets/images/best.JPG',
                      fit: BoxFit.cover,
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: 20),

            // 게시글 베스트 제목
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                '게시글 베스트',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            // 게시글 베스트 3개 표시
            StreamBuilder<List<PostModel>>(
              stream: PostService.getAllPosts(), // ✅ 기존 best_post 대신 사용
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                } else if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text('오류 발생: ${snapshot.error}'),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text('게시글이 없습니다.'),
                  );
                } else {
                  final latestPosts = snapshot.data!.take(3).toList(); // ✅ 상위 3개만 사용

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: latestPosts.length,
                    itemBuilder: (context, index) {
                      return PostCard(post: latestPosts[index]);
                    },
                  );
                }
              },
            ),

/* 여긴 post_service.dart에 베스트 3개만 뽑아주는 코드가 필요함
            // 게시글 베스트 3개만 표시
            StreamBuilder<List<PostModel>>(
              stream: PostService.getBestPostsStream(), // 실시간 베스트 3개
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                } else if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text('오류 발생: ${snapshot.error}'),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text('게시글이 없습니다.'),
                  );
                } else {
                  final bestPosts = snapshot.data!; // 이미 limit(3) 적용됨

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: bestPosts.length,
                    itemBuilder: (context, index) {
                      return PostCard(post: bestPosts[index]);
                    },
                  );
                }
              },
            ),
*/
          ],
        ),
      ),
    );
  }
}
