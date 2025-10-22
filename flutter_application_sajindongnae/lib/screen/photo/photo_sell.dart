import 'package:flutter/material.dart';
import 'package:flutter_application_sajindongnae/component/search.dart';
import 'package:flutter_application_sajindongnae/models/photo_trade_model.dart';
import 'package:flutter_application_sajindongnae/models/request_model.dart';
import 'package:flutter_application_sajindongnae/component/request_card.dart';
import 'package:flutter_application_sajindongnae/screen/photo/request_detail.dart';
import 'package:flutter_application_sajindongnae/screen/photo/sell_detail.dart';
import 'package:flutter_application_sajindongnae/screen/photo/sell_write.dart';
import 'package:flutter_application_sajindongnae/screen/photo/request_write.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_sajindongnae/services/request_service.dart';
import 'package:flutter_application_sajindongnae/services/photo_trade_service.dart'; // [수정] PhotoTrade Service 로 수정
class PhotoSellScreen extends StatefulWidget {
  const PhotoSellScreen({super.key});

  @override
  State<PhotoSellScreen> createState() => _PhotoSellScreenState();
}

class _PhotoSellScreenState extends State<PhotoSellScreen>
    with SingleTickerProviderStateMixin {
  final searchController = TextEditingController();
  final List<String> tags = ['여름 방학', '졸업 작품', '사진 동네', '바다', '감성 사진'];
  List<String> _selectedTags = [];

  final List<String> tabs = ['판매', '구매'];
  late TabController _tabController;

  final RequestService _requestService = RequestService();
  // [수정] PhotoTradeService 추가
  final PhotoTradeService _photoTradeService = PhotoTradeService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth <= 360;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: SearchBarWidget(
          controller: searchController,
          onChanged: (value) {
            print('검색어 : $value');
          },
          leadingIcon: IconButton(
            icon: const Icon(Icons.menu, color: Colors.black54),
            onPressed: () {
              print('photo_sell 메뉴 클릭');
            },
          ),
        ),
      ),
      body: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) {
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: Container(
          color: Colors.white,
          child: Column(
            children: [
              // 태그 영역
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: tags.isEmpty ? 1 : tags.length + 1,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      const double tagPaddingH = 16;
                      const double tagPaddingV = 10;
                      final double tagFontSize = isSmallScreen ? 12 : 14;
                      const double tagBorderRadius = 16;

                      if (tags.isEmpty || index == tags.length) {
                        return GestureDetector(
                          onTap: () {
                            print('태그 추가 버튼 클릭');
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: tagPaddingH,
                                vertical: tagPaddingV),
                            decoration: const BoxDecoration(color: Colors.white),
                            child: Align(
                              alignment: Alignment.center,
                              child: Text(
                                '+ 태그 추가',
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w500,
                                  fontSize: tagFontSize,
                                ),
                              ),
                            ),
                          ),
                        );
                      }

                      final tag = tags[index];
                      final isSelected = _selectedTags.contains(tag);

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedTags.remove(tag);
                            } else {
                              _selectedTags.add(tag);
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: tagPaddingH, vertical: tagPaddingV),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFDDECC7)
                                : Colors.white,
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFFBBD18B)
                                  : Colors.grey.shade300,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(tagBorderRadius),
                          ),
                          child: Align(
                            alignment: Alignment.center,
                            child: Text(
                              tag,
                              style: TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                                fontSize: tagFontSize,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // 탭 바
              TabBar(
                controller: _tabController,
                labelColor: Colors.black,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.black,
                tabs: tabs.map((label) => Tab(text: label)).toList(),
              ),

              // 콘텐츠
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // [수정] 판매 탭 Firestore 연동
                    StreamBuilder<List<PhotoTradeModel>>(
                      stream: _photoTradeService.getPhotoTrades(limit: 30),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Center(
                            child: Text('등록된 판매 사진이 없습니다.'),
                          );
                        }

                        final photos = snapshot.data!;
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          child: MasonryGridView.count(
                            crossAxisCount: 2,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            itemCount: photos.length,
                            itemBuilder: (context, index) {
                              final photo = photos[index];
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          SellDetailScreen(photo: photo),
                                    ),
                                  );
                                },
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        photo.imageUrl,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        "₩${photo.price}",
                                        style: TextStyle(
                                          fontWeight: FontWeight.w300,
                                          fontSize: isSmallScreen ? 10 : 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),

                    // [기존 유지] 구매(의뢰) 탭: Firestore 실시간 데이터
                    StreamBuilder<List<RequestModel>>(
                      stream: _requestService.getRequests(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Center(
                            child: Text('등록된 의뢰글이 없습니다.'),
                          );
                        }

                        final requests = snapshot.data!;
                        return ListView.separated(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          itemCount: requests.length,
                          separatorBuilder: (_, __) => const Divider(
                              height: 1, color: Color(0xFFEFEFEF)),
                          itemBuilder: (context, index) {
                            final r = requests[index];
                            return RequestCard(
                              request: r,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        RequestDetailScreen(request: r),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      // 글쓰기 버튼
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final selectedCategory = tabs[_tabController.index];
          switch (selectedCategory) {
            case '판매':
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SellWriteScreen()),
              );
              break;
            case '구매':
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => RequestWriteScreen()),
              );
              break;
          }
        },
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        backgroundColor: const Color(0xFFDDECC7),
        elevation: 5,
        icon: const Icon(Icons.photo, size: 20, color: Colors.black),
        label: const Text('업로드',
            style: TextStyle(fontSize: 12, color: Colors.black)),
      ),
    );
  }
}
