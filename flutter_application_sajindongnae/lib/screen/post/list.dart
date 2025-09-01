// 게시판 페이지

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:flutter_application_sajindongnae/component/search.dart';
import 'package:flutter_application_sajindongnae/component/post_card.dart';
import 'package:flutter_application_sajindongnae/models/post_model.dart';
import 'package:flutter_application_sajindongnae/services/post_service.dart';
import 'package:flutter_application_sajindongnae/screen/post/write.dart';
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

  final List<String> tabs = ['자유', '카메라추천', '피드백']; // 탭 이름 정의
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


  // Firestore 연결 전 임시 데이터 (결과 확인용)
  /*
  final List<PostModel> postList = List.generate(
    30,
    (index) => PostModel(
      postId: 'post_$index',
      userId: 'user_$index',
      nickname: '사용자$index',
      profileImageUrl: 'https://', // 아무 주소 없어서 오류 뜰거지만 괜찮음. 임시임
      category: index % 3 == 0 
          ? '자유'
          : index % 3 == 1
              ? '카메라추천'
              : '피드백',
      likeCount: 10 + index,
      commentCount: 5 + index,
      timestamp: DateTime.now().subtract(Duration(minutes: index * 15)),
      title: '제목 $index',
      content: '$index번째 테스트 게시글',
    ),
  );
  
*/



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0, //그림자
        title: SearchBarWidget( //search.dart에서 정의한 검색창
          controller: searchController,
          onChanged: (value){
            // 이후에 Firestore 쿼리 또는 리스트 필터링 로직 추가 필요함
            // 검색어 업데이트
            setState(() {
              searchKeyword = value.trim().toLowerCase();
            });
          },
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
              TabBar(
                controller: _tabController,
                labelColor: Colors.black,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.black,
                tabs: tabs.map((label) => Tab(text: label)).toList() // map의 결과는 Iterable임. 위젯은 List를 보통 써서 toList로 형변환이 필요요
                /*indicator: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.black,
                      width: 2.5,
                    ),
                  ),
                ),
                indicatorSize: TabBarIndicatorSize.tab, */
              ),
            
              Expanded(
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
                            return PostCard(post: filteredList[index]);
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