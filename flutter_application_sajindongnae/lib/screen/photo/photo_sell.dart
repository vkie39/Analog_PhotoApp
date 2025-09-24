import 'package:flutter/material.dart';
import 'package:flutter_application_sajindongnae/component/search.dart';
import 'package:flutter_application_sajindongnae/models/photo_model.dart';
import 'package:flutter_application_sajindongnae/models/request_model.dart';
import 'package:flutter_application_sajindongnae/component/request_card.dart';
import 'package:flutter_application_sajindongnae/screen/photo/request_detail.dart';
import 'package:flutter_application_sajindongnae/screen/photo/sell_detail.dart';
import 'package:flutter_application_sajindongnae/screen/photo/sell_write.dart';
import 'package:flutter_application_sajindongnae/screen/photo/request_write.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';


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
      title: "동아리 행사 사진 부탁드립니다아",
      description: "대학 축제 사진 구합니다",
      price: 1000,
      location: "강남구",
      position: LatLng(37.115, 126.688),
      bookmarkedBy: ['u1', 'u52', 'u32'],
    ),
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
                            color: isSelected ? const Color(0xFFDDECC7) : Colors.white,              //선택된 태그 색상
                            border: Border.all(
                              color: isSelected ? const Color(0xFFBBD18B) : Colors.grey.shade300,    //선택된 태그 테두리 색상
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
                    // 판매 탭
                    Padding(

                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: MasonryGridView.count(
                          crossAxisCount: 2,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          itemCount: 10,
                          itemBuilder: (context, index) {
                            final imageName = 'assets/images/sellPhoto${index + 1}.JPG';
                            final price = prices[index];                   
                            //임시 데이터
                            PhotoModel dummyPhoto = PhotoModel(
                              photoId: '1',
                              uid: 'dummy_uid',
                              nickname: '반딧불이 작가',
                              profileImageUrl: 'https://example.com/profile.png',
                              category: '몽골,하늘사진,소니카메라,안녕하세요,태그,어디까지,스크롤,크로와상',
                              likeCount: 20,
                              commentCount: 5,
                              dateTime: DateTime(2025, 2, 5),
                              title: '몽골 은하수',
                              description: '아름다운 몽골 은하수와 보랏빛 하늘\n그리고 나무가 어우러진 사진입니다',
                              imageUrl: 'assets/images/sellPhoto${index + 1}.JPG', // 로컬 이미지 경로
                              price: 2000,
                              location: 'Baganuur, Ulaanbaatar 12060',
                            );

                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SellDetailScreen(
                                      photo: dummyPhoto,
                                    ),
                                  ),
                                );
                              },
                              child: Column(
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
                              ),
                            );

                          },
                        ),
                      ),

                    // 구매탭 TODO : firebase 연동후 실시간 스트림으로 바꿔야 함
                    ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      itemCount: dummyRequests.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, color: Color(0xFFEFEFEF)),
                      itemBuilder: (context, index) {
                        final r = dummyRequests[index];
                        return RequestCard(
                          request: r,
                          onTap: () {
                            print("${r.title} 클릭됨");
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_)=> RequestDetailScreen(request: r)),
                            );
                          },
                        );
                      },
                    )
                  ],
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
          switch (selectedCategory){       // 판매탭에서 '판매글 쓰기', 구매(의뢰)탭에선 '의뢰글 쓰기'로  
            case '판매':
              Navigator.push(
                context,      
                MaterialPageRoute(
                  builder: (context) => SellWriteScreen(),
                ),
              );
              break;
            case '구매':
              Navigator.push(
                context,      
                MaterialPageRoute(
                  builder: (context) => RequestWriteScreen(),
                ),
              );    
              break;
            default:
              break;
          }     
        },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), // 버튼 모양
        backgroundColor: const Color(0xFFDDECC7),
        elevation: 5, // 그림자
        icon: const Icon(Icons.photo, size: 20, color: Colors.black),
        label: const Text('업로드', style: TextStyle(fontSize: 12, color: Colors.black)),
      ),
    );
  }
}
