import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ListScreen extends StatefulWidget {
  const ListScreen({super.key});
  
  @override
  State<ListScreen> createState() => _ListScreenState();
} 

class _ListScreenState extends State<ListScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('게시글 목록'),),
      body: Container(
        padding: const EdgeInsets.fromLTRB(5, 0, 5, 10),
        child: ListView.builder(
          itemCount: 10,
          itemBuilder: (context, Index) {
            return GestureDetector(
              child: Card(
                child: ListTile(
                  leading: Text('101'),
                  title: Text('게시글 제목'),
                  subtitle: Text('작성자'),
                )
              ),
              onTap: (){
                Navigator.pushNamed(context, '/post/read');
              },
            );
          }
        ), 
      ),
      );
  }
  
}