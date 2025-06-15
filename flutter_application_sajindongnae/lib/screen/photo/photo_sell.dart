import 'package:flutter/material.dart';
import 'package:flutter_application_sajindongnae/component/search.dart';
import 'package:flutter_application_sajindongnae/screen/photo/sell_detail.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class PhotoSellScreen extends StatefulWidget {
  const PhotoSellScreen({super.key});

  @override
  State<PhotoSellScreen> createState() => _PhotoSellScreenState();
}

class _PhotoSellScreenState extends State<PhotoSellScreen> with SingleTickerProviderStateMixin {
  final searchController = TextEditingController(); // 검색창 내용을 컨트롤하기 위함

  List<String> tags = ['여름 방학','졸업 작품', '사진 동네', '바다', '감성 사진']; // 태그 저장 리스트 정의
  List<String> _selectedTags = []; 

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
    final screenWidth = MediaQuery.of(context).size.width; // 화면 너비
    final isSmallScreen = screenWidth <= 360;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0, //그림자
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: tags.isEmpty ? 1 : tags.length + 1,
                    separatorBuilder: (context, index) => const SizedBox(width: 10),
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
                            padding: const EdgeInsets.symmetric(horizontal: tagPaddingH, vertical: tagPaddingV),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                            ),
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
                          padding: const EdgeInsets.symmetric(horizontal: tagPaddingH, vertical: tagPaddingV),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFDDECC7) : Colors.white,
                            border: Border.all(
                              color: isSelected ? const Color(0xFFBBD18B) : Colors.grey.shade300,
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
                child: _tabController.index == 0
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: MasonryGridView.count(
                          crossAxisCount: 2,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          itemCount: 10,
                          itemBuilder: (context, index) {
                            final imageName = 'assets/images/sellPhoto${index + 1}.JPG';
                            final price = prices[index];
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.asset(
                                    imageName,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    price,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w300,
                                      fontSize: isSmallScreen ? 10 : 12,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      )
                    : const Center(
                        child: Text('구매 탭입니다', style: TextStyle(color: Colors.grey)),
                      ),
              ),
            ],
          ),
        ),
      ),

      /// 글쓰기 버튼
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final selectedCategory = tabs[_tabController.index];
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SellDetailScreen(),
            ),
          );
        },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)), // 버튼 모양
        backgroundColor: const Color(0xFFDDECC7),
        elevation: 5, // 그림자
        icon: const Icon(Icons.photo, size: 20, color: Colors.black),
        label: const Text('업로드', style: TextStyle(fontSize: 12, color: Colors.black)),
      ),
    );
  }
}
