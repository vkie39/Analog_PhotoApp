/*
 *  photo_sell.dart 에서 requestId를 받아와 의뢰글에 대한 상세 페이지를 보여주는 페이지.
 * 
 *  - requestId를 통해 상세페이지 정보를 firestore에 실시간으로 요청 -> streambuilder로 실시간 반영
 */

import 'dart:developer' as dev;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// 모델 import
import 'package:flutter_application_sajindongnae/models/request_model.dart';
import 'package:flutter_application_sajindongnae/models/chat_list_model.dart';

// 채팅 상세 페이지 import
import 'package:flutter_application_sajindongnae/screen/chat/chat_detail.dart';

enum MoreAction { report, edit, delete }

class RequestDetailScreen extends StatefulWidget {
  final RequestModel request;
  const RequestDetailScreen({super.key, required this.request});

  @override
  State<RequestDetailScreen> createState() => RequestDetailScreenState();
}

class RequestDetailScreenState extends State<RequestDetailScreen> {
  static const String _googleApiKey = 'AIzaSyD08a7ITr6A8IgDYt4zDcmeXHvyYKhZrdE'; // TODO: 여긴 나중에 보안을 위해 수정해야 함
  
  // 현재 로그인한 사용자 uid
  String? get _myUid => FirebaseAuth.instance.currentUser?.uid; 

  // widget 접근 편의를 위한 getter
  RequestModel get request => widget.request;

  // 북마크 상태를 나타내는 변수
  bool isMarkedRequest = false;
  int markCount = 0;

  GoogleMapController? _requestDetailMapController;
  Set<Circle> circles = {};

  @override
  void initState(){
    super.initState();
  }
  
  @override
  void dispose(){
    super.dispose();
    _requestDetailMapController?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // [수정됨] 실제 로그인한 사용자 uid와 작성자 uid 비교
    final isOwner = request.uid == FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        title: const Text('의뢰글', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        scrolledUnderElevation: 0,

        // 더보기 버튼
        // uid를 확인하여 isOwner일 경우 '수정하기', '삭제하기' 버튼을 보여줌. isOwner가 아니면 '신고하기'
        actions: [
          PopupMenuButton<MoreAction>(
            icon: const Icon(Icons.more_vert),  // 점 3개 아이콘 명시
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            color: Colors.white,              
            elevation: 6,                       
            position: PopupMenuPosition.under,  

            // 메뉴 항목. 작성자와 비작성자에 따라 다르게 표시
            itemBuilder: (BuildContext context) {
              if (isOwner) {
                return const [
                  PopupMenuItem<MoreAction>(
                    value: MoreAction.edit,
                    child: Text('수정하기'),
                  ),
                  PopupMenuDivider(height: 5), 
                  PopupMenuItem<MoreAction>(
                    value: MoreAction.delete,
                    child: Text('삭제하기'),
                  ),
                ];
              } else {
                return const [
                  PopupMenuItem<MoreAction>(
                    value: MoreAction.report,
                    child: Text('신고하기'),
                  ),
                ];
              }
            },

            // 메뉴 항목 선택 시 처리
            onSelected: (MoreAction action) async{
              switch (action) {
                case MoreAction.report:
                  dev.log('신고하기 선택됨');
                  break;
                case MoreAction.edit:
                  dev.log('수정하기 선택됨');
                  break;
                case MoreAction.delete:
                  dev.log('삭제하기 선택됨');
                  final shouldDelete = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(                            
                        borderRadius: BorderRadius.circular(16),
                      ),
                      backgroundColor: Colors.white,                          
                      title: const Text('정말로 이 의뢰글을 삭제하시겠습니까?'),     
                      content: const Text('삭제 후에는 복구할 수 없습니다.'),       
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('취소', style: TextStyle(color: Colors.black)),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('삭제', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                  if (shouldDelete == true) {
                    dev.log('삭제 로직 실행됨');
                    Navigator.of(context).pop(); 
                  }
                  break;
              }
            },
          ),
        ],
      ),

      // 의뢰글 작성자 정보와 작성 내용
      body: Padding(
        padding: const EdgeInsets.all(1.0),
        child: ListView( // 스크롤 가능
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          children: [
            Row(
              children: [
                // 프로필 이미지
                CircleAvatar(
                  backgroundImage: NetworkImage(request.profileImageUrl), 
                  radius: 20,
                ),
                const SizedBox(width: 10),

                // 의뢰 정보 (의뢰자 닉네임, 의뢰글 작성 시간)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 닉네임
                    Text(request.nickname, 
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    // 작성 시간
                    Text(
                      _getFormattedTime(request.dateTime),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
                const Spacer(),
              ],
            ),

            const Divider(height: 32, thickness: 0.5, color: Color.fromARGB(255, 180, 180, 180)),
            const SizedBox(height: 10),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 의뢰글 제목
                  Text(request.title!, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  // 의뢰글 내용
                  Text(request.description!, style: const TextStyle(fontSize: 18)),                    
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Divider(height: 32, thickness: 0.5, color: Color.fromARGB(255, 180, 180, 180)),
            const SizedBox(height: 10),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child:Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                // 위치 아이콘 및 텍스트 
                children: [
                  const Icon(Icons.location_on, color: Color.fromARGB(255, 133, 133, 133)),
                  const SizedBox(width: 5),
                  Text(request.location!, style: const TextStyle(fontSize: 15, color: Color.fromARGB(255, 133, 133, 133)))
                ],
              ),
            ),

            const SizedBox(height: 20), 
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                height: 160,
                width: double.infinity,
                child: Image.network(
                  'https://maps.googleapis.com/maps/api/staticmap'
                  '?center=${request.position.latitude},${request.position.longitude}'
                  '&zoom=15'
                  '&size=600x300'
                  '&maptype=roadmap'
                  '&markers=color:green%7C${request.position.latitude},${request.position.longitude}'
                  '&key=$_googleApiKey',
                  fit:BoxFit.cover,
                ),
              ),
            ),
          ],
        ),
      ),

      // 북마크 + 가격 + 수락버튼
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 18),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween, 
          children: [
            // 북마크
            Row(
              children: [
                // 북마크 아이콘
                IconButton(
                  icon:Icon(
                    isMarkedRequest? Icons.bookmark : Icons.bookmark_border, 
                    size: 30,
                    color: isMarkedRequest
                      ? const Color.fromARGB(255, 102, 204, 105)
                      : const Color.fromARGB(255, 161, 161, 161),
                  ) ,
                  onPressed: () {
                    dev.log('북마크 버튼 클릭됨');
                    setState(() {
                      isMarkedRequest = !isMarkedRequest; 
                    });
                    // TODO : DB에 좋아요 상태 업데이트 로직 추가
                  },
                ),
                const SizedBox(width: 4),
                Text(request.price == 0 ?  '무료 의뢰' : '${request.price}원',style: const TextStyle()),
              ],
            ),

            // [수정됨] 구매(수락) 버튼
            ElevatedButton(
              onPressed: () async {
                dev.log('수락하기 버튼 클릭됨');

                // [추가됨] 로그인 사용자 확인
                final currentUid = FirebaseAuth.instance.currentUser?.uid;
                if (currentUid == null) {
                  dev.log('로그인이 필요합니다.');
                  return;
                }

                // [추가됨] Firestore 및 채팅방 생성 로직
                final db = FirebaseFirestore.instance;
                final requesterUid = request.uid;

                // 두 UID를 정렬하여 항상 같은 chatRoomId를 생성
                final sortedIds = [currentUid, requesterUid]..sort();
                final chatRoomId = sortedIds.join('_');

                final chatRef = db.collection('chats').doc(chatRoomId);
                final existingChat = await chatRef.get();

                if (!existingChat.exists) {
                  final newChatRoom = ChatRoom(
                    chatRoomId: chatRoomId,
                    participants: [currentUid, requesterUid],
                    requestId: request.requestId,
                    lastMessage: '',
                    lastSenderId: '',
                    lastTimestamp: DateTime.now(),
                    requesterNickname: request.nickname,
                    requesterProfileImageUrl: request.profileImageUrl,
                  );

                  await chatRef.set(newChatRoom.toMap());
                  dev.log('새 채팅방 생성 완료: $chatRoomId');
                } else {
                  dev.log('기존 채팅방 존재: $chatRoomId');
                }

                // [추가됨] 채팅 상세 화면으로 이동
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatDetailScreen(request: request),
                  ),
                );
              },
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith<Color>(
                  (Set<WidgetState> states) {
                    if (states.contains(WidgetState.pressed)) {
                      return const Color.fromARGB(255, 198, 211, 178);
                    }
                    return const Color(0xFFDDECC7);
                  },
                ),
                shape: WidgetStateProperty .all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
              ),
              child: const Text('수락하기', style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }
}

// 작성 시간 포맷 함수
String _getFormattedTime(DateTime time) {
  return '${time.year}/${_twoDigits(time.month)}/${_twoDigits(time.day)} '
         '${_twoDigits(time.hour)}:${_twoDigits(time.minute)}';
}

String _twoDigits(int n) => n.toString().padLeft(2, '0'); 
