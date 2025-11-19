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
import 'package:flutter_application_sajindongnae/models/chat_list_model.dart';

import 'package:flutter_application_sajindongnae/services/request_service.dart';
import 'package:flutter_application_sajindongnae/screen/photo/request_write.dart';
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

  // 의뢰글 서비스
  final RequestService _requestService = RequestService();

  int markCount = 0;

  GoogleMapController? _requestDetailMapController;
  Set<Circle> circles = {};

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _requestDetailMapController?.dispose();
  }
  // 북마크 상태를 토글하고 Firestore에 반영
  Future<void> _toggleBookmark(RequestModel request) async {
    if (_myUid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인이 필요합니다.')),
      );
      return;
    }

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
  Widget build(BuildContext context) {

    final initialRequest = widget.request;
    final requestId = initialRequest.requestId;

    return StreamBuilder<RequestModel?>(
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

        final request = snapshot.data!;
        final isOwner = request.uid == FirebaseAuth.instance.currentUser?.uid;

        final bookmarkedBy = request.bookmarkedBy ?? <String>[];
        final isMarkedRequest =
            _myUid != null && bookmarkedBy.contains(_myUid);

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
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ReportPostScreen(
                            postId: request.requestId,    
                            postType: 'requests',        
                            reasons: [
                              '무단 사진/자료 도용',
                              '저작권 침해',
                              '불법 내용',
                              '욕설/혐오 표현',
                              '기타',
                            ],
                          ),
                        ),
                      );

                      break;
                    case MoreAction.edit:
                      dev.log('수정하기 선택됨');
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RequestWriteScreen(
                            existingRequest: request, // StreamBuilder에서 받은 최신 request
                          ),
                        ),
                      );
                      break;
                    case MoreAction.delete:
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
                        Navigator.of(context).pop();
                      }
                      break;
                  }
                },
              ),
            ],
          ),

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

                const SizedBox(height: 20),
                /* 컴퓨터 잘 안돌아가는 사람들은 이거 주석 빼고 사용하기
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
                ),*/
                // 컴퓨터 잘 돌아가면 이걸로 쓰기 (반투명 원이 있는 버전)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    height: 160,
                    width: double.infinity,
                    child: GoogleMap(
                      liteModeEnabled: true, // 👈 StaticMap 느낌 나게 가볍게
                      initialCameraPosition: CameraPosition(
                        target: LatLng(
                          request.position.latitude,
                          request.position.longitude,
                        ),
                        zoom: 12,
                      ),
                      onMapCreated: (c) => _requestDetailMapController = c,
                      myLocationEnabled: false,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      markers: {
                        Marker(
                          markerId: const MarkerId('request_detail'),
                          position: LatLng(
                            request.position.latitude,
                            request.position.longitude,
                          ),
                          infoWindow: const InfoWindow(title: '의뢰 위치'),
                          icon: BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueGreen,
                          ),
                        ),
                      },
                      circles: {
                        Circle(
                          circleId: const CircleId('request_circle'),
                          center: LatLng(
                            request.position.latitude,
                            request.position.longitude,
                          ),
                          radius: 2500, // 2.5km
                          fillColor: const Color.fromARGB(54, 116, 235, 106),
                          strokeColor: const Color.fromARGB(54, 116, 235, 106),
                          strokeWidth: 1,
                        ),
                      },
                    ),
                  ),
                ),

              ],
            ),
          ),

          bottomNavigationBar: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 18),
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
                      onPressed: () => _toggleBookmark(request),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      request.price == 0
                          ? '무료 의뢰'
                          : '${request.price}원',
                    ),
                  ],
                ),
                const Spacer(),

                Row(
                  children: [
                    Text(
                      request.status ?? '의뢰중',
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(width: 12),

                  ElevatedButton(
                    onPressed: () async {
                      
                      dev.log('수락/대화중인 채팅으로 이동하기 버튼 클릭됨');

                      final currentUid =
                          FirebaseAuth.instance.currentUser?.uid;
                      if (currentUid == null) return;
                      /*
                      // 본인 의뢰면 채팅 리스트를 보여주도록 하고 있기 때문에 불필요
                      if (isOwner) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('본인 의뢰는 수락할 수 없습니다.'),
                          ),
                        );
                        return;
                      }   */

                      if(isOwner){
                          
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatListScreen(  
                              ),
                            ),
                          );
                        }
                        else{
                          final db = FirebaseFirestore.instance;
                          final requesterUid = request.uid;

                          // 항상 동일한 chatRoomId 생성
                          final sortedIds = [currentUid, requesterUid]..sort();
                          final chatRoomId = sortedIds.join('_');

                          final chatRef = db.collection('chats').doc(chatRoomId);
                          final existingChat = await chatRef.get();

                          if (!existingChat.exists) {
                            // 신규 채팅방 생성
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

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatDetailScreen(
                                  request: request,
                                  chatRoom: newChatRoom,   // ⭐ 여기!!!!
                                ),
                              ),
                            );

                          } else {
                            // 기존 채팅방 읽기
                            final existingRoom =
                                ChatRoom.fromDoc(existingChat);

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatDetailScreen(
                                  request: request,
                                  chatRoom: existingRoom,   // ⭐ 정답!
                                ),
                              ),
                            );
                          }
                        }
                    },
                    style: ButtonStyle(
                      backgroundColor:
                          WidgetStateProperty.resolveWith<Color>(
                        (Set<WidgetState> states) {
                          if (states.contains(WidgetState.pressed)) {
                            return const Color.fromARGB(255, 198, 211, 178);
                          }
                          return const Color(0xFFDDECC7);
                        },
                      ),
                      shape: WidgetStateProperty.all<
                          RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                    ),
                    child: Text(
                      isOwner ? '대화중인 채팅' : '수락하기',
                      style: const TextStyle(color: Colors.black),
                    ),
                  ),
                 ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// 작성 시간 포맷 함수
String _getFormattedTime(DateTime time) {
  return '${time.year}/${_twoDigits(time.month)}/${_twoDigits(time.day)} '
      '${_twoDigits(time.hour)}:${_twoDigits(time.minute)}';
}

String _twoDigits(int n) => n.toString().padLeft(2, '0');
