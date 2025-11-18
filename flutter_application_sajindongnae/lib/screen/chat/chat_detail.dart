import 'dart:async';
import 'dart:developer' as dev;
import 'dart:io';
import 'dart:ui' as ui;


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_sajindongnae/models/chat_list_model.dart';

import 'package:flutter_application_sajindongnae/models/request_model.dart';
import 'package:flutter_application_sajindongnae/screen/photo/request_detail.dart';
import 'package:flutter_application_sajindongnae/screen/chat/chat_image_viewer.dart';
import 'package:flutter_application_sajindongnae/models/message_model.dart'; // Firestore Message 모델
import 'package:flutter_application_sajindongnae/services/image_service.dart';
import 'package:flutter_application_sajindongnae/services/request_service.dart';
import 'package:flutter_application_sajindongnae/services/trade_BottomSheet_service.dart';

import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import 'package:flutter/services.dart' show rootBundle;
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart'; // 권한

class ChatDetailScreen extends StatefulWidget {
  final RequestModel request;
  final ChatRoom chatRoom;

  const ChatDetailScreen({
    super.key,
    required this.request,
    required this.chatRoom,
  });

  @override
  _ChatDetailScreen createState() => _ChatDetailScreen();
}


class _ChatDetailScreen extends State<ChatDetailScreen> {
  final RequestService _requestService = RequestService(); // 11/16 추가
  StreamSubscription<RequestModel?>? _requestSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _chatSub;

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String? get _myUid => FirebaseAuth.instance.currentUser?.uid;

  late String _otherUid;
  late bool _isOwner; // 리퀘스트 작성자가 아니라면 리퀘스트 상태변화를 할 수 없도록 함


  // Firestore 인스턴스
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Firestore 실시간 메시지 목록 (결제 가능 여부 판단용)
  List<Message> _messages = [];

  // 대화 상대방의 프로필
  String? _myProfileUrl;
  String? _otherProfileUrl;
  bool _isLoadingProfiles = true;
  String? _otherNickname;
  
  // 결제/다운로드 활성화 여부
  bool _canPay = false;       // 상대방이 보낸 사진이 하나라도 있으면 true
  bool _canDownload = false;  // 수락자는 항상 가능, 의뢰자는 isPaied == true 일 때만

  // 채팅방 / 의뢰 정보
  late RequestModel _originalRequest;

  late final String _chatRoomId;
  late final String _requestId;
  late final String _requesterUid;
  late final String _requesterNickname;
  late String _requestTitle;
  late int _requestPrice;
  bool _isPaied = false;

  // 리퀘스트 상태(의뢰중, 거래중, 의뢰완료)
  String _requestStatement = '의뢰중';

  String? _lastNonRequesterImageUrl; // 의뢰자가 아닌 사람이 보낸 마지막 이미지 URL

  // 선택한 이미지 파일
  XFile? _originalImage;
  XFile? _selectedImage; 
  final bool _cropping = false;
  late ImageService _imageService;

  // 기능 패널 on/off 제어
  bool _showPanel = false;
  final double _panelHeight = 260;

  void _hideKeyboard() => FocusScope.of(context).unfocus();

  void _togglePanel([bool? show]) {
    setState(() {
      _showPanel = show ?? !_showPanel;
    });
    if (_showPanel) _hideKeyboard();
  }

  @override
  void initState() {
    super.initState();

    final myUid = FirebaseAuth.instance.currentUser!.uid;
    final otherUid = widget.chatRoom.participants.firstWhere(
      (id) => id != myUid,
    );
    
    // 상대방 UID 저장
    _otherUid = otherUid;

    // 프로필/닉네임 불러오기
    _loadProfiles();

    final sorted = [myUid, otherUid]..sort();
    _chatRoomId = sorted.join('_');

    _originalRequest = widget.request;
    _imageService = ImageService();

    _requestId = _originalRequest.requestId;
    _requesterUid = _originalRequest.uid;
    _requesterNickname = _originalRequest.nickname;
    _requestTitle = _originalRequest.title;
    _requestPrice = _originalRequest.price;
    _requestStatement = _originalRequest.status ?? '의뢰중';
    _isPaied = _originalRequest.isPaied;

    _ensureChatRoomExists();   // 채팅방 생성 확인 (가장 중요)
    // _loadRequest();         // 실시간으로 바꾸며 제거 : 의뢰글 정보 로드

    final me = _myUid ?? 'dummy_me';
    _isOwner = _myUid == _requesterUid; 


    _isOwner = _myUid == _requesterUid;
    _canDownload = !_isOwner || _originalRequest.isPaied;

    // 의뢰글 실시간 구독
    _requestSub = _requestService.watchRequest(_requestId).listen((req) {
      if (req == null) return;
      if (!mounted) return;
      setState(() {
        _originalRequest = req;
        _requestTitle = req.title;
        _requestPrice = req.price;
        _requestStatement = req.status;
        _isPaied = req.isPaied;
        _canDownload = !_isOwner || _isPaied;
      });
    });



    // Firestore 메시지 스트림 구독

    _chatSub = _db
        .collection('chats')
        .doc(_chatRoomId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;

      final msgs = snapshot.docs.map((d) => Message.fromDoc(d)).toList();
      final myUid = _myUid;
      final hasOpponentImage = msgs.any((m) {
        if (!m.hasImage) return false;
        if (myUid == null) return true;
        return m.senderId != myUid;
      });

        String? lastNonRequesterImageUrl;
        for (final m in msgs) {
          if (m.hasImage &&
              m.senderId != _requesterUid &&          // 의뢰인이 아닌 사람
              m.imageUrl != null &&
              m.imageUrl!.isNotEmpty) {
            lastNonRequesterImageUrl = m.imageUrl;    // 계속 덮어쓰기 → 결국 마지막 값
          }
        }

      setState(() {
        _messages = msgs;
        _canPay = hasOpponentImage;
        _lastNonRequesterImageUrl = lastNonRequesterImageUrl;
      });
    });
  }

  @override
  void dispose() {
    _requestSub?.cancel();
    _chatSub?.cancel();
    _scrollController.dispose();
    _messageController.dispose();
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


 // =========================================================================== 
 //  상대방 ID 찾아내고 프로필 가져오기
 // ===========================================================================

  // 상대방 ID 찾기
  Future<void> _loadParticipants() async {
    final doc = await _db.collection('chats').doc(_chatRoomId).get();

    if (!doc.exists) return;

    final data = doc.data()!;
    final List<dynamic> participants = data['participants'] ?? [];

    final me = _myUid;
    if (me == null) return;

    // participants 중 내가 아닌 uid를 상대방으로 지정
    _otherUid = participants.firstWhere((uid) => uid != me);

    dev.log("상대방 UID = $_otherUid");
  }


  Future<void> _loadProfiles() async {
    try {
      final me = _myUid;
      final other = _otherUid;

      Future<Map<String, dynamic>?> getUser(String uid) async {
        final snap = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        return snap.exists ? snap.data() : null;

      }

      // 내 정보 (옵션)
      Map<String, dynamic>? myData;
      if (me != null) {
        myData = await getUser(me);
      }

      // 상대방 정보
      final otherData = await getUser(other);

      if (!mounted) return;

      setState(() {
        _myProfileUrl = myData?['profileImageUrl'];
        _otherProfileUrl = otherData?['profileImageUrl'];
        _otherNickname  = otherData?['nickname'];   // ← ★ 여기서 닉네임 저장!
        _isLoadingProfiles = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingProfiles = false);
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

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    await _ensureChatRoomExists();

    final senderId = _myUid ?? 'unknown';
    final messageData = {
      'senderId': senderId,
      'text': text,
      'imageUrl': null,
      'createdAt': FieldValue.serverTimestamp(),
    };

    try {
      await _db
          .collection('chats')
          .doc(_chatRoomId)
          .collection('messages')
          .add(messageData);

      await _db.collection('chats').doc(_chatRoomId).update({
        'lastMessage': text,
        'lastSenderId': senderId,
        'lastTimestamp': FieldValue.serverTimestamp(),
      });

      _messageController.clear();
    } catch (e) {
      debugPrint('메시지 전송 오류: $e');
    }
  }

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
    await _ensureChatRoomExists();

    try {
      final imageUrl = await _imageService.uploadChatImage(picked, _chatRoomId);

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

      await _db.collection('chats').doc(_chatRoomId).update({
        'lastMessage': '(이미지)',
        'lastSenderId': senderId,
        'lastTimestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('이미지 메시지 전송 오류: $e');
    }
  }

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

  // =======================================================================
  // 채팅 메세지 위젯들
  // =======================================================================

  Widget _buildAvatar({required bool loginProfile}) {
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

  Widget _buildBubble(BuildContext context, Message msg, bool isMe) {
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
          // 텍스트
          if (msg.text != null && msg.text!.isNotEmpty)
            Text(
              msg.text!,
              style: const TextStyle(fontSize: 15, color: Colors.black),
            ),

          if ((msg.text != null && msg.text!.isNotEmpty) &&
              ((msg.imageUrl != null && msg.imageUrl!.isNotEmpty) ||
                  msg.image != null))
            const SizedBox(height: 8),

          // 이미지 + 워터마크
          if ((msg.imageUrl != null && msg.imageUrl!.isNotEmpty) ||
              msg.image != null)
            GestureDetector(
              onTap: () {
                // 1) Firestore 네트워크 이미지
                if (msg.imageUrl != null && msg.imageUrl!.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatImageViewer(
                        imagePath: msg.imageUrl!,
                        isAsset: false,
                        heroTag: 'chat_image_${msg.id}',
                        photoOwnerNickname: _requesterNickname,
                        canDownload: _canDownload,
                      ),
                    ),
                  );
                  return;
                }

                // 2) 로컬/에셋 이미지 (예비용)
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
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // 실제 이미지
                      if (msg.imageUrl != null && msg.imageUrl!.isNotEmpty)
                        Image.network(
                          msg.imageUrl!,
                          width: 200,
                          fit: BoxFit.cover,
                        )
                      else if (msg.image != null &&
                          msg.image!.path.startsWith('assets/'))
                        Image.asset(
                          msg.image!.path,
                          width: 200,
                          fit: BoxFit.cover,
                        )
                      else if (msg.image != null)
                          Image.file(
                            File(msg.image!.path),
                            width: 200,
                            fit: BoxFit.cover,
                          )
                        else
                          const SizedBox.shrink(),

                      // 대각선 반복 워터마크
                      const Positioned.fill(
                        child: DiagonalWatermarkOverlay(
                          text: '사진동네',
                          fontSize: 16,   // 더 작게
                          opacity: 0.14,  // 연하게
                          angle: -0.6,    // 대각선 (라디안, 약 -34도)
                        ),
                      ),
                    ],
                  ),
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
      debugPrint('💬 결제 요청 메시지 전송 시도: $senderId');
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


  // [결제 완료] 메세지 보내기
  Future<void> _sendPaymentCompleteMessage() async {
    await _ensureChatRoomExists();

    final senderId = _myUid ?? 'unknown';

    try {
      await _db
          .collection('chats')
          .doc(_chatRoomId)
          .collection('messages')
          .add({
        'senderId': senderId,
        'text': null,                 // 텍스트는 사용 안 함
        'imageUrl': null,             // 이미지 URL도 없음
        'createdAt': FieldValue.serverTimestamp(),
        'type': 'payment_complete',   
        'paymentAmount': _requestPrice, 
      });

      await _db.collection('chats').doc(_chatRoomId).update({
        'lastMessage': '결제가 완료되었습니다.',
        'lastSenderId': senderId,
        'lastTimestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('결제 완료 메시지 전송 오류: $e');
      Fluttertoast.showToast(msg: '결제 완료 메시지를 보내는 중 오류가 발생했어요.');
    }
  }

  // [결제 완료] 메세지 내용
  Widget _buildPaymentCompleteCard(BuildContext context, Message msg, bool isMe) {
    final amount = msg.paymentAmount ?? _requestPrice;
    
    // ✅ 결제한 사람 닉네임 계산
    // 메시지를 보낸 사람이 의뢰자면 -> 의뢰자 닉네임
    // 아니면 -> 상대방 닉네임
    String payerNickname;
    if (msg.senderId == _requesterUid) {
      payerNickname = _requesterNickname;
    } else {
      payerNickname = _otherNickname ?? '알 수 없음';
    }
    
    // 더미 데이터 (결제완료 메세지는 의뢰자가 보냄. 의뢰자일 경우와 아닐 경우로 나누어 각각의 잔액을 표시)
    final int remainingBalance = isMe ? 43210 : 98765;

    // 썸네일로 쓸 이미지 (없으면 더미 이미지)
    final thumbUrl = _lastNonRequesterImageUrl ??
    'https://via.placeholder.com/150'; // TODO: 나중에 플레이스홀더 바꾸기


    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFDFF1D5), // 연한 초록 느낌
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFF7BC67B), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // 앵무새 아이콘
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Image.asset(
                    'assets/icons/parrot.png',
                    width: 26,
                    height: 26,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                 '[${payerNickname}] 님의 송금',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${amount}원을 보냈어요.',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 4),
          const Text(
            '상대방과의 거래를 마무리해주세요.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 36,
            child: ElevatedButton(
              onPressed: () {
              // 여기서 바텀시트 호출
                tradeBottomSheetService(
                  context: context,
                  postId: _requestId,              // 어떤 의뢰/거래인지 구분용 (지금은 그냥 넘겨만 주기)
                  imageUrl: thumbUrl,         
                  title: _requestTitle,            // 의뢰 제목
                  price: amount,                   // 결제 금액
                  remainingBalance: remainingBalance, // 더미 잔액
                  onTapMyPage: () {
                    // TODO: 마이페이지로 이동하는 로직 나중에 구현
                    Fluttertoast.showToast(msg: '마이페이지로 이동(추후 구현)');
                  },
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: const Text(
                '의뢰 내역 보기',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }



  // ===========================================================================
 // 이미지 선택 관련 함수들
 // ===========================================================================

  Future<XFile?> _pickImageFromGallery(BuildContext context) async {
    final orig = await pickImageFromGallery(context);
    if (orig == null) {
      Fluttertoast.showToast(msg: '사진 선택이 취소되었습니다.');
      return null;
    }
    try {
      final normalizedPath = await _toTempFilePath(orig.path);
      final croppedFile = await _imageService.cropImage(normalizedPath);
      if (croppedFile != null) {
        return XFile(croppedFile.path);
      }
      return orig;
    } catch (e, st) {
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
    try {
      final normalizedPath = await _toTempFilePath(orig.path);
      final croppedFile = await _imageService.cropImage(normalizedPath);
      if (croppedFile != null) {
        return XFile(croppedFile.path);
      }
      return orig;
    } catch (e, st) {
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
    try {
      final normalizedPath = await _toTempFilePath(file.path);
      final croppedFile = await _imageService.cropImage(normalizedPath);
      if (croppedFile != null) {
        return XFile(croppedFile.path);
      }
      return file;
    } catch (e, st) {
      debugPrint('crop error : $e\n$st');
      Fluttertoast.showToast(msg: '편집 중 오류 발생');
      return null;
    }
  }

  Future<String> _toTempFilePath(String pickedPath) async {
    final bytes = await XFile(pickedPath).readAsBytes();
    final ext =
    path.extension(pickedPath).isNotEmpty ? path.extension(pickedPath) : '.jpg';
    final dir = await getTemporaryDirectory();
    final f =
    File('${dir.path}/${DateTime.now().millisecondsSinceEpoch}$ext');
    await f.writeAsBytes(bytes, flush: true);
    return f.path;
  }

  // =======================================================================
  // 하단 기능 패널
  // =======================================================================

  Future<void> _openImageActionMenu() async {
    _togglePanel(true);
  }

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
              final picked = await _pickImageFromFileSystem(context);
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

  // =======================================================================
  // 실제 포인트 결제 처리 (의뢰자 -> 수락자)
  // =======================================================================
  Future<void> _processPayment() async {
    final buyerUid = _requesterUid; // 결제(포인트 차감) 주체: 의뢰자
    final sellerUid = _otherUid;    // 포인트 받는 사람: 의뢰 수락자
    final amount = _requestPrice;

    if (buyerUid.isEmpty || sellerUid.isEmpty) {
      Fluttertoast.showToast(msg: '결제 대상 정보를 찾을 수 없습니다.');
      return;
    }

    try {
      await _db.runTransaction((transaction) async {
        final buyerRef = _db.collection('users').doc(buyerUid);
        final sellerRef = _db.collection('users').doc(sellerUid);
        final requestRef = _db.collection('requests').doc(_requestId);

        final buyerSnap = await transaction.get(buyerRef);
        final sellerSnap = await transaction.get(sellerRef);

        if (!buyerSnap.exists || !sellerSnap.exists) {
          throw Exception('유저 정보를 찾을 수 없습니다.');
        }

        final buyerData = buyerSnap.data() as Map<String, dynamic>;
        final sellerData = sellerSnap.data() as Map<String, dynamic>;

        // 현재 포인트 (없으면 0으로 간주)
        final buyerPoint = ((buyerData['point'] ?? {})['balance'] ?? 0) as int;
        final sellerPoint = ((sellerData['point'] ?? {})['balance'] ?? 0) as int;

        if (buyerPoint < amount) {
          throw Exception('잔액이 부족합니다.');
        }

        final newBuyerPoint = buyerPoint - amount;
        final newSellerPoint = sellerPoint + amount;

        // 의뢰자 포인트 차감
        transaction.update(buyerRef, {
          'point.balance': newBuyerPoint,
        });

        // 수락자 포인트 가산
        transaction.update(sellerRef, {
          'point.balance': newSellerPoint,
        });

        // 의뢰 상태 / 결제 여부 업데이트
        transaction.update(requestRef, {
          'isPaied': true,
          'status': '의뢰완료',
          'paidAt': FieldValue.serverTimestamp(),
        });
      });

      // 상태 반영
      if (mounted) {
        setState(() {
          _isPaied = true;
          _canDownload = true;
          _requestStatement = '의뢰완료';
        });
      }

      // 결제 완료 메시지 전송 (채팅용)
      await _sendPaymentCompleteMessage();

      Fluttertoast.showToast(msg: '결제가 완료되었습니다!');
    } catch (e) {
      debugPrint('결제 처리 실패: $e');
      if (e.toString().contains('잔액이 부족')) {
        Fluttertoast.showToast(msg: '포인트가 부족하여 결제할 수 없습니다.');
      } else {
        Fluttertoast.showToast(msg: '결제 처리 중 오류가 발생했습니다.');
      }
    }
  }


  // =======================================================================
  // 결제 다이얼로그
  // =======================================================================

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
          actionsPadding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                backgroundColor: Colors.grey[300],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              child: const Text('취소', style: TextStyle(color: Colors.black)),
            ),
            TextButton(
              onPressed: () async{
                Navigator.pop(context);
                Fluttertoast.showToast(msg: '결제가 완료되었습니다!');
                await _processPayment();
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.lightGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              child: const Text('확인', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // =======================================================================
  // UI 빌드
  // =======================================================================

  @override
  Widget build(BuildContext context) {
    final otherName = _requesterNickname;

    return Scaffold(
      appBar: AppBar(
        title: Text(_otherNickname ?? '채팅'),

        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Container(
        color: Colors.white,
        child: Column(
          children: [
            // 상단 의뢰 정보 영역
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFF7BC67B), width: 0.5),
                ),
              ),
              child: Column(
                children: [
                  Padding(
                    padding:
                    const EdgeInsets.fromLTRB(12, 12, 12, 1),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: _openRequestDetail,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  if (_isOwner)
                                    PopupMenuButton<String>(
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                        BorderRadius.circular(18),
                                      ),
                                      color: Colors.white,
                                      elevation: 6,
                                      position: PopupMenuPosition.under,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            _requestStatement,
                                            style: const TextStyle(
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(
                                            Icons.arrow_drop_down,
                                            color: Colors.black,
                                            size: 20,
                                          ),
                                        ],
                                      ),
                                      onSelected: (value) async {
                                        dev.log('의뢰 상태 변경: $value');
                                        setState(() {
                                          _requestStatement = value;
                                        });

                                        try {
                                          await _requestService.updateRequest(
                                            _requestId,
                                            {'status': value},
                                          );
                                          dev.log('Firestore request 상태 업데이트 성공');
                                        } catch (e) {
                                          dev.log(
                                              'request 상태 업데이트 실패: $e');
                                          Fluttertoast.showToast(
                                              msg: "request 상태 변경 실패했습니다");
                                        }
                                      },
                                      itemBuilder: (context) => const [
                                        PopupMenuItem(
                                            value: '의뢰중', child: Text('의뢰중')),
                                        PopupMenuItem(
                                            value: '거래중', child: Text('거래중')),
                                        PopupMenuItem(
                                            value: '의뢰완료',
                                            child: Text('의뢰완료')),
                                      ],
                                    ),
                                  if (!_isOwner)
                                    Text(
                                      _requestStatement,
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      _requestTitle,
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        color: Colors.black87,
                                        height: 1.2,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _requestPrice == 0
                                    ? '무료 의뢰'
                                    : '${_requestPrice}원',
                                style: const TextStyle(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),

                  // 결제 버튼
                  Padding(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 12.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // 수락자 → 결제 요청 보내기
                          if (!_isOwner) {
                            _sendPaymentRequestMessage();
                            return;
                          }

                          // 의뢰자: 사진 받기 전에는 막기
                          if (!_canPay) {
                            Fluttertoast.showToast(
                                msg: '사진을 받은 후에 결제할 수 있어요!');
                            return;
                          }

                          _showPaymentDialog();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDFF1D5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(
                                color: Color(0xFF7BC67B), width: 1),
                          ),
                          padding:
                          const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.payment,
                                color: Color.fromARGB(221, 30, 30, 30)),
                            const SizedBox(width: 5),
                            Text(
                              _isOwner ? '구매하기' : '결제 요청 하기',
                              style: const TextStyle(
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

            // 채팅 리스트
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

                        // ★ 결제 완료 카드
                        if (msg.isPaymentComplete) {
                          return _buildPaymentCompleteCard(context, msg, isMe);
                        }

                        // ★ 일반 말풍선
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 2.0, horizontal: 4.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment:
                                isMe ? MainAxisAlignment.end : MainAxisAlignment.start,

                            children: [
                              if (isMe)
                                Text(
                                  (msg.createdAt).toKoreanAMPM(),
                                  style: const TextStyle(
                                      fontSize: 10, color: Colors.grey),
                                ),
                              if (!isMe) _buildAvatar(loginProfile: false),
                              // Flexible 추가 (줄 내림)
                              Flexible(
                                child: _buildBubble(context, msg, isMe),
                              ),
                              //_buildBubble(context, msg, isMe),

                              if (!isMe)
                                Text(
                                  (msg.createdAt).toKoreanAMPM(),
                                  style: const TextStyle(
                                      fontSize: 10, color: Colors.grey),
                                ),
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
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.apps),
                      onPressed: _openImageActionMenu,
                    ),
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        onTap: () => _togglePanel(false),
                        decoration: const InputDecoration(
                          hintText: '메시지를 입력하세요',
                          filled: true,
                          fillColor: Color(0xFFF3F4F6),
                          border: OutlineInputBorder(
                            borderSide: BorderSide.none,
                            borderRadius:
                            BorderRadius.all(Radius.circular(24)),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _sendMessage,
                    ),
                  ],
                ),
              ),
            ),

            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child:
              _showPanel ? _buildFunctionPanel() : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

// 시간 포맷 확장
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

// ==========================================================
// 대각선 반복 워터마크 위젯
// ==========================================================

class DiagonalWatermarkOverlay extends StatelessWidget {
  final String text;
  final double fontSize;
  final double opacity;
  final double angle;

  const DiagonalWatermarkOverlay({
    super.key,
    required this.text,
    this.fontSize = 16,
    this.opacity = 0.15,
    this.angle = -0.6,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Opacity(
        opacity: opacity,
        child: CustomPaint(
          painter: _DiagonalWatermarkPainter(
            text: text,
            fontSize: fontSize,
            angle: angle,
          ),
        ),
      ),
    );
  }
}

class _DiagonalWatermarkPainter extends CustomPainter {
  final String text;
  final double fontSize;
  final double angle;

  _DiagonalWatermarkPainter({
    required this.text,
    required this.fontSize,
    required this.angle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final textStyle = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
      color: Colors.white,
      letterSpacing: 2.0,
      shadows: [
        Shadow(
          offset: const Offset(0, 0),
          blurRadius: 3,
          color: Colors.black.withOpacity(0.25),
        ),
      ],
    );

    final tp = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textDirection: ui.TextDirection.ltr,
    )..layout();

    canvas.save();

    // 중심 기준 회전
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(angle);
    canvas.translate(-size.width / 2, -size.height / 2);

    final stepX = tp.width + 20; // 가로 간격
    final stepY = tp.height * 2.5; // 세로(줄) 간격

    for (double y = -size.height; y < size.height * 2; y += stepY) {
      for (double x = -size.width; x < size.width * 2; x += stepX) {
        tp.paint(canvas, Offset(x, y));
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _DiagonalWatermarkPainter oldDelegate) {
    return oldDelegate.text != text ||
        oldDelegate.fontSize != fontSize ||
        oldDelegate.angle != angle;
  }
}
