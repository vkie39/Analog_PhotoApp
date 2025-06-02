import 'package:flutter/material.dart';
import 'package:flutter_application_sajindongnae/component/search.dart';
import 'package:flutter_application_sajindongnae/component/post_card.dart';
import 'package:flutter_application_sajindongnae/models/post_model.dart';

class ListScreen extends StatefulWidget {
  const ListScreen({super.key});

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  final searchController = TextEditingController();

  // Firestore 연결 전 임시 데이터 (결과 확인용용)
  final List<PostModel> postList = List.generate(
    10,
    (index) => PostModel(
      postId: 'post_$index',
      userId: 'user_$index',
      nickname: '사용자$index',
      profileImageUrl: 'https://via.placeholder.com/150',
      category: '소니',
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
      appBar: AppBar(title: Text('게시글 목록')),
      body: Column(
        children: [
          SearchBarWidget(
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
    );
  }
}
