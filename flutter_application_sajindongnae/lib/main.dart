import 'package:flutter/material.dart';
import 'screen/post/list.dart'; // 리스트 페이지 import

void main() {
  runApp(MaterialApp(
    home: MainPage(), 
  ));
}

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "메인 페이지입니다",
            style: TextStyle(fontSize: 20),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ListScreen()),
              );
            },
            child: const Text('게시판으로 이동'),
          ),
        ],
      ),
    );
  }
}