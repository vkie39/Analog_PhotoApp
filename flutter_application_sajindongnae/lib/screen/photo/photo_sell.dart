import 'package:flutter/material.dart';
import 'package:flutter_application_sajindongnae/component/search.dart';
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

import 'package:flutter_application_sajindongnae/models/request_model.dart';
import 'package:flutter_application_sajindongnae/services/request_service.dart';
import 'package:flutter_application_sajindongnae/services/photo_trade_service.dart'; // [수정] PhotoTrade Service 로 수정
import 'package:flutter_application_sajindongnae/models/photo_trade_model.dart';

class PhotoSellScreen extends StatefulWidget {
  const PhotoSellScreen({super.key});

  @override
  State<PhotoSellScreen> createState() => _PhotoSellScreenState();
}

class _PhotoSellScreenState extends State<PhotoSellScreen>
    with SingleTickerProviderStateMixin {
  final searchController = TextEditingController();
  List<String> tags = []; // 용도 : 화면에 보여줄 태그 리스트 (tag_select.dart에서 받아 옴)
  List<String> _selectedTags = []; // 용도: 화면에 보여줄 선택된 태그 리스트 (색상 변경용)
  SelectedTagState _searchTagState = SelectedTagState(); // 태그 선택 상태 관리용, 용도 : tag_select.dart와 데이터를 주고 받는 용

  final List<String> tabs = ['판매', '구매']; // 탭 이름 정의
  late TabController _tabController;

  final RequestService _requestService = RequestService();
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

  // 사진 위에 중앙 워터마크 한 번만 찍는 빌더
  Widget _waterMarkedImage({
    required String imageUrl,
    required String nickname,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 화면 너비 기준으로 글자 크기 계산
        final double baseWidth = constraints.maxWidth;

        // 너무 크지 않게 적당히 조절 (예: 10% 정도)
        final double fontSize = (baseWidth * 0.10).clamp(16.0, 30.0);

        return Stack(
          alignment: Alignment.center,
          children: [
            // 원본 비율 유지하면서 가로 꽉 채우기
            Image.network(
              imageUrl,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            // 중앙 워터마크 텍스트
            Text(
              '$nickname \n사진동네',   // 🔥 줄바꿈 들어간 버전
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: Colors.white.withOpacity(0.35),
                shadows: [
                  Shadow(
                    blurRadius: 4,
                    offset: const Offset(1, 1),
                    color: Colors.black.withOpacity(0.5),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
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
                                      borderRadius: BorderRadius.circular(5),
                                      child: _waterMarkedImage(
                                        imageUrl: photo.imageUrl,
                                        nickname: photo.nickname,   // PhotoTradeModel에 있는 닉네임 필드
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: Padding(
                                        padding: const EdgeInsets.only(right: 4.0), // 오른쪽 패딩 
                                        child: Text(
                                          "⭐${photo.price}",
                                          style: TextStyle(
                                            fontWeight: FontWeight.w300,
                                            fontSize: isSmallScreen ? 10 : 12,
                                          ),
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
