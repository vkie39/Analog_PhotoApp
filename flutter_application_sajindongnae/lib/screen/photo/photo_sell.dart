import 'package:flutter/material.dart';
import 'package:flutter_application_sajindongnae/component/search.dart';
import 'package:flutter_application_sajindongnae/models/photo_trade_model.dart';
import 'package:flutter_application_sajindongnae/models/request_model.dart';
import 'package:flutter_application_sajindongnae/component/request_card.dart';
import 'package:flutter_application_sajindongnae/models/tag_model.dart';
import 'package:flutter_application_sajindongnae/screen/photo/request_detail.dart';
import 'package:flutter_application_sajindongnae/screen/photo/sell_detail.dart';
import 'package:flutter_application_sajindongnae/screen/photo/sell_write.dart';
import 'package:flutter_application_sajindongnae/screen/photo/request_write.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_application_sajindongnae/screen/photo/tag_select.dart';

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

/*
  List<String> tags = []; // 용도 : 화면에 보여줄 태그 리스트 (tag_select.dart에서 받아 옴)
  List<String> _selectedTags = []; // 용도: 화면에 보여줄 선택된 태그 리스트 (색상 변경용)
  SelectedTagState _searchTagState = SelectedTagState(); // 태그 선택 상태 관리용, 용도 : tag_select.dart와 데이터를 주고 받는 용

  final List<String> tabs = ['판매', '구매']; // 탭 이름 정의
  late TabController _tabController;

  final List<String> prices = [ // 가격 임시 데이터
    '₩1,000',
    '₩1,000',
    '₩1,500',
    '₩1,000',
    '₩5,000',
    '₩3,000',
    '₩2,900',
    '₩1,000',
    '₩5,000',
    '₩500',
  ];

  // 의뢰글 임시 데이터
  final List<RequestModel> dummyRequests = [
    RequestModel(
      requestId: "1",
      uid: "user1",
      nickname: "동미대욜로생",
      profileImageUrl: "https://example.com/1.png",
      category: "풍경",
      dateTime: DateTime.now().subtract(const Duration(minutes: 3)),
      title: "동미대 학식 사진 구합니다",
      description: "엄마한테 학식 먹고 있다고 뻥치고 놀러왔는데 뭐 먹는지 궁금하시대요.. 10분안에 가능하신분 찾습니다",
      price: 0,
      location: "구로구",
      position: LatLng(37.495, 126.887),
      bookmarkedBy: ['u1', 'u2', 'u3'],
    ),
    RequestModel(
      requestId: "2",
      uid: "user2",
      nickname: "메가리카노",
      profileImageUrl: "https://example.com/2.png",
      category: "행사",
      dateTime: DateTime.now().subtract(const Duration(hours: 1)),
      title: "동아리 행사 사진 부탁드립니다아dkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkoooooooooooooooooooooooooooooooook",
      description: "대학 축제 사진 구합니다",
      price: 1000,
      location: "강남구",
      position: LatLng(37.115, 126.688),
      bookmarkedBy: ['u1', 'u52', 'u32'],
    ),
  ];
  */
  SelectedTagState _searchTagState = SelectedTagState(); // 태그 선택 상태 관리용, 용도 : tag_select.dart와 데이터를 주고 받는 용               
  final List<String> tabs = ['판매', '구매'];
  late TabController _tabController;

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
                          onTap: () async {
                            print('태그 추가 버튼 클릭');
                            final result = await Navigator.push<SelectedTagState>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TagSelectionScreen(
                                  initialState: _searchTagState,
                                  forceMultiSelect: true,         // 모든 섹션 다중 선택 강제
                                  title: '검색 태그 선택',
                                  showAppBar: true,               // 바텀시트로 쓰고 싶으면 false로 하고 content만 분리 해도 됨
                                ),
                              ),
                            );
                            if (result != null) {
                              setState(() {
                                _searchTagState = result;
                                // 화면에 보일 태그 문자열 리스트
                                tags = [
                                  ...result.multiTags.values.expand((s) => s),
                                ];
                                _selectedTags = List.from(tags); // tag_select에서 선택한 태그들을 모두 '선택됨'으로 설정한다
                              });

                              // TODO: 여기서 Firestore 쿼리 실행
                            }
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
