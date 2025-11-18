// 게시판 페이지

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:flutter_application_sajindongnae/component/search.dart';
import 'package:flutter_application_sajindongnae/component/post_card.dart';
import 'package:flutter_application_sajindongnae/models/post_model.dart';
import 'package:flutter_application_sajindongnae/services/post_service.dart';
import 'package:flutter_application_sajindongnae/screen/post/write.dart';
import 'package:flutter_application_sajindongnae/screen/post/post_detail.dart';
import 'package:flutter/gestures.dart';


// 검색 기능을 위한 필드
String searchKeyword = '';
List<PostModel> searchResults = [];
List<PostModel> allPosts = []; // 전체 게시글 저장용


class ListScreen extends StatefulWidget {
  const ListScreen({super.key});

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> with SingleTickerProviderStateMixin{ 
  final searchController = TextEditingController(); // 검색창 내용을 컨트롤하기 위함

  final List<String> tabs = ['자유', '카메라추천', 'QnA']; // 탭 이름 정의
  late TabController _tabController; // late는 당장 초기화 안해도  nullable되는 것을 방지(나중에 값 넣을거라고 알려주는 타입)


  @override
  void initState(){ // 탭바 초기화
    super.initState();
    _tabController = TabController(length: tabs.length, vsync: this); // SingleTickerProviderStateMixin 로 this를 받아올 수 있음. 애니메이션을 위해 사용용

  }

  @override
  void dispose() { // 위젯 제거될 때 메모리 정리를 위해 호출출
    _tabController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white, // 앱 바 배경색 
        elevation: 0,                    // 그림자
        leadingWidth: 40, // 메뉴 버튼 공간만 확보
        titleSpacing: 0,  // title 좌우 간격 최소화
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: SearchBarWidget(
            controller: searchController,
            onChanged: (value) {
              setState(() {
                searchKeyword = value.trim().toLowerCase();
              });
            },
          ),
        ),
      ),

      body: Listener(
        behavior: HitTestBehavior.translucent, // 클릭 이벤트가 있는(탭바 등)을 눌러도 키보드 내림
        onPointerDown: (_) {
          FocusManager.instance.primaryFocus?.unfocus();
        },
        /*onTap: () {
          FocusScope.of(context).unfocus(); // 키보드 내리기
        },
        behavior: HitTestBehavior.opaque, */
        child: Container( 
          color: Colors.white,
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 0),
                child: TabBar(
                  controller: _tabController,
                  labelColor: Colors.black,
                  labelStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 15,
                  ),
                  unselectedLabelColor: Colors.grey,

                  // 3개 탭에 최적화된 인디케이터 길이
                  indicator: const UnderlineTabIndicator(
                    borderSide: BorderSide(width: 3, color: Colors.black),
                    insets: EdgeInsets.symmetric(
                      horizontal: 90,   // 3개일 때 딱 예쁘게 나옴
                    ),
                  ),

                  indicatorWeight: 2,
                  isScrollable: false, // 균등 분배
                  tabs: [
                    SizedBox(width: 80, child: Tab(text: '자유')),
                    SizedBox(width: 80, child: Tab(text: '카메라추천')),
                    SizedBox(width: 80, child: Tab(text: 'QnA')),
                  ],
                ),
              ),

              Expanded(                                  // 남은 공간을 모두 차지하도록 하는 위젯
                child: TabBarView(
                  controller: _tabController,
                  children: tabs.map((category) {
                    return StreamBuilder<List<PostModel>>(
                      stream: PostService.getPostsByCategory(category), // ← Firestore에서 데이터 스트림 가져오기
                      builder: (context, snapshot) { // 데이터가 변경될 때 자동 호출, UI업데이트, snapshot엔 현재 데이터 상태, 로딩여부 등이 있음
                        if (snapshot.connectionState == ConnectionState.waiting) { // 데이터 받아오는 중이면 로딩표시시
                          return Center(child: CircularProgressIndicator());
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) { // 게시글이 없을 경우 안내문구구 출력
                          return Center(child: Text('게시글이 없습니다.'));
                        }
                        // 검색기능을 위해 추가된 부분
                        final List<PostModel> rawList = snapshot.data!;


                        final filteredList = rawList.where((post){
                          if(searchKeyword.isEmpty) return true;
                          return post.title.toLowerCase().contains(searchKeyword) ||
                                 post.content.toLowerCase().contains(searchKeyword);
                        }).toList();
                
                
                        return ListView.builder(
                          padding: EdgeInsets.symmetric(vertical: 15),
                          itemCount: filteredList.length,
                          itemBuilder: (context, index) {
                            final p = filteredList[index];
                            return PostCard(
                              post: p, 
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => PostDetailScreen(post: p)),
                                );
                              });
                          },
                        );
                      },
                    );
                  }).toList(),            
                ),  
              ),
            ],
          ),
        ),
      ),

      /// 글쓰기 버튼
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async { // ← 수정: async 추가
          final selectedCategory = tabs[_tabController.index];
          // 글쓰기 화면으로 이동
          final result = await Navigator.push( // ← 수정: await + result로 결과 받음
            context, 
            MaterialPageRoute(
              builder: (context) => WriteScreen(category: selectedCategory),
            ),
          ); 

          // ← 추가: 글쓰기 완료 후 새로고침 트리거
          if (result == true) {
            setState(() {}); 
          }
        },


        shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(100)), // 버튼 모양
        backgroundColor: Color(0xFFDDECC7),
        elevation: 5, // 그림자
        icon: Icon(Icons.edit, size:20, color: Colors.black),
        label: Text('글 쓰기', style: TextStyle(fontSize:12, color: Colors.black)),
      ),
    );  
  } 
}



/* Tab navigation구현 전
      body: Column(
        children: [
          SearchBarWidget( //search.dart에서 정의한 검색창창
            controller: searchController,
            onChanged: (value) {
              print('검색어: $value');
              // 이후에 Firestore 쿼리 또는 리스트 필터링 로직 추가 가능
            },
          ),
          Expanded(
            child: ListView.builder(
              itemCount: postList.length,
              itemBuilder: (context, index) {
                return PostCard(post: postList[index]);
              },
            ),
          ),
        ],
      ),
      */