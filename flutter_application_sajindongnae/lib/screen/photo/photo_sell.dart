import 'package:flutter/material.dart';
import 'package:flutter_application_sajindongnae/component/search.dart';
import 'package:flutter_application_sajindongnae/screen/photo/sell_detail.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';


class PhotoSellScreen extends StatefulWidget {
  const PhotoSellScreen({super.key});
  
  @override
  State<PhotoSellScreen> createState() => _PhotoSellScreenState();
} 

class _PhotoSellScreenState extends State<PhotoSellScreen> with SingleTickerProviderStateMixin{
  final searchController = TextEditingController(); // 검색창 내용을 컨트롤하기 위함

  List<String> tags = ['여름 방학','졸업 작품', '사진 동네', '바다', '감성 사진']; // 태그 저장 리스트 정의
  List<String> _selectedTags = []; 


  final List<String> tabs = ['판매', '구매']; // 탭 이름 정의
  late TabController _tabController; // late는 당장 초기화 안해도  nullable되는 것을 방지(나중에 값 넣을거라고 알려주는 타입)

  final List<String> prices = [
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
  void initState(){ // 탭바 초기화
    super.initState();
    _tabController = TabController(length: tabs.length, vsync: this); // SingleTickerProviderStateMixin 로 this를 받아올 수 있음. 애니메이션을 위해 사용

  }

  @override
  void dispose() { // 위젯 제거될 때 메모리 정리를 위해 호출
    _tabController.dispose();
    super.dispose();
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0, //그림자
          surfaceTintColor: Colors.transparent, 
          title: SearchBarWidget( //search.dart에서 정의한 검색창
            controller: searchController,
            onChanged: (value){
              print('검색어 : $value');
              // 이후에 Firestore 쿼리 또는 리스트 필터링 로직 추가 필요함
            },
            leadingIcon: IconButton(
              icon: const Icon(Icons.menu, color: Colors.black54),
              onPressed: (){
                print('photo_sell 메뉴 클릭');
              },
              )
          ),
        ),


        body: Listener(
          behavior: HitTestBehavior.translucent, // 클릭 이벤트가 있는(탭바 등)을 눌러도 키보드 내림
          onPointerDown: (_) {
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: Container( 
            color: Colors.white,
            child: Column(
              children: [
                // 태그 영역
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 26.0, vertical: 8.0),
                  child: SizedBox(
                      height: 35,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: tags.isEmpty? 1: tags.length+1, // '+ 태크 추가' 버튼 때문에 +1
                        separatorBuilder: (context, index) => const SizedBox(width: 8), // 각 테그 사이에 간격 8만큼
                        itemBuilder: (context, index) {
                          // 태그가 없을 때나 태그 맨 끝에
                          if (tags.isEmpty || index == tags.length){
                            return GestureDetector(
                              onTap: (){
                                print('태그 추가 버튼 클릭');
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  //border: Border.all(color: Colors.grey.shade300),
                                  //borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    '+ 태그 추가',
                                    style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ),
                            );
                          }


                          final tag = tags[index];
                          final isSelected = _selectedTags.contains(tag); // boolean

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
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFFDDECC7) : Colors.white,
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  tag,
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                ),

                // 탭 바 영역(판매,구매)
                TabBar(
                  controller: _tabController,
                  labelColor: Colors.black,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Colors.black,
                  tabs: tabs.map((label) => Tab(text: label)).toList() // map의 결과는 Iterable임. 위젯은 List를 보통 써서 toList로 형변환이 필요
                ),

                // 탭 콘텐츠
                Expanded(
                          child: _tabController.index == 0
                              // 판매탭
                              ? Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                                  child: MasonryGridView.count( // 동적 높이를 할당하는 그리드뷰
                                    crossAxisCount: 2, // 열 개수
                                    mainAxisSpacing: 8, // 새로 간격
                                    crossAxisSpacing: 8, // 좌우 간격
                                    itemCount: 10,
                                    itemBuilder: (context, index) {
                                      // 임시 데이터 (나중에 firestore랑 연결 필요)
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
                                          const SizedBox(height: 2), // 이미지와 텍스트 사이 간격
                                          Text(
                                            price,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w300,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ]
                                      );                                      
                                    },
                                  ),
                                )

                              // 구매탭
                              : Center(
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
          // 글쓰기 화면으로 이동
          Navigator.push(
            context, 
            MaterialPageRoute(
              builder: (context) => SellDetailScreen(),
            ),
          ); 
        },
        shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(100)), // 버튼 모양
        backgroundColor: Color(0xFFDDECC7),
        elevation: 5, // 그림자
        icon: Icon(Icons.photo, size:20, color: Colors.black),
        label: Text('업로드', style: TextStyle(fontSize:12, color: Colors.black)),
      ),


        
    );
  }
}