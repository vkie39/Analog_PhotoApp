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
String searchKeyword = '';          // 입력된 단어 저장
List<PostModel> searchResults = []; // 검색 결과 게시글 저장용. 지금 사용x 인듯
List<PostModel> allPosts = [];      // 전체 게시글 저장용. 지금 사용x 인듯 -> 확실해지면 지우기


class ListScreen extends StatefulWidget { // 게시글 목록이 변하기 때문에 StatefulWidget
  const ListScreen({super.key});          // 생성자

  @override
  State<ListScreen> createState() => _ListScreenState();   // 상태 관리를 위한 _ListScreenState(State 객체) 생성
}

class _ListScreenState extends State<ListScreen> with SingleTickerProviderStateMixin{  // 탭 이벤트 발생시 화면 전환을 부드럽게 하기 위해 SingleTickerProviderStateMixin 사용
  final searchController = TextEditingController();        // 검색창 내용을 컨트롤하기 위함(입력값을 읽거나 지움)

  final List<String> tabs = ['자유', '카메라추천', '피드백']; // 탭 이름 정의
  late TabController _tabController;                       // 탭 전환과 인텍스 관리용 컨트롤러. late는 당장 초기화 안해도  nullable되는 것을 방지(나중에 값 넣을거라고 알려주는 타입)

  @override
  void initState(){ // 탭바 초기화. 위젯이 생성될 때 한 번만 호출되는 생명주기 메서드
    super.initState();
    _tabController = TabController(length: tabs.length, vsync: this); // SingleTickerProviderStateMixin 로 this를 받아올 수 있음. 애니메이션을 위해 사용

  }

  @override
  void dispose() { // 위젯 제거될 때 메모리 정리를 위해 호출
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
        backgroundColor: Colors.white, // 앱 바 배경색 
        elevation: 0,                    // 그림자
        title: SearchBarWidget(          // Appbar의 title자리에 search.dart에서 정의한 검색창 배치
          controller: searchController,  // 위에서 정의한 검색창 컨트롤러

          onChanged: (value){
            // 이후에 Firestore 쿼리 또는 리스트 필터링 로직 추가 필요함
            // 검색어 업데이트
            setState(() {
              searchKeyword = value.trim().toLowerCase();
            });
          },
        ),
      ),

      body: Listener(                                    // 하위 위젯의 포인터 이벤트를 감지하는 위젯
        behavior: HitTestBehavior.translucent,           // 클릭 이벤트가 있는(탭바 등)을 눌러도 키보드 내리고 하위 위젯의 클릭 이벤트도 처리
        onPointerDown: (_) {                             // 포커스된 입력창의 포커스 제거, 키보드 내림
          FocusManager.instance.primaryFocus?.unfocus(); // FocusManager 클래스의 instance라는 싱글톤 객체를 통해 primaryFocus사용. 현재 포커스를 가진 위젯의 FocusNode를 가리킴 
        },

        child: Container(                                // AppBar 아래 컨테이너 만들어서 배경색 지정. 탭바뷰 만듦
          color: Colors.white,
          child: Column(                                 // 탭바와 탭바뷰를 만들기 위한 Column
            children: [                                  // 탭바와 탭바뷰를 만들 children
              TabBar(
                controller: _tabController,              // 위에서 length 지정한 컨트롤러             
                labelColor: Colors.black,              // 선택시 스타일 지정
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.black,          // 문자열을 사용하면 오류가 나기 때문에 map을 통해 tabs(자유, 카메라추천..)를 List<String> -> Iterable<Tab>으로 변환
                tabs: tabs.map((label) => Tab(text: label)).toList() // map의 결과는 Iterable. TabBar가 List를 사용하기 때문에 toList로 형변환이 필요
              ),
            
              Expanded(                                  // 남은 공간을 모두 차지하도록 하는 위젯

                child: TabBarView(
                  controller: _tabController,
                  children: tabs.map((category) {
                    return StreamBuilder<List<PostModel>>(
                      stream: PostService.getPostsByCategory(category),             // ← Firestore에서 데이터 스트림 가져오기
                      builder: (context, snapshot) {                                // 데이터가 변경될 때 자동 호출, UI업데이트, snapshot엔 현재 데이터 상태, 로딩여부 등이 있음
                        if (snapshot.connectionState == ConnectionState.waiting) {  // 데이터 받아오는 중이면 로딩표시
                          return Center(child: CircularProgressIndicator());
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {          // 게시글이 없을 경우 안내문구 출력
                          return Center(child: Text('게시글이 없습니다.'));
                        }
                        // 검색기능을 위해 추가된 부분
                        final List<PostModel> rawList = snapshot.data!;              // 스트림에서 받은 카테고리별 원본 게시글 목록


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