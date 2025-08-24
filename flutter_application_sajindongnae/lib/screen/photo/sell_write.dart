import 'package:flutter/material.dart';

// Form을 관리하기 위한 키 (입력칸이 빈칸인지, 숫자인지 확인하고 업로드 하는 용도)
final _formKey = GlobalKey<FormState>();

class SellWriteScreen extends StatelessWidget {
  const SellWriteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('사진 판매글 작성'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      
      backgroundColor: Colors.white,
      
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column( // 사진 업로드 버튼(창), 사진 정보 입력칸, 위치 입력칸, 카테고리 선택란, 등록 버튼

          crossAxisAlignment: CrossAxisAlignment.start,
          
          children: [
            // 사진 업로드 버튼
            ElevatedButton.icon(
              onPressed:(){
                //버튼 클릭시 이미지 선택
              },
              icon: const Icon(Icons.upload_rounded, size: 16, color: Colors.grey),
              label: const Text("사진 업로드"),
            ),

            // 사진 정보 입력칸(사진명, 가격, 추가 설명)

          ],



        ),
      ),
    );
  }
}
