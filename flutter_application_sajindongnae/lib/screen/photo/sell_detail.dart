import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application_sajindongnae/screen/photo/photo_sell.dart';
import 'package:flutter_application_sajindongnae/models/photo_model.dart';

/// appBar 버튼에서 어떤 메뉴를 선택했는지 구분하기 위한 enum
enum MoreAction { report, edit, delete }

class SellDetailScreen extends StatefulWidget {
  final PhotoModel photo;
  const SellDetailScreen({super.key, required this.photo});

  // 임시 유저 정보 
  final String currentUserUid = 'dummy_uid';

  @override
  State<SellDetailScreen> createState() => _SellDetailScreenState();

}

class _SellDetailScreenState extends State<SellDetailScreen> {
  // widget 접근 편의를 위한 getter (안쓰면 widget.photo로 접근해야 함)
  PhotoModel get photo => widget.photo;
  String get currentUserUid => widget.currentUserUid;                 // 임시 유저 아이디
  bool isLikedPhoto = false;                                          // 좋아요 상태를 나타내는 변수 (상태가 바뀌는 변수이기 때문에 State 클래스에 선언)
  
  // 태그 리스트
  List<String> get tags => (photo.category ?? '')                     // null이면 빈 문자열 반환
                             .split(',')                              // 쉼표로 분리
                             .map((tag) => tag.trim())                // 각 태그의 앞뒤 공백 제거
                             .where((tag) => tag.isNotEmpty)          // 빈 문자열 제거
                             .toList();

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('yyyy/MM/dd').format(photo.dateTime);
    // 현재 로그인된 사용자가 작성한 판매글인지 확인 (uid 비교)
    final isOwner = photo.uid == currentUserUid;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,

        // 더보기 버튼 
        actions: [
          PopupMenuButton<MoreAction>(
            icon: const Icon(Icons.more_vert),  // 점 3개 아이콘 명시
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            color: Colors.white,              // 메뉴 배경색   
            elevation: 6,                       // 그림자 깊이
            position: PopupMenuPosition.under,  // 메뉴가 버튼 아래에 나타나도록 설정

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
                      title: const Text('정말로 이 판매글을 삭제하시겠습니까?'),     // 제목
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
                    // 실제 삭제 로직 추가
                    Navigator.of(context).pop(); // 삭제 후 이전 화면으로 돌아감
                  }
                  break;
              }
            },

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
          ),
        ],
      ),


      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 사진
            SizedBox(
              width: double.infinity,
              child: Image.asset(photo.imageUrl, fit: BoxFit.cover),
            ),

            const SizedBox(height: 10),

            // 작가 정보
            ListTile(
              leading: CircleAvatar(
                backgroundImage: NetworkImage(photo.profileImageUrl),
              ),
              title: Text(
                photo.nickname,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)
                ),
            ),

            const Divider(),

            // 제목
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                photo.title,
                style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
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

            // 태그
            if (tags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: SingleChildScrollView(                              // 태그 스크롤 (Wrap 사용시 태그가 많을 때 줄바꿈됨)
                  scrollDirection: Axis.horizontal,                        // 가로 스크롤
                  child: Row(
                    children: tags.map((tag) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ActionChip(                                              // 클릭 가능한 태그
                          label: Text(tag),                                             // 태그 텍스트
                          backgroundColor: Colors.white,                              // 태그 배경색
                          labelStyle: const TextStyle(color: Colors.black87),         // 태그 텍스트 색상
                          side: const BorderSide(color: Color(0xFFE0E0E0), width:1,), // 태그 테두리
                          onPressed: (){/*검색 기능 추가 가능*/},),
                      );
                    }).toList(),
                  ),
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
          ],
        ),
      ),

            // 좋아요 + 가격 + 구매버튼
            bottomNavigationBar: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween, // 시작과 끝에 위젯을 배치하고 가운데 공간 확보
                children: [
                  // 좋아요
                  Row(
                    children: [
                      // 좋아요 아이콘
                      IconButton(
                        icon:Icon(
                         isLikedPhoto? Icons.favorite : Icons.favorite_border, 
                         size: 30,
                         color: isLikedPhoto
                            ? const Color.fromARGB(255, 102, 204, 105)         // 좋아요 눌렀을 때 색상
                            : const Color.fromARGB(255, 161, 161, 161),        // 좋아요 안눌렀을 때 색상
                        ) ,
                        onPressed: () {
                          dev.log('좋아요 버튼 클릭됨');
                          setState(() {
                            isLikedPhoto = !isLikedPhoto;                        // 좋아요 상태 토글(업데이트)
                          });
                          // TODO : DB에 좋아요 상태 업데이트 로직 추가
                        },
                      ),
                      const SizedBox(width: 4),
                      Text('${photo.price.toString()} 원'),
                    ],
                  ),

                  // 구매 버튼
                  ElevatedButton(
                    onPressed: () {
                      dev.log('구매하기 버튼 클릭됨');
                      // TODO : 구매하기 로직 추가 (결제 페이지로 이동 등)
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
                    child: const Text('구매하기', style: TextStyle(color: Colors.black)),
                  ),
                ],
              ),
            ),
        );
  }
}