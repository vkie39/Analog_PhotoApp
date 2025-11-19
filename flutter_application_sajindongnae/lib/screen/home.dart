import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_sajindongnae/component/post_card.dart';
import 'package:flutter_application_sajindongnae/models/post_model.dart';
import 'package:flutter_application_sajindongnae/services/post_service.dart';
import 'package:flutter_application_sajindongnae/models/photo_trade_model.dart';
import 'package:flutter_application_sajindongnae/services/photo_trade_service.dart';

import 'package:flutter_application_sajindongnae/screen/post/post_detail.dart';
import 'package:flutter_application_sajindongnae/screen/photo/sell_detail.dart';

// 워터마크 오버레이 위젯
import 'package:flutter_application_sajindongnae/screen/photo/watermarked_image.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>{
  final _bestPageCtrl = PageController(viewportFraction: 0.9);
  int _bestPage = 0;

  Timer? _autoSlideTimer;     //  자동 슬라이드용 타이머
  int _bestPhotoCount = 0;    //  베스트 사진 개수

  @override
  void initState(){
    super.initState();
    _startAutoSlide();
  }

  @override
  void dispose(){
    _bestPageCtrl.dispose();
    _autoSlideTimer?.cancel();
    super.dispose();
  }

  // ★ 베스트 사진 자동 슬라이드
  void _startAutoSlide() {
    // 혹시 기존 타이머가 있으면 정리
    _autoSlideTimer?.cancel();

    _autoSlideTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      if (!_bestPageCtrl.hasClients) return;
      if (_bestPhotoCount <= 1) return; // 사진 1장 이하면 넘길 필요 없음

      final nextPage = (_bestPage + 1) % _bestPhotoCount;

      _bestPageCtrl.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );

      setState(() {
        _bestPage = nextPage;
      });
    });
  }


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
            // 알람 아이콘이 현재 별 기능이 없는데 디자인 적으로도 딱히 예브지 않은 것 같음
            /*
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Image.asset(
                  'assets/icons/alarm_icon.png',
                  width: 34,
                ),
              ),
            ],*/
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
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: LayoutBuilder( // 다시 감싸기
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final aspectRatio = width < 400 ? 4 / 3 : 1.5 / 1;

                      return StreamBuilder<List<PhotoTradeModel>>(
                        stream: PhotoTradeService.getTopLikedPhotosStream(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return SizedBox(
                              height: width / aspectRatio, // 로딩시에도 동일 비율 확보
                              child: const Center(child: CircularProgressIndicator()),
                            );
                          }

                          final photos = snapshot.data!;
                          _bestPhotoCount = photos.length;  // 자동 슬라이드용 사진 개수 저장

                          if (photos.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.all(20.0),
                              child: Text('아직 베스트 사진이 없습니다.'),
                            );
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              AspectRatio(
                                aspectRatio: aspectRatio,
                                child: PageView.builder(
                                  controller: _bestPageCtrl,
                                  itemCount: photos.length,
                                  onPageChanged: (i) => setState(() => _bestPage = i),
                                  itemBuilder: (_, index) {
                                  final photo = photos[index];

                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => SellDetailScreen(photo: photo),
                                          ),
                                        );
                                      },
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: WatermarkedImage.network(
                                          photo.imageUrl,
                                          fit: BoxFit.cover,
                                          watermarkText: '${photo.nickname} · 사진동네',
                                          opacity: 0.18,
                                          paddingFactor: 2.5,
                                          angleDeg: -45,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(photos.length, (i) {
                                  final isActive = i == _bestPage;
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 220),
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    width: isActive ? 16 : 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      color: isActive
                                          ? Colors.black.withOpacity(0.85)
                                          : Colors.black.withOpacity(0.25),
                                    ),
                                  );
                                }),
                              ),
                            ],
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
                        children: bestPosts.map((post) =>
                         PostCard(
                          post: post, 
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => PostDetailScreen(post: post)),
                            );
                          })).toList(),
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
