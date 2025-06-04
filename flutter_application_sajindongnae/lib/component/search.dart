import 'package:flutter/material.dart';

class SearchBarWidget extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  const SearchBarWidget({
    super.key,
    required this.controller,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          hintText: '검색어를 입력하세요',
          suffixIcon: IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              print('검색 버튼 클릭');
            },
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none, // 테두리 없애기
          ),
          filled: true,
          fillColor: const Color.fromARGB(255, 245, 245, 244),
        ),
      ),
    );
  }
}
