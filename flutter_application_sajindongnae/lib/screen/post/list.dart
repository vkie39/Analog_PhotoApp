

// 게시판 페이지


import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:flutter_application_sajindongnae/component/search.dart';
import 'package:flutter_application_sajindongnae/component/post_card.dart';
import 'package:flutter_application_sajindongnae/models/post_model.dart';


class ListScreen extends StatefulWidget {
  const ListScreen({super.key});

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen>{ 
  final searchController = TextEditingController(); // 검색창 내용을 컨트롤하기 위함

  final List<String> tabs = ['자유', '카메라추천', '피드백']; // 탭 이름 정의

  // Firestore 연결 전 임시 데이터 (결과 확인용)
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

  /*
  // 지금은 임시 데이터 사용 중
  final List<PostModel> postList = [..]; 위처럼럼 

  // 나중에 이렇게 수정해야 됨
  StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance.collection('posts').orderBy('timestamp', descending: true).snapshots(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) return CircularProgressIndicator();

      final postList = snapshot.data!.docs
          .map((doc) => PostModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      return ListView.builder(
        itemCount: postList.length,
        itemBuilder: (context, index) => PostCard(post: postList[index]),
      );
    },
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
            print('검색어 : $value');
            // 이후에 Firestore 쿼리 또는 리스트 필터링 로직 추가 필요함
          },
        ),
      ),

      body: Container( 
        color: Colors.white,
        child: DefaultTabController(
          length: tabs.length, 
          child: Column(
            children: [
              TabBar(
                labelColor: Colors.black,
                unselectedLabelColor: Colors.grey,
                /*indicator: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.black,
                      width: 2.5,
                    ),
                  ),
                ),
                indicatorSize: TabBarIndicatorSize.tab, */
                indicatorColor: Colors.black,
                tabs: tabs.map((label) => Tab(text: label)).toList() // map의 결과는 Iterable임. 위젯은 List를 보통 써서 toList로 형변환이 필요요
                ),

                Expanded(
                  child: TabBarView(
                    children: tabs.map((category) {
                      final filteredList = postList
                          .where((post) => post.category == category) // postList를 하나씩 post로 받아와서 필터링링
                          .toList();
                      return ListView.builder(
                        padding: EdgeInsets.symmetric(vertical: 15),
                        itemCount: filteredList.length, // filteredList에 몇개의 요소가 있는지 확인하고, 이 수를 기준으로 itemBuilder호출출
                        itemBuilder: (context, index){ // index는 ListView.builder내부에서 자동으로 0부터 itemCount-1까지 넣어줌
                          return PostCard(post: filteredList[index]);
                        },
                      );
                    }).toList(),                  
                  ),
                ),
            ],
          ),
        ),
      )
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