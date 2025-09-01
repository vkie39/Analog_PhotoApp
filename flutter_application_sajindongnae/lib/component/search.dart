import 'package:flutter/material.dart';

class SearchBarWidget extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSearchPressed;
  final Widget? leadingIcon; // 👈 왼쪽 아이콘 (nullable로 선택적)

  const SearchBarWidget({
    super.key,
    required this.controller,
    this.onChanged,
    this.onSearchPressed,
    this.leadingIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 245, 245, 244),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          // 왼쪽 메뉴 아이콘 (선택적)
          if (leadingIcon != null) leadingIcon!,

          // 검색어 입력 필드
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                hintText: '검색어를 입력하세요',
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),

          // 검색 버튼 아이콘
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black54,),
            onPressed: onSearchPressed ?? () {
              print('검색 클릭');
            },
          ),
        ],
      ),
    );
  }
}
