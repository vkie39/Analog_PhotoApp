import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:developer';
import 'package:flutter_application_sajindongnae/screen/photo/photo_sell.dart';
import 'package:flutter_application_sajindongnae/models/photo_model.dart';


class SellDetailScreen extends StatelessWidget {
  final PhotoModel photo;

  // 임시 유저 정보
  final String currentUserUid = 'test_uid';

  SellDetailScreen({super.key, required this.photo});

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('yyyy/MM/dd').format(photo.dateTime);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 사진
            AspectRatio(
              aspectRatio: 4 / 3,
              child: Image.network(
                photo.imageUrl,
                fit: BoxFit.cover,
              ),
            ),

            // 작가 정보
            ListTile(
              leading: CircleAvatar(
                backgroundImage: NetworkImage(photo.profileImageUrl),
              ),
              title: Text(photo.nickname),
            ),

            const Divider(),

            // 제목
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                photo.title,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),

            // 날짜
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                formattedDate,
                style: const TextStyle(color: Colors.grey),
              ),
            ),

            // 태그 (카테고리 기반)
            if (photo.category != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Wrap(
                  spacing: 8.0,
                  children: photo.category!.split(',').map((tag) {
                    return Chip(label: Text(tag));
                  }).toList(),
                ),
              ),

            // 장소
            if (photo.location != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      photo.location!,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),

            // 내용
            if (photo.description != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  photo.description!,
                  style: const TextStyle(fontSize: 14),
                ),
              ),

            const SizedBox(height: 8),

            // 좋아요 + 가격 + 구매버튼
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 좋아요
                  Row(
                    children: [
                      const Icon(Icons.favorite_border),
                      const SizedBox(width: 4),
                      Text('${photo.price.toString()} 원'),
                    ],
                  ),
                  // 구매 버튼
                  ElevatedButton(
                    onPressed: () {
                      log('구매하기 버튼 클릭됨');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[200],
                    ),
                    child: const Text('구매하기'),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
