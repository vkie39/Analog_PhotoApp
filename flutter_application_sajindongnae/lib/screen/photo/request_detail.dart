/*
 *  photo_sell.dart 에서 requestId를 받아와 의뢰글에 대한 상세 페이지를 보여주는 페이지.
 * 
 *  - requestId을 통해 상세페이지 정보를 firestore에 실시간으로 요청 -> streambuilder로 실시간 반영
 */

import 'dart:developer' as dev;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:flutter_application_sajindongnae/models/request_model.dart';
import 'package:flutter_application_sajindongnae/screen/photo/location_select.dart';
import 'package:flutter_application_sajindongnae/models/location_model.dart';
import 'package:flutter_application_sajindongnae/screen/chat/chat_detail.dart';

enum MoreAction { report, edit, delete }

/*  TODO : 실제 request 컬렉션이 firestore에 반영되면 이걸로 수정

class RequestDetailScreen extends StatelessWidget {
  final String requestId;                                               // firestore에서 실시간으로 detail페이지 받아올 때는 request자체가 아니라 requestId로 페이지 요청
  const RequestDetailScreen({super.key, required this.requestId}); 
  
  
  @override
  Widget build(BuildContext context) {
    // 현재 로그인한 사용자 uid
    final String? myUid = FirebaseAuth.instance.currentUser?.uid; 
    
    // requests 컬렉션에서 ID가 requestId인 것을 찾아 docRef에 넣기
    final docRef = FirebaseFirestore.instance
           .collection('requests')   // TODO : 실제 컬렉션 이름으로 수정해야 함
           .doc(requestId);

    // StreamBuilder로 실시간으로 수정사항을 반영
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: docRef.snapshots(),
      builder: (context, snap){
        if (snap.connectionState == ConnectionState.waiting){
          return const Scaffold(body: Center(child: CircularProgressIndicator(),)); // 로딩중일 때 처리
        }
        if (!snap.hasData || !snap.data!.exists){
          return const Scaffold(body: Center(child: Text('의뢰글을 찾을 수 없어요.'),));
        }

      final requestData = snap.data!.data()!;
      final ownerUid = (requestData['uid'] as String?) ?? '';
      final ownerNickname = (requestData['nickname'] as String?) ?? '';
      final profile = (requestData['profileImageUrl'] as String?) ?? '';
      final title = (requestData['title'] as String?) ?? '';
      final description = (requestData['description'] as String?) ?? '';
      final price = (requestData['price'] is num) ? (requestData['price'] as num).toInt() : 0;
      final location = (requestData['location'] as String?) ?? '';
      final dateTime = (requestData['dateTime']);
      final bookmarkedBy = (requestData['bookmarkedBy'] as List?)?.cast<String>() ?? const<String>[];

      final isOwner = (myUid != null) && (myUid == ownerUid);
      final isMarkedRequest = (myUid != null) && (bookmarkedBy.contains(myUid)); 
      final markCount = bookmarkedBy.length;


      return Scaffold(
        backgroundColor: Colors.white,

        appBar: AppBar(
          title: const Text('의뢰글', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),),
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
              color: Colors.white,              // 메뉴 배경색   
              elevation: 6,                       // 그림자 깊이
              position: PopupMenuPosition.under,  // 메뉴가 버튼 아래에 나타나도록 설정

              // 메뉴 항목. 작성자와 비작성자에 따라 다르게 표시
              itemBuilder: (BuildContext context) {
                if (isOwner) {
                  return const [
                    PopupMenuItem<MoreAction>(
                      value: MoreAction.edit,
                      child: Text('수정하기'),
                    ),
                    PopupMenuDivider(height: 5,), // 구분선

                    PopupMenuItem<MoreAction>(
                      value: MoreAction.delete,
                      child: Text('삭제하기'),
                    ),
                  ];
                }
                else {
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
                    // 신고하기 로직 추가
                    break;
                  case MoreAction.edit:
                    dev.log('수정하기 선택됨');
                    // 수정하기 로직 추가
                    Navigator.of(context).push(    // 한 번 선언후 바꾸지 않는 값이라 final
                      MaterialPageRoute(builder: (_) => UpdateRequestScreen(requestId: requestId)),
                    );
                    break;
                  case MoreAction.delete:
                    dev.log('삭제하기 선택됨');
                    // 삭제 확인 다이얼로그 표시
                    final shouldDelete = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        shape: RoundedRectangleBorder(                            // 모서리 둥글게
                          borderRadius: BorderRadius.circular(16),
                        ),
                        backgroundColor: Colors.white,                          // 배경색
                        title: const Text('정말로 이 의뢰글을 삭제하시겠습니까?'),     // 제목
                        content: const Text('삭제 후에는 복구할 수 없습니다.'),       // 내용
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
                    // 사용자가 삭제를 확인했을 때 삭제 로직 실행
                    if (shouldDelete == true) {
                      dev.log('삭제 로직 실행됨');
                      // 실제 삭제 로직 추가 await PhotoService.deleteRequest(request);
                      Navigator.of(context).pop(); // 삭제 후 이전 화면으로 돌아감
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
                      backgroundImage: NetworkImage(profile), 
                      radius: 20,
                    ),
                    const SizedBox(width: 10),

                    // 의뢰 정보 (의뢰자 닉네임, 의뢰글 작성 시간)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 닉네임
                        Text(ownerNickname, 
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14)),
                        // 작성 시간
                        Text(
                          _getFormattedTime(dateTime),
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
                      Text(title!, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      // 의뢰글 내용
                      Text(description!, style: const TextStyle(fontSize: 18)),                    
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
                      Icon(Icons.location_on, color: const Color.fromARGB(255, 133, 133, 133),),
                      SizedBox(width: 5,),
                      Text(location!, style: const TextStyle(fontSize: 15, color: Color.fromARGB(255, 133, 133, 133)))
                    ],
                  ),
                ),
              ],
            ),
        ),

        // 북마크 + 가격 + 수락버튼
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween, // 시작과 끝에 위젯을 배치하고 가운데 공간 확보
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
                        ? const Color.fromARGB(255, 102, 204, 105)         // 좋아요 눌렀을 때 색상
                        : const Color.fromARGB(255, 161, 161, 161),        // 좋아요 안눌렀을 때 색상
                    ) ,
                    onPressed: () async{
                      if (myUid == null){
                        // TODO : 로그인 필요하다고 알려줘야 함
                      }
                      await docRef.update({
                        'bookmarkedBy' : isMarkedRequest
                        ? FieldValue.arrayRemove([myUid])        // 북마크한 상태에서 클릭 -> 북마크 해제
                        : FieldValue.arrayUnion([myUid])         // 북마크 no 상태에서 클릭 -> 북마크 
                      });
                    },
                  ),
                  const SizedBox(width: 4),
                  Text(price == 0 ?  '무료 의뢰' : '${price}원',style: const TextStyle()),
                ],
              ),

              // 구매 버튼
              ElevatedButton(
                onPressed: () {
                  dev.log('수락하기 버튼 클릭됨');
                  // TODO : 수락하기 로직 추가 (의뢰자와의 1:1채팅 페이지로 이동 등)
                },
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith<Color>(
                    (Set<WidgetState> states) {
                      if (states.contains(WidgetState.pressed)) {
                        return const Color.fromARGB(255, 198, 211, 178);  // 눌렀을 때 진하게
                      }
                      return const Color(0xFFDDECC7);                     // 기본색
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

    });
  }
}
*/

class RequestDetailScreen extends StatefulWidget {
  final RequestModel request;
  // => final String requestId;  firestore에서 실시간으로 detail페이지 받아올 때는 request자체가 아니라 requestId로 페이지 요청
  const RequestDetailScreen({
    super.key,
    required this.request,
  }); // => required this.requestId

  @override
  State<RequestDetailScreen> createState() => RequestDetailScreenState();
}

class RequestDetailScreenState extends State<RequestDetailScreen> {
  static const String _googleApiKey =
      'AIzaSyD08a7ITr6A8IgDYt4zDcmeXHvyYKhZrdE'; // TODO: 여긴 나중에 보안을 위해 수정해야 함

  // 현재 로그인한 사용자 uid
  String? get _myUid => FirebaseAuth.instance.currentUser?.uid;

  // widget 접근 편의를 위한 getter (안쓰면 widget.photo로 접근해야 함)
  RequestModel get request => widget.request;
  // 북마크 상태를 나타내는 변수 (상태가 바뀌는 변수이기 때문에 State 클래스에 선언)
  bool isMarkedRequest =
      false; // TODO : DB와 연동하여 좋아요를 누른 사용자이면 카운트하지 말고 처음부터 좋아요 표시가 되어있어야 함
  int markCount = 0;

  GoogleMapController? _requestDetailMapController;
  Set<Circle> circles = {};

  @override
  void initState() {
    super.initState();
    _loadBookmarkState();
    //markCount = request.markCount;  // TODO : 의뢰글의 실제 mark 수를 연동해야 함
  }

  Future<void> _loadBookmarkState() async {
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
  }

  Future<void> _toggleBookmark() async {
    if (_myUid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인이 필요합니다.')),
      );
      return;
    }

    final docRef = FirebaseFirestore.instance
        .collection('requests')
        .doc(request.requestId);

    setState(() {
      isMarkedRequest = !isMarkedRequest;
    });

    await docRef.update({
      'bookmarkedBy': isMarkedRequest
          ? FieldValue.arrayUnion([_myUid])
          : FieldValue.arrayRemove([_myUid]),
    });
  }

  @override
  void dispose() {
    super.dispose();
    _requestDetailMapController?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = request.uid == _myUid;

    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        title: const Text(
          '의뢰글',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        scrolledUnderElevation: 0,

        // 더보기 버튼
        // uid를 확인하여 isOwner일 경우 '수정하기', '삭제하기' 버튼을 보여줌. isOwner가 아니면 '신고하기'
        actions: [
          PopupMenuButton<MoreAction>(
            icon: const Icon(Icons.more_vert), // 점 3개 아이콘 명시
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            color: Colors.white, // 메뉴 배경색
            elevation: 6, // 그림자 깊이
            position: PopupMenuPosition.under, // 메뉴가 버튼 아래에 나타나도록 설정
            // 메뉴 항목. 작성자와 비작성자에 따라 다르게 표시
            itemBuilder: (BuildContext context) {
              if (isOwner) {
                return const [
                  PopupMenuItem<MoreAction>(
                    value: MoreAction.edit,
                    child: Text('수정하기'),
                  ),
                  PopupMenuDivider(height: 5), // 구분선

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
            onSelected: (MoreAction action) async {
              switch (action) {
                case MoreAction.report:
                  dev.log('신고하기 선택됨');
                  // 신고하기 로직 추가
                  break;
                case MoreAction.edit:
                  dev.log('수정하기 선택됨');
                  // 수정하기 로직 추가
                  break;
                case MoreAction.delete:
                  dev.log('삭제하기 선택됨');
                  // 삭제 확인 다이얼로그 표시
                  final shouldDelete = await showDialog<bool>(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          shape: RoundedRectangleBorder(
                            // 모서리 둥글게
                            borderRadius: BorderRadius.circular(16),
                          ),
                          backgroundColor: Colors.white, // 배경색
                          title: const Text('정말로 이 의뢰글을 삭제하시겠습니까?'), // 제목
                          content: const Text('삭제 후에는 복구할 수 없습니다.'), // 내용
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text(
                                '취소',
                                style: TextStyle(color: Colors.black),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text(
                                '삭제',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                  );
                  // 사용자가 삭제를 확인했을 때 삭제 로직 실행
                  if (shouldDelete == true) {
                    dev.log('삭제 로직 실행됨');
                    // 실제 삭제 로직 추가 await PhotoService.deleteRequest(request);
                    Navigator.of(context).pop(); // 삭제 후 이전 화면으로 돌아감
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
          // 스크롤 가능
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
                    Text(
                      request.nickname,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
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
                  // 의뢰글 제목
                  Text(
                    request.title!,
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // 의뢰글 내용
                  Text(
                    request.description!,
                    style: const TextStyle(fontSize: 18),
                  ),
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
                // 위치 아이콘 및 텍스트
                children: [
                  Icon(
                    Icons.location_on,
                    color: const Color.fromARGB(255, 133, 133, 133),
                  ),
                  SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      request.location!,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color.fromARGB(255, 133, 133, 133),
                      ),
                      softWrap: true,
                      overflow: TextOverflow.visible,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20), // 위치 입력칸과 등록 버튼 사이 간격
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
          mainAxisAlignment:
              MainAxisAlignment.spaceBetween, // 시작과 끝에 위젯을 배치하고 가운데 공간 확보
          children: [
            // 북마크
            Row(
              children: [
                // 북마크 아이콘
                IconButton(
                  icon: Icon(
                    isMarkedRequest ? Icons.bookmark : Icons.bookmark_border,
                    size: 30,
                    color: isMarkedRequest
                        ? const Color.fromARGB(255, 102, 204, 105)
                        : const Color.fromARGB(255, 161, 161, 161),
                  ),
                  onPressed: () async {
                    dev.log('북마크 버튼 클릭됨');

                    if (_myUid == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('로그인이 필요합니다.')),
                      );
                      return;
                    }

                    final docRef = FirebaseFirestore.instance
                        .collection('requests')
                        .doc(request.requestId);

                    setState(() {
                      isMarkedRequest = !isMarkedRequest; // UI는 먼저 토글
                    });

                    try {
                      await docRef.update({
                        'bookmarkedBy': isMarkedRequest
                            ? FieldValue.arrayUnion([_myUid]) // 북마크 추가
                            : FieldValue.arrayRemove([_myUid]), // 북마크 제거
                      });
                      dev.log('북마크 업데이트 성공');
                    } catch (e) {
                      dev.log('북마크 업데이트 실패: $e');
                      // 실패하면 UI 롤백
                      setState(() {
                        isMarkedRequest = !isMarkedRequest;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('북마크 업데이트에 실패했습니다.')),
                      );
                    }
                  },
                ),

                const SizedBox(width: 4),
                Text(
                  request.price == 0 ? '무료 의뢰' : '${request.price}원',
                  style: const TextStyle(),
                ),
              ],
            ),


            // 구매 버튼
            ElevatedButton(
              onPressed: () {
                dev.log('수락하기 버튼 클릭됨');
                // TODO : 수락하기 로직 추가 (의뢰자와의 1:1채팅 페이지로 이동 등)
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatDetailScreen(request: request),
                  ),
                );
              },
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith<Color>((
                  Set<WidgetState> states,
                ) {
                  if (states.contains(WidgetState.pressed)) {
                    return const Color.fromARGB(
                      255,
                      198,
                      211,
                      178,
                    ); // 눌렀을 때 진하게
                  }
                  return const Color(0xFFDDECC7); // 기본색
                }),
                shape: WidgetStateProperty.all<RoundedRectangleBorder>(
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

String _getFormattedTime(DateTime time) {
  return '${time.year}/${_twoDigits(time.month)}/${_twoDigits(time.day)} '
      '${_twoDigits(time.hour)}:${_twoDigits(time.minute)}';
}

String _twoDigits(int n) => n.toString().padLeft(2, '0'); // 두 자리 채워주는 함수