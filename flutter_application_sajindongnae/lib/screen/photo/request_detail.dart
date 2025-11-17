/*
 *  photo_sell.dart 에서 requestId를 받아와 의뢰글에 대한 상세 페이지를 보여주는 페이지.
 * 
 *  - requestId를 통해 상세페이지 정보를 firestore에 실시간으로 요청 -> streambuilder로 실시간 반영
 */

    // ---------------------------------------------------------------------------------
    //
    // 함이 11/16일에 수정한 부분
    // : stream: _requestService.watchRequest(requestId), 로 전체 build를 감싸서 
    // : 표시되는 모든 내용을 실시간값으로 사용
    // : 리퀘스트 내용 변화를 실시간으로 감지하기 위해 수정함 (리퀘스트 상태 status등 감시)
    // : _loadBookmarkState 주석처리 (필요없음)
    // : final request = snapshot.data!;
    // : final isOwner = request.uid == FirebaseAuth.instance.currentUser?.uid;
    // 
    // ----------------------------------------------------------------------------------
    
import 'dart:developer' as dev;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// 모델 import
import 'package:flutter_application_sajindongnae/models/request_model.dart';
import 'package:flutter_application_sajindongnae/services/request_service.dart';
import 'package:flutter_application_sajindongnae/models/chat_list_model.dart';
import 'package:flutter_application_sajindongnae/screen/post/report.dart';

// 채팅 상세 페이지 import
import 'package:flutter_application_sajindongnae/screen/chat/chat_detail.dart';
import 'package:flutter_application_sajindongnae/screen/chat/chat_list.dart';


enum MoreAction { report, edit, delete }

class RequestDetailScreen extends StatefulWidget {
  final RequestModel request;
  const RequestDetailScreen({super.key, required this.request});

  @override
  State<RequestDetailScreen> createState() => RequestDetailScreenState();
}

class RequestDetailScreenState extends State<RequestDetailScreen> {
  static const String _googleApiKey =
      'AIzaSyD08a7ITr6A8IgDYt4zDcmeXHvyYKhZrdE'; // TODO: 여긴 나중에 보안을 위해 수정해야 함

  // 현재 로그인한 사용자 uid
  String? get _myUid => FirebaseAuth.instance.currentUser?.uid;

  // 실시간으로 바꾸며 제거 : widget 접근 편의를 위한 getter
  // RequestModel get request => widget.request;

  // 의뢰글 서비스 함수들이 들어있는 클래스 가져옴 RequestService
  final RequestService _requestService = RequestService();

  // 북마크 상태를 나타내는 변수
  // 실시간으로 바꾸며 제거 :bool isMarkedRequest = false;
  int markCount = 0;

  GoogleMapController? _requestDetailMapController;
  Set<Circle> circles = {};

  @override
  void initState() {
    super.initState();
    // 실시간으로 바꾸며 제거 : _loadBookmarkState();
  }
   
  // 실시간으로 바꾸며 제거 : Firestore에서 북마크 상태를 불러옴
  /*Future<void> _loadBookmarkState() async {
    if (_myUid == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('requests')
        .doc(request.requestId)
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      final bookmarkedBy = (data['bookmarkedBy'] as List?)?.cast<String>() ?? [];
      setState(() {
        isMarkedRequest = bookmarkedBy.contains(_myUid);
      });
    }
  }*/

  // 북마크 상태를 토글하고 Firestore에 반영
  Future<void> _toggleBookmark(RequestModel request) async {
    if (_myUid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인이 필요합니다.')),
      );
      return;
    }

    // 실시간으로 바꾸며 제거 : final docRef = FirebaseFirestore.instance.collection('requests').doc(request.requestId);
    /*
    setState(() {
      isMarkedRequest = !isMarkedRequest;
    });
    */
    try {
      await RequestService().toggleBookmark(request.requestId, _myUid!);
      dev.log('북마크 토글 완료');
    } catch (e) {
      dev.log('북마크 토글 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('북마크 업데이트에 실패했습니다.')),
      );
    }
  }

  @override
  void dispose() {
    super.dispose();
    _requestDetailMapController?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // [수정됨] 실제 로그인한 사용자 uid와 작성자 uid 비교
    // 실시간으로 바꾸며 제거 :final isOwner = request.uid == FirebaseAuth.instance.currentUser?.uid;
    
    final initialRequest = widget.request;      // 전 페이지에서 받아온 request
    final requestId = initialRequest.requestId; // 그 request의 ID를 requestId에 저장

    return StreamBuilder<RequestModel?>(        // requestId를 통해 실시간으로 해당 request에 대한 수정사항 반영
      stream: _requestService.watchRequest(requestId),
      builder: (context, snapshot) {
        // 로딩
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 삭제되었거나 없는 경우
        if (!snapshot.hasData || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('의뢰글'),
            ),
            body: const Center(
              child: Text('해당 의뢰글을 찾을 수 없습니다.'),
            ),
          );
        }

        // 항상 최신 Firestore 데이터를 사용
        final request = snapshot.data!;
        dev.log('request.status = "${request.status}" (${request.status.runtimeType})');
        final isOwner = request.uid == FirebaseAuth.instance.currentUser?.uid;

        // 북마크 여부도 실시간 데이터로 계산
        final bookmarkedBy = (request.bookmarkedBy ?? <String>[]); 
        final isMarkedRequest =                                    // 로그인 사용자가 해당 request에 북마크를 한 사용자인지 확인
            _myUid != null && bookmarkedBy.contains(_myUid);       // 북마크 했으면 true

        return Scaffold(
          backgroundColor: Colors.white,

          appBar: AppBar(
            title: const Text('의뢰글',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            centerTitle: true,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0.5,
            scrolledUnderElevation: 0,

            // 더보기 버튼
            // uid를 확인하여 isOwner일 경우 '수정하기', '삭제하기' 버튼을 보여줌. isOwner가 아니면 '신고하기'
            actions: [
              PopupMenuButton<MoreAction>(
                icon: const Icon(Icons.more_vert),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                color: Colors.white,
                elevation: 6,
                position: PopupMenuPosition.under,

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

                onSelected: (MoreAction action) async {
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
                              child: const Text('취소',
                                  style: TextStyle(color: Colors.black)),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('삭제',
                                  style: TextStyle(color: Colors.red)),
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
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: NetworkImage(request.profileImageUrl),
                      radius: 20,
                    ),
                    const SizedBox(width: 10),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(request.nickname,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14)),
                        Text(
                          _getFormattedTime(request.dateTime),
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                    const Spacer(),
                  ],
                ),

                const Divider(
                  height: 32,
                  thickness: 0.5,
                  color: Color.fromARGB(255, 180, 180, 180),
                ),
                const SizedBox(height: 10),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(request.title!,
                          style: const TextStyle(
                              fontSize: 25, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Text(request.description!,
                          style: const TextStyle(fontSize: 18)),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                const Divider(
                  height: 32,
                  thickness: 0.5,
                  color: Color.fromARGB(255, 180, 180, 180),
                ),
                const SizedBox(height: 10),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on,
                          color: Color.fromARGB(255, 133, 133, 133)),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          request.location!,
                          style: const TextStyle(
                              fontSize: 15,
                              color: Color.fromARGB(255, 133, 133, 133)),
                          softWrap: true,
                          overflow: TextOverflow.visible,
                        ),
                      ),
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
                      fit: BoxFit.cover,
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
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        isMarkedRequest ? Icons.bookmark : Icons.bookmark_border,
                        size: 30,
                        color: isMarkedRequest
                            ? const Color.fromARGB(255, 102, 204, 105)
                            : const Color.fromARGB(255, 161, 161, 161),
                      ),
                      onPressed:() => _toggleBookmark(request),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      request.price == 0 ? '무료 의뢰' : '${request.price}원',
                      style: const TextStyle(),
                    ),
                  ],
                ),
                // 현재 의뢰 상태 표시 - 텍스트
                Text(
                  request.status ?? '의뢰중', // 텍스트 자체를 트리거로 사용
                  style: const TextStyle(
                    color: Color.fromARGB(255, 0, 0, 0),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),

                ElevatedButton(
                  onPressed: () async {
                    dev.log('수락하기 버튼 클릭됨');

                    // 로그인 사용자 확인
                    final currentUid = FirebaseAuth.instance.currentUser?.uid;
                    if (currentUid == null) {
                      dev.log('로그인이 필요합니다.');
                      return;
                    }

                    // Firestore 및 채팅방 생성 로직
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
                    
                    // 채팅 상세 화면으로 이동
                    if(isOwner){                // 1. 의뢰 작성자일 경우 -> 채팅 리스트 화면으로 이동
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ChatListScreen()),
                      );
                    }
                    else{                       // 2. 의뢰 수락자일 경우 -> 채팅 화면으로 이동
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatDetailScreen(request: request),
                        ),
                      );
                    }
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
                    shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                  ),
                  child:
                    Text(
                      isOwner ? '대화중인 채팅' : '수락하기',
                      style: const TextStyle(color: Colors.black),
                    ),
                ),
              ],
            ),
          ),
        );
      }
    );
  }
}

// 작성 시간 포맷 함수
String _getFormattedTime(DateTime time) {
  return '${time.year}/${_twoDigits(time.month)}/${_twoDigits(time.day)} '
      '${_twoDigits(time.hour)}:${_twoDigits(time.minute)}';
}

String _twoDigits(int n) => n.toString().padLeft(2, '0');
