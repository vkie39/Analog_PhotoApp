import 'dart:developer' as dev;
import 'dart:io';
import 'dart:async'; 
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:flutter_application_sajindongnae/models/request_model.dart';
import 'package:flutter_application_sajindongnae/screen/photo/request_detail.dart';
import 'package:flutter_application_sajindongnae/screen/chat/chat_image_viewer.dart';
import 'package:flutter_application_sajindongnae/models/message_model.dart'; // [추가됨] Firestore Message 모델
import 'package:flutter_application_sajindongnae/services/image_service.dart';
import 'package:flutter_application_sajindongnae/services/request_service.dart'; 

import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';


import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';           // 권한



class ChatDetailScreen extends StatefulWidget {
  final RequestModel request; // 이전 화면에서 넘겨받음
  const ChatDetailScreen({super.key, required this.request});
  

  @override
  _ChatDetailScreen createState() => _ChatDetailScreen();
}

class _ChatDetailScreen extends State<ChatDetailScreen> {
  final RequestService _requestService = RequestService(); // 함 추가 11/16
  StreamSubscription<RequestModel?>? _requestSub;          // 함 추가 11/16
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _chatSub;

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String? get _myUid => FirebaseAuth.instance.currentUser?.uid;
  late bool _isOwner; // 리퀘스트 작성자가 아니라면 리퀘스트 상태변화를 할 수 없도록 함


  // Firestore 인스턴스 [추가됨]
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  // Firestore 실시간 메시지 목록
  List<Message> _messages = [];


  // 대화 상대방의 프로필을 표시하기 위한 변수
  String? _myProfileUrl;
  String? _otherProfileUrl;
  bool _isLoadingProfiles = true;
  
  // 결제하기 활성화 여부 검사용 (상대방이 보낸 사진이 하나라도 있으면 true가 됨)
  bool _canPay = false;
  bool _canDownload = false;


  // 채팅방 정보 [추가됨]
  late RequestModel _originalRequest;

  late final String _chatRoomId;
  late final String _requestId;
  late final String _requesterUid;
  late final String _requesterNickname;
  late  String _requestTitle;
  late  int _requestPrice;
  bool _isPaied = false;

  // 리퀘스트 상태(의뢰중, 거래중, 의뢰완료) 이건 request_model에 필드 만들면 수정해야 함
  String _requestStatement= '의뢰중';

  // 선택한 이미지 파일
  XFile? _originalImage;
  XFile? _selectedImage; 
  bool _cropping = false;
  late ImageService _imageService;

  // 기능 패널 on/off 제어 (카카오톡처럼 메뉴버튼 누르면 키보드 대신 패널 열림)
  bool _showPanel = false;
  final double _panelHeight = 260;

  void _hideKeyboard() => FocusScope.of(context).unfocus();

  void _togglePanel([bool? show]) {
    setState(() {
      _showPanel = show ?? !_showPanel;
    });
    if (_showPanel) _hideKeyboard(); // 패널 열릴 땐 키보드 닫기
  }
 
  @override
  void initState() {
    super.initState();

    _originalRequest = widget.request;
    _imageService = ImageService();

    _requestId = _originalRequest.requestId;
    _requesterUid = _originalRequest.uid;
    _requesterNickname = _originalRequest.nickname;
    _requestTitle = _originalRequest.title;
    _requestPrice = _originalRequest.price;
    _requestStatement = _originalRequest.status ?? '의뢰중';
    _isPaied = _originalRequest.isPaied;

    // [수정됨] 채팅방 ID 생성 규칙 (requestId로 고정)
    _chatRoomId = 'chat_${widget.request.requestId}';

    _ensureChatRoomExists();   // 채팅방 생성 확인 (가장 중요)
    // _loadRequest();         // 실시간으로 바꾸며 제거 : 의뢰글 정보 로드


    // 현재 사용자와 상대방 UID
    final otherUid = _requesterUid;
    final me = _myUid ?? 'dummy_me';
    _isOwner = _myUid == _requesterUid; 

    _canDownload = !_isOwner || _originalRequest.isPaied; // 수락자의 경우 조건 없이 사진 다운로드 가능
                                                          // 의뢰자의 경우 돈을 지불했을 때만 다운로드 가능


    // 의뢰글 실시간으로 가져옴
    _requestSub = _requestService.watchRequest(_requestId).listen((req) {
    if (req == null) return; // 삭제된 경우 등 방어
    if (!mounted) return;
    setState(() {
          _originalRequest = req;
          _requestTitle   = req.title;
          _requestPrice   = req.price;
          _requestStatement = req.status;  // 상태 필드
          _isPaied = req.isPaied;
        });
      });

        
    // 두 사용자 프로필 미리 로드
    _loadProfiles();


    // Firestore 메시지 스트림 구독
    _chatSub = _db
        .collection('chats')
        .doc(_chatRoomId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .listen((snapshot) {
      // 위젯이 이미 dispose된 상태면 더 이상 setState 하지 않도록 방어
      if (!mounted) return;

      final msgs = snapshot.docs.map((d) => Message.fromDoc(d)).toList();

      final myUid = _myUid;
      final hasOpponentImage = msgs.any((m) {
        if (!m.hasImage) return false;
        if (myUid == null) return true;
        return m.senderId != myUid;
      });

      setState(() {
        _messages = msgs;
        _canPay = hasOpponentImage;
      });


});

        
    
  }

  @override
  void dispose() {
     _requestSub?.cancel(); 
    _scrollController.dispose();
    _messageController.dispose();
    _chatSub?.cancel(); 
    super.dispose();
  }

  Future<void> _loadRequest() async {
  final snap = await FirebaseFirestore.instance
      .collection('requests')
      .doc(_requestId)
      .get();

  if (!snap.exists) return;

  final data = snap.data()!;
  final req = RequestModel.fromMap(data, snap.id);

  setState(() {
    _originalRequest = req;
    _requestTitle = req.title;
    _requestPrice = req.price;
    _requestStatement = req.status;   // 혹시 상태 표시할 경우
  });
}



  Future<void> _loadProfiles() async {
    try {
      final me = _myUid;
      final other = _requesterUid;

      // users 컬렉션 스키마 예시:
      // { uid, nickname, profileImageUrl, ... }
      Future<String?> getUrl(String uid) async {
        final snap = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        if (!snap.exists) return null;
        final data = snap.data()!;
        return (data['profileImageUrl'] as String?)?.trim().isEmpty == true
            ? null
            : data['profileImageUrl'] as String?;
      }

      String? myUrl;
      if (me != null) {
        myUrl = await getUrl(me);
      }
      final otherUrl = await getUrl(other);

      if (!mounted) return;
      setState(() {
        _myProfileUrl = myUrl;
        _otherProfileUrl = otherUrl;
        _isLoadingProfiles = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingProfiles = false);
      // 필요시 스낵바/로그 처리
      // dev.log('Failed to load profiles: $e');
    }
  }


  void _openRequestDetail() {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => RequestDetailScreen(request: widget.request),
    ),
  );
}


  // 메시지 전송 함수 [수정됨 → Firestore write로 변경]
  Future<void> _sendMessage() async {
    
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    await _ensureChatRoomExists();   // 없으면 만들어놓고 메세지 전송

    final senderId = _myUid ?? 'unknown';
    final messageData = {
      'senderId': senderId,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    };

    try {
      // Firestore에 메시지 추가
      await _db
          .collection('chats')
          .doc(_chatRoomId)
          .collection('messages')
          .add(messageData);

      // 채팅방의 최근 메시지 갱신
      await _db.collection('chats').doc(_chatRoomId).update({
        'participants': [_myUid, _requesterUid],
        'lastMessage': text,
        'lastSenderId': senderId,
        'lastTimestamp': FieldValue.serverTimestamp(),
      });

      _messageController.clear();
    } catch (e) {
      debugPrint('메시지 전송 오류: $e');
    }
  }


  // 메시지 실시간 구독 [추가됨]
  Stream<QuerySnapshot<Map<String, dynamic>>> _messageStream() {
    return _db
        .collection('chats')
        .doc(_chatRoomId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots();
  }


  void _appendImageMessage(XFile picked) async {
  final senderId = _myUid ?? 'unknown';
  await _ensureChatRoomExists();   // 없으면 만들어놓고 메세지 전송

  try {
    // 1) Firebase Storage 업로드
    final imageUrl = await _imageService.uploadChatImage(picked, _chatRoomId);

    // 2) Firestore에 메시지 저장
    await _db
        .collection('chats')
        .doc(_chatRoomId)
        .collection('messages')
        .add({
      'senderId': senderId,
      'text': null,
      'imageUrl': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 3) 채팅방 마지막 메시지 갱신
    await _db.collection('chats').doc(_chatRoomId).update({
      'lastMessage': '(이미지)',
      'lastSenderId': senderId,
      'lastTimestamp': FieldValue.serverTimestamp(),
    });
  } catch (e) {
    debugPrint('이미지 메시지 전송 오류: $e');
  }
}

// 채팅방이 없으면 생성하는 함수
Future<void> _ensureChatRoomExists() async {
  final docRef = _db.collection('chats').doc(_chatRoomId);
  final snapshot = await docRef.get();

  if (!snapshot.exists) {
    await docRef.set({
      'participants': [_myUid, _requesterUid],
      'createdAt': FieldValue.serverTimestamp(),
      'lastMessage': '',
      'lastSenderId': '',
      'lastTimestamp': FieldValue.serverTimestamp(),
    });
  }
}





 // =========================================================================== 
 // 채팅 메세지 위젯들
 // ===========================================================================

  // [프로필 사진] 위젯
  Widget _buildAvatar({required bool loginProfile}) {
    // 내 프로필을 안 보이고 싶다면 isMe일때 SizedBox.shrink() 리턴
    // isMe면 빈 공간 (말풍선 정렬을 맞춤)
    if (loginProfile) return const SizedBox(width: 36);

    final url = _otherProfileUrl;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6.0),
      child: CircleAvatar(
        radius: 16,
        backgroundColor: Colors.grey.shade300,
        backgroundImage: (url != null && url.isNotEmpty)
            ? NetworkImage(url)
            : null,
        child: (url == null || url.isEmpty)
            ? const Icon(Icons.person, size: 18, color: Colors.white)
            : null,
      ),
    );
  }
  
  // [말풍선] 위젯
Widget _buildBubble(BuildContext context, Message msg, bool isMe) {

  //Widget _buildBubble(Message msg, bool isMe) {

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      padding: const EdgeInsets.all(12.0),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.72,
      ),
      decoration: BoxDecoration(
        color: isMe ? Colors.lightGreen[200] : Colors.grey[300],
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(12),
          topRight: const Radius.circular(12),
          bottomLeft: isMe ? const Radius.circular(12) : const Radius.circular(0),
          bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // 텍스트 전송
          if (msg.hasText)
            Text(
              msg.text!,       // null 아님이 보장되는 경우만 !
              style: const TextStyle(fontSize: 15, color: Colors.black),
            ),
          if (msg.hasText && msg.hasImage) const SizedBox(height: 8),

          // 이미지 전송
          if (msg.hasImage)
            GestureDetector(
              
              onTap: () {
                // 1) Firestore에 올라간 네트워크 이미지 (imageUrl)
                if (msg.imageUrl != null && msg.imageUrl!.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatImageViewer(
                        imagePath: msg.imageUrl!,        // ✅ URL 그대로 넘김
                        isAsset: false,                  // 네트워크니까 false
                        heroTag: 'chat_image_${msg.id}',
                        photoOwnerNickname: _requesterNickname,
                        canDownload: _canDownload,
                      ),
                    ),
                  );
                  return;
                }
                // 2) (옵션) 아직 로컬 XFile을 쓰는 경우 대비 -> 나중에 지워도 됨
                if (msg.image != null) {
                  final isAsset = msg.image!.path.startsWith('assets/');
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatImageViewer(
                        imagePath: msg.image!.path,
                        isAsset: isAsset,
                        heroTag: 'chat_image_${msg.id}',
                        photoOwnerNickname: _requesterNickname,
                        canDownload: _canDownload,

                      ),
                    ),
                  );
                }
              },
                
              child: Hero(
                tag: 'chat_image_${msg.id}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: msg.imageUrl != null && msg.imageUrl!.startsWith('http')
                      // 1) 네트워크 이미지
                      ? Image.network(
                          msg.imageUrl!,
                          width: 200,
                          fit: BoxFit.cover,
                        )
                      // 2) 에셋 이미지
                      : (msg.image != null && msg.image!.path.startsWith('assets/'))
                          ? Image.asset(
                              msg.image!.path,
                              width: 200,
                              fit: BoxFit.cover,
                            )
                          // 3) 파일 이미지 (로컬 경로)
                          : (msg.image != null)
                              ? Image.file(
                                  File(msg.image!.path),
                                  width: 200,
                                  fit: BoxFit.cover,
                                )
                              // 4) 혹시 둘 다 없으면 안전하게 빈 위젯
                              : const SizedBox.shrink(),
                ),
              ),
            ),

        ],
      ),
    );
  }
  

  // [결제 요청] 메세지 보내기

  Future<void> _sendPaymentRequestMessage() async {
    await _ensureChatRoomExists();

    final senderId = _myUid ?? 'unknown';
    final text = '[결제 요청] 사진 확인 후 "구매하기" 버튼을 눌러 결제를 진행해 주세요.';

    try {
      debugPrint('💬 결제 요청 메시지 전송 시도: $senderId');   // <-- 디버깅용
      debugPrint('💬 로그인 사용자: $_myUid');
      debugPrint('💬 의뢰자: $_requesterUid');
        
      await _db
          .collection('chats')
          .doc(_chatRoomId)
          .collection('messages')
          .add({
        'senderId': senderId,
        'text': text,
        'imageUrl': null,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _db.collection('chats').doc(_chatRoomId).update({
        'participants': [_myUid, _requesterUid],
        'lastMessage': text,
        'lastSenderId': senderId,
        'lastTimestamp': FieldValue.serverTimestamp(),
      });

      Fluttertoast.showToast(msg: '결제 요청 메시지를 보냈어요!');
    } catch (e) {
      debugPrint('결제 요청 메시지 전송 오류: $e');
      Fluttertoast.showToast(msg: '결제 요청 메시지를 보내는 중 오류가 발생했어요.');
    }
  }


  // ===========================================================================
 // 이미지 선택 관련 함수들
 // ===========================================================================

  Future<XFile?> _pickImageFromGallery(BuildContext context) async {
    // 다른 dart파일에 정의한 함수와 달리 전역 변수에 사진을 저장하지 않고 XFile을 반환해서 사용함(void->Future<XFile?>)
    final orig = await pickImageFromGallery(context); 
    if (orig == null) {
      Fluttertoast.showToast(msg: '사진 선택이 취소되었습니다.');
      return null;
    }
    try{
      // 크롭 사용 시
      final normalizedPath = await _toTempFilePath(orig.path);
      final croppedFile = await _imageService.cropImage(normalizedPath); // File?
      if (croppedFile != null) {
        return XFile(croppedFile.path);
      }
      // 크롭 안 쓰거나 실패하면 원본
      return orig;
      } catch (e, st){
      debugPrint('crop error : $e\n$st');
      Fluttertoast.showToast(msg: '편집 중 오류 발생');
      return null;
    }
  }


  Future<XFile?> _pickImageFromCamera(BuildContext context) async {
    final orig = await pickImageFromCamera(context);
    if (orig == null) {
      Fluttertoast.showToast(msg: '사진 촬영이 취소되었습니다.');
      return null;
    } 
    try{
      // 크롭 사용 시
      final normalizedPath = await _toTempFilePath(orig.path);
      final croppedFile = await _imageService.cropImage(normalizedPath); // File?
      if (croppedFile != null) {
        return XFile(croppedFile.path);
      }
      // 크롭 안 쓰거나 실패하면 원본
      return orig;
      } catch (e, st){
      debugPrint('crop error : $e\n$st');
      Fluttertoast.showToast(msg: '편집 중 오류 발생');
      return null;
    }
  }


  Future<XFile?> _pickImageFromFileSystem(BuildContext context) async {
    final file = await pickImageFromFileSystem(context);
    if (file == null) {
      Fluttertoast.showToast(msg: '파일 선택이 취소되었습니다.');
      return null;
    }
    try{
      // 크롭 사용 시
      final normalizedPath = await _toTempFilePath(file.path);
      final croppedFile = await _imageService.cropImage(normalizedPath); // File?
      if (croppedFile != null) {
        return XFile(croppedFile.path);
      }
      // 크롭 안 쓰거나 실패하면 원본
      return file;
      } catch (e, st){
      debugPrint('crop error : $e\n$st');
      Fluttertoast.showToast(msg: '편집 중 오류 발생');
      return null;
    }
  }




  
  // 사진 경로를 받아서 어플의 임시 디렉토리 경로를 반환하는 함수
  Future<String> _toTempFilePath(String pickedPath) async{                     // 갤러리나 카메라에서 가져온 사진 경로를 받음
    final bytes = await XFile(pickedPath).readAsBytes();                       // 원본을 XFile로 감싸서 전체 바이트를 읽어옴
    final ext = path.extension(pickedPath).isNotEmpty ? path.extension(pickedPath) : '.jpg';
    final dir = await getTemporaryDirectory();                                 // 앱 전용 임시 디렉토리
    final f = File('${dir.path}/${DateTime.now().millisecondsSinceEpoch}$ext');// 임시 디렉토리에 새로운 파일 만듦
    await f.writeAsBytes(bytes, flush: true);                                  // 읽어온 바이트를 만든 파일에 기록. flush는 버퍼링된 내용을 바로 사용할 수 있도록 보장
    return f.path;
  } 


 // =========================================================================== 
 // 이미지 메뉴 뜨워주는 함수와 위젯 (카카오톡처럼 메뉴 누르면 하단에 패널이 뜨도록 함)
 // ===========================================================================

  // 이미지 선택 메뉴 보여주는 함수
  Future<void> _openImageActionMenu() async {
    _togglePanel(true); // 패널 열기
  }

  // 카톡처럼 하단에 뜨는 기능 패널 (위젯 : 앨범, 카메라, 파일, 닫기 아이콘 있음)
  Widget _buildFunctionPanel() {
    return Container(
      height: _panelHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300, width: 0.6)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: GridView.count(
        crossAxisCount: 4,
        childAspectRatio: .86,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _imageActionIcon(
            icon: Icons.photo,
            label: '앨범',
            onTap: () async {
              final picked = await _pickImageFromGallery(context);
              if (picked != null) _appendImageMessage(picked);
              _togglePanel(false);
            },
          ),
          _imageActionIcon(
            icon: Icons.camera_alt,
            label: '카메라',
            onTap: () async {
              final picked = await _pickImageFromCamera(context);
              if (picked != null) _appendImageMessage(picked);
              _togglePanel(false);
            },
          ),
          _imageActionIcon(
            icon: Icons.folder,
            label: '파일',
            onTap: () async {
              final picked =await _pickImageFromFileSystem(context);
              if (picked != null) _appendImageMessage(picked);
              _togglePanel(false);
            },
          ),
          _imageActionIcon(
            icon: Icons.close,
            label: '닫기',
            onTap: () => _togglePanel(false),
          ),
        ],
      ),
    );
  }
  
  // 패널 내의 아이콘 + 라벨 만드는 위젯
  Widget _imageActionIcon({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Icon(icon, size: 22, color: Colors.black87),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.black87)),
        ],
      ),
    );
  }
  

 // =========================================================================== 
 // 결제 확인 다이얼로그 (결제하기 버튼 누르면 뜸 -> 취소, 확인 버튼 있음)
 // ===========================================================================

  void _showPaymentDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.white,
          title: const Text(
            '결제 확인',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text('$_requestPrice 포인트를 사용하여 결제하시겠습니까?'),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // 취소 버튼
              style: TextButton.styleFrom(
                backgroundColor: Colors.grey[300], // 밝은 회색
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              child: const Text('취소', style: TextStyle(color: Colors.black)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // ===========================================
                // TODO: 결제 처리 로직 추가 (포인트 차감 등)
                // ===========================================
                Fluttertoast.showToast(msg: '결제가 완료되었습니다!');
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.lightGreen, // lightGreen[200]은 materialColor이므로 바로 사용 가능
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              child: const Text('확인', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }


 // =========================================================================== 
 // UI 빌드
 // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final otherName = _requesterNickname;

    return Scaffold(
      appBar: AppBar(
        title: Text(otherName.isNotEmpty? otherName: '채팅'),
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,  // AppBar 배경색
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          }
        ), 
      ),
      

      body: Container(
        color: Colors.white, 
        child: Column(
          children: [
            // 상단 의뢰글 제목 명시 (클릭하면 의뢰글로 이동)
            Container(
              // 하단 테두리
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: const Color(0xFF7BC67B), width: 0.5),
                ),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 1), // 아래 여백 1 (이전값 8이었음)
                    child : Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: _openRequestDetail, // 클릭시 의뢰글 상세로 이동
                          child: Container(
                            width: double.infinity,
                            /*decoration: BoxDecoration(              // 의뢰상태, 제목, 가격 영역 박스 디자인 
                              color: const Color(0xFFDFF1D5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF7BC67B), width: 1),
                            ),*/
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 의뢰 상태 선택용 드롭다운 메뉴 
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    if(_isOwner)
                                      PopupMenuButton<String>(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(18),
                                        ),
                                        color: Colors.white,              // 메뉴 배경색   
                                        elevation: 6,                       // 그림자 깊이
                                        position: PopupMenuPosition.under,  // 메뉴가 버튼 아래에 나타나도록 설정
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [

                                            // 현재 의뢰 상태 표시 - 텍스트
                                            Text(
                                              _requestStatement, // 텍스트 자체를 트리거로 사용
                                              style: const TextStyle(
                                                color: Color.fromARGB(255, 0, 0, 0),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(width: 4),

                                            // 현재 의뢰 상태 표시 - 아이콘
                                            const Icon(
                                              Icons.arrow_drop_down,
                                              color: Colors.black,
                                              size: 20,
                                            ),
                                          ],
                                        ),

                                        // 메뉴 항목 선택시 처리
                                        onSelected: (value) async {
                                          dev.log('의뢰 상태 변경: $value');
                                          // 1) UI 변경
                                          setState(() {
                                            _requestStatement = value; // 바로 대입
                                          });

                                          // 2) Firestore 업데이트
                                          try {
                                            await _requestService.updateRequest(
                                              _requestId,
                                              {'status': value},   // 바뀐 상태만 업데이트
                                            );
                                            dev.log('Firestore request 상태 업데이트 성공');
                                          } catch (e) {
                                            dev.log('request 상태 업데이트 실패: $e');
                                            Fluttertoast.showToast(msg: "request 상태 변경 실패했습니다");
                                          }
                                        },
                                        itemBuilder: (context) => const [
                                          PopupMenuItem(value: '의뢰중', child: Text('의뢰중')),
                                          PopupMenuItem(value: '거래중', child: Text('거래중')),
                                          PopupMenuItem(value: '의뢰완료', child: Text('의뢰완료')),
                                        ],
                                      ),

                                    if(!_isOwner)
                                     // 현재 의뢰 상태 표시 - 텍스트
                                          Text(
                                            _requestStatement, // 텍스트 자체를 트리거로 사용
                                            style: const TextStyle(
                                              color: Color.fromARGB(255, 0, 0, 0),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                    const SizedBox(width: 4),
                                    
                                    // 의뢰 제목 표시
                                    Text(
                                      _requestTitle,
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        color: Colors.black87,
                                        height: 1.2,
                                      ),
                                    ),
                                  ],
                                ),

                              

                                
                                const SizedBox(height: 4),
                                // 의뢰 가격 표시 (0원은 '무료의뢰'로 표시)
                                Text(_requestPrice == 0 ?  '무료 의뢰' : '${_requestPrice}원',style: const TextStyle()),
                                    
                              ],
                            ),
                          ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),

                  // 결제 버튼
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: SizedBox(
                      width: double.infinity, // 화면 가로 꽉 차게
                      child: ElevatedButton(
                        onPressed: () {
                          // 1) 수락자가 "결제 요청하기"를 누른 경우 → 결제 요청 메시지만 보내기 (수락자는 돈을 받아야 함)
                          if (!_isOwner) {
                            _sendPaymentRequestMessage();
                            return;
                          }

                          // 2) 의뢰자 사진 받기 전이면 토스트
                          if (!_canPay) {
                            Fluttertoast.showToast(msg: '사진을 받은 후에 결제할 수 있어요!');
                            return;
                          }

                          // 3) 의뢰자이고, 사진도 받은 상태면 결제 다이얼로그
                          _showPaymentDialog();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:  const Color(0xFFDFF1D5), // 배경색 흰색
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12), // radius 12
                            side: const BorderSide(color: Color(0xFF7BC67B), width: 1), // 테두리색
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0, // 그림자 제거
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.payment, color: const Color.fromARGB(221, 30, 30, 30)),
                            const SizedBox(width: 5),
                            Text( _isOwner ? '구매하기': '결제 요청 하기',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color.fromARGB(255, 53, 53, 53),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ), 
            ),

            Expanded(
              child: GestureDetector(
                onTap: () => _togglePanel(false),
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _messageStream(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                      }
                      
                      final docs = snapshot.data!.docs;
                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final msg = Message.fromDoc(docs[index]);
                          final isMe = msg.senderId == (_myUid ?? 'dummy_me');
                          
                    return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 4.0),
                        // 열 [프로필, 메세지]
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment:
                                isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                                children: [
                                    if(isMe) Text((msg.createdAt).toKoreanAMPM(), style: TextStyle(fontSize: 10, color: Colors.grey)),
                                    if(!isMe) _buildAvatar(loginProfile: false),
                                    _buildBubble(context, msg, isMe),

                                    if(!isMe) Text((msg.createdAt).toKoreanAMPM(), style: TextStyle(fontSize: 10, color: Colors.grey)),
                                    // if (isMe) const SizedBox(width: 36),
/*
                          final msg = Message.fromDoc(docs[index]);
                          final isMe = msg.senderId == (_myUid ?? 'dummy_me');
                          
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 4.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment:
                              isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                              children: [
                                if (!isMe) _buildAvatar(isMe: false),
                                _buildBubble(msg, isMe),
*/
                                ],
                            ),
                         );
                      },
                    );
                  },
                ),
              ),
            ),

            // 입력창
            SafeArea( // 하단바 등을 피해서 배치
              top: false,
              child: 
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.apps), // 메뉴 아이콘 느낌으로 교체 추천
                        onPressed: _openImageActionMenu, // 패널 열기
                      ),
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          onTap: () => _togglePanel(false), // 입력창 탭하면 패널 닫기
                          decoration: const InputDecoration(
                            hintText: '메시지를 입력하세요',
                            filled: true,
                            fillColor: Color(0xFFF3F4F6),
                            border: OutlineInputBorder(
                              borderSide: BorderSide.none,
                              borderRadius: BorderRadius.all(Radius.circular(24)),
                            ),
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                          onSubmitted: (_) => _sendMessage(), // (_) 는 매개변수를 사용하지 않는다는 의미
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.send),
                        onPressed: _sendMessage,
                      ),
                    ],
                  ),
                ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: _showPanel ? _buildFunctionPanel() : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}


extension KoreanTimeFormat on DateTime {
  String toKoreanAMPM() {
    final hour = this.hour;
    final minute = this.minute.toString().padLeft(2, '0');

    final isAM = hour < 12;
    final period = isAM ? "오전" : "오후";

    final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final hourStr = hour12.toString().padLeft(2, '0');

    return "$period $hourStr:$minute";
  }
}

