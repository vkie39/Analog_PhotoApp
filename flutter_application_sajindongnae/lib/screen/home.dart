import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_sajindongnae/component/post_card.dart';
import 'package:flutter_application_sajindongnae/models/post_model.dart';
import 'package:flutter_application_sajindongnae/services/post_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light, // iOS용
      ),
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            toolbarHeight: 50,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            elevation: 0.5,
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
              ),
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
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),

                // 베스트 사진 4장
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final aspectRatio = width < 400 ? 1.0 : 1.3;

                      final bestImagePaths = [
                        'assets/images/best.JPG',
                        'assets/images/sellPhoto9.JPG',
                        'assets/images/sellPhoto10.JPG',
                        'assets/images/sellPhoto5.JPG',
                      ];

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: bestImagePaths.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: aspectRatio,
                        ),
                        itemBuilder: (context, index) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(
                              bestImagePaths[index],
                              fit: BoxFit.cover,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // 게시글 베스트 제목
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.0),
                  child: Text(
                    '게시글 베스트',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),

                // 게시글 베스트 3개 표시
                StreamBuilder<List<PostModel>>(
                  stream: PostService.getBestPostsStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    } else if (snapshot.hasError) {
                      debugPrint('게시글 스트림 에러: ${snapshot.error}');
                      return const Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text('오류 발생. 나중에 다시 시도해주세요.'),
                      );
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text('게시글이 없습니다.'),
                      );
                    } else {
                      final bestPosts = snapshot.data!;

                      return Column(
                        children: bestPosts.map((post) => PostCard(post: post)).toList(),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
