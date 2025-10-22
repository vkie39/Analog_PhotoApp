import 'package:flutter/material.dart';
import '../models/request_model.dart';

class RequestCard extends StatelessWidget {
  final RequestModel request;
  final VoidCallback? onTap;  // request 카드 클릭시 실행할 동작

  const RequestCard({super.key, required this.request, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,    // 왼쪽 정렬
          children: [
            // 텍스트 영역
            Expanded(                                      // Expanded는 프로필 이미지로 사용한 공간 제외 모두 쓰라는 의미
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 제목
                  Text(
                    request.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height:4),

                  // 위치, 시간
                  Row(
                    children: [
                      Text(
                        request.location!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color.fromARGB(255, 120, 119, 119),
                        ),
                      ),
                      Text('  |  ',
                        style: const TextStyle(
                            fontSize: 12,
                            color: Color.fromARGB(255, 120, 119, 119),
                          ),
                      ),
                      Text(
                        _getTimeAgo(request.dateTime),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color.fromARGB(255, 120, 119, 119),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height:4),

                  // 가격
                  Text(
                    request.price == 0 ?  '무료 의뢰' : '${request.price}원',
                    style: const TextStyle(
                      fontSize: 12,
                    ),
                  ), 

                ],
              )
            ),

            // 유료 표시 아이콘
            if(request.price != 0)
              Padding(
                padding: const EdgeInsets.only(left:8.0),
                child: Image.asset(
                  'assets/icons/parrot.png',
                  width: 50,
                ),
              ),
            const SizedBox(width: 10),
            
          ],
        ),
        ),
    );
  }


  // 글 작성 시간 포맷 
  static String _getTimeAgo(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return '방금 전';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    return '${diff.inDays}일 전';
  }

}


