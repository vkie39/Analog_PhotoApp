import 'package:flutter/material.dart';
import 'package:flutter_application_sajindongnae/component/search.dart';
import 'package:flutter_application_sajindongnae/component/request_card.dart';
import 'package:flutter_application_sajindongnae/models/tag_model.dart';
import 'package:flutter_application_sajindongnae/screen/photo/request_detail.dart';
import 'package:flutter_application_sajindongnae/screen/photo/sell_detail.dart';
import 'package:flutter_application_sajindongnae/screen/photo/sell_write.dart';
import 'package:flutter_application_sajindongnae/screen/photo/request_write.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_application_sajindongnae/screen/photo/tag_select.dart';

import 'package:flutter_application_sajindongnae/models/request_model.dart';
import 'package:flutter_application_sajindongnae/services/request_service.dart';
import 'package:flutter_application_sajindongnae/services/photo_trade_service.dart';
import 'package:flutter_application_sajindongnae/models/photo_trade_model.dart';

class PhotoSellScreen extends StatefulWidget {
  const PhotoSellScreen({super.key});

  @override
  State<PhotoSellScreen> createState() => _PhotoSellScreenState();
}

class _PhotoSellScreenState extends State<PhotoSellScreen>
    with SingleTickerProviderStateMixin {
  final searchController = TextEditingController();
  List<String> tags = [];
  List<String> _selectedTags = [];
  SelectedTagState _searchTagState = SelectedTagState();

  final List<String> tabs = ['판매', '구매'];
  late TabController _tabController;

  final RequestService _requestService = RequestService();
  final PhotoTradeService _photoTradeService = PhotoTradeService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabs.length, vsync: this);

    // 탭 변경 시 UI 갱신
    _tabController.addListener(() {
      // if (_tabController.indexIsChanging) return; // 드래그 중일 때는 무시
      setState(() {}); // 탭이 바뀔 때 rebuild
    });
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
      leadingWidth: 40, // 메뉴 버튼 공간만 확보
      titleSpacing: 0,  // title 좌우 간격 최소화
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0), // title 안쪽 여백
        child: SearchBarWidget(
          controller: searchController,
          onChanged: (value) => print('검색어 : $value'),
        ),
      ),
    ),

      body: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => FocusManager.instance.primaryFocus?.unfocus(),
        child: Container(
          color: Colors.white,
          child: Column(
            children: [
              // 태그 영역
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: tags.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      const double tagPaddingH = 16;
                      const double tagPaddingV = 10;
                      final double tagFontSize = isSmallScreen ? 12 : 14;
                      const double tagBorderRadius = 20;

                      if (index == tags.length) {
                        return GestureDetector(
                          onTap: () async {
                            final result = await Navigator.push<SelectedTagState>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TagSelectionScreen(
                                  initialState: _searchTagState,
                                  forceMultiSelect: true,
                                  title: '검색 태그 선택',
                                  showAppBar: true,
                                ),
                              ),
                            );
                            if (result != null) {
                              setState(() {
                                _searchTagState = result;
                                tags = [...result.multiTags.values.expand((s) => s)];
                                _selectedTags = List.from(tags);
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: tagPaddingH, vertical: tagPaddingV),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(tagBorderRadius),
                              border: Border.all(color: Colors.grey.shade300, width: 1),
                            ),
                            child: Center(
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

                      return Chip(
                        label: Text(
                          tag,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: tagFontSize,
                          ),
                        ),
                        backgroundColor: isSelected ? const Color(0xFFBBD18B) : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(tagBorderRadius),
                          side: const BorderSide(color: Color(0xFFBBD18B), width: 1),
                        ),
                        onDeleted: () {

                          final removedTag = tags[index];
                          setState(() {
                            tags.removeAt(index);
                            _selectedTags.remove(tag);

                             // 검색 상태(_searchTagState)에서도 제거
                             // 2) 기존 multiTags를 깊은 복사(Deep Copy)
                             final newMulti = <String, Set<String>>{};
                             _searchTagState.multiTags.forEach((key, value) {
                              newMulti[key] = Set<String>.from(value);  // 불변 → 변경 가능
                              });
                              // 3) 복사된 데이터에서 해당 태그 제거
                              newMulti.updateAll((key, value) {
                                value.remove(removedTag);
                                return value;
                                });
                                // 4) 빈 Set은 제거
                                newMulti.removeWhere((key, value) => value.isEmpty);
                                // 5) 새로운 상태로 업데이트
                                _searchTagState = SelectedTagState(
                                  singleTags: _searchTagState.singleTags, // 그대로 유지
                                  multiTags: newMulti, );
                          });
                        },
                        deleteIcon: const Icon(Icons.close, color: Colors.white, size: 18),
                      );
                    },
                  ),
                ),
              ),

              // 탭바
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 0),
                child: TabBar(
                  controller: _tabController,
                  labelColor: Colors.black,
                  labelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  unselectedLabelStyle: TextStyle(fontSize: 15),
                  unselectedLabelColor: Colors.grey,
                  indicator: UnderlineTabIndicator(
                    borderSide: BorderSide(width: 4, color: Colors.black),
                    insets: EdgeInsets.symmetric(horizontal: 100), // 선 길이 조절
                  ),
                  indicatorWeight: 2, // 선 두께
                  tabs: tabs.map((label) => Tab(text: label)).toList(),
                  isScrollable: false, // 균등 분배
                ),
              ),


              // 콘텐츠
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // 판매 탭
                    StreamBuilder<List<PhotoTradeModel>>(
                      stream: _photoTradeService.searchTradeByTags(_searchTagState),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Center(child: Text('등록된 판매 사진이 없습니다.'));
                        }
                        final photos = snapshot.data!;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          child: MasonryGridView.count(
                            crossAxisCount: 2,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            itemCount: photos.length,
                            itemBuilder: (context, index) {
                              final photo = photos[index];
                              return GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => SellDetailScreen(photo: photo),
                                  ),
                                ),
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

                    // 구매 탭
                    StreamBuilder<List<RequestModel>>(
                      stream: _requestService.getRequests(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Center(child: Text('등록된 의뢰글이 없습니다.'));
                        }
                        final requests = snapshot.data!;
                        return ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          itemCount: requests.length,
                          separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFEFEFEF)),
                          itemBuilder: (context, index) {
                            final r = requests[index];
                            return RequestCard(
                              request: r,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => RequestDetailScreen(request: r)),
                              ),
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

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_tabController.index == 0) {
            // 판매 탭
            Navigator.push(context, MaterialPageRoute(builder: (_) => SellWriteScreen()));
          } else {
            // 구매 탭
            Navigator.push(context, MaterialPageRoute(builder: (_) => RequestWriteScreen()));
          }
        },
        backgroundColor: const Color(0xFFDDECC7), // 배경색
        elevation: 0, // 그림자 제거
        label: Text(
          _tabController.index == 0 ? '판매하기' : '구매하기',
          style: const TextStyle(color: Colors.black),
        ),
      ),
    );
  }
}