import 'dart:developer' as dev;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:intl/intl.dart';
// 권한
import 'package:flutter_application_sajindongnae/services/image_service.dart';
import 'package:http/http.dart' as http;  

 // ---------------------------------------------------------------------------
 // 채팅 이미지 전체화면 뷰어
 // 1. 사진 확대/축소 가능
 // 2. 갤러리에 사진 저장 기능
 // 3. 현재 테스트를 위해 에셋이미지와 파일 이미지를 모두 지원하도록 함
 // 4. ChatDetailScreen에서 Navigator로 이동하여 사용
 // 5. 다른 화면 (ex : 구매한 사진 보기) 에서도 재사용 할 수 있음 
 // 5-1. 재사용시에는 photoOwnerNickname 파라미터에 사진 소유자 닉네임을 전달하면 닉네임_sajindongnae_YYYYMMDD_HHmmss 형식으로 갤러리에 저장
 // ---------------------------------------------------------------------------



class ChatImageViewer extends StatelessWidget {
  final String imagePath;
  final bool isAsset;
  final String heroTag;
  final String? photoOwnerNickname;
  final bool canDownload;

  const ChatImageViewer({
    super.key,
    required this.imagePath,
    required this.isAsset,
    required this.heroTag,
    this.photoOwnerNickname, 
    required this.canDownload,
  });

  
 // =========================================================================== 
 // 사진을 갤러리에 저장하기 위한 코드
 // ===========================================================================

    Future<void> _saveImageToGallery(BuildContext context) async {
     try { 
      // 1) Android SDK 32 이하에서는 기존 storage 권한 사용 if (!kIsWeb) {
        final sdk = await androidSdkInt();
        if (sdk != null && sdk <= 32) {
          final ok = await ensureLegacyStoragePermission(context);
          if (!ok){
            //Fluttertoast.showToast(msg: '저장소 권한이 필요합니다.');
            return;
          }
        }
      
      // 2) 이미지 바이트 읽기 (asset vs 파일)
      Uint8List bytes;
      if (imagePath.startsWith('http')) {
      // 네트워크 이미지 (Firestore downloadUrl)
      final uri = Uri.parse(imagePath);
      final resp = await http.get(uri);
      if (resp.statusCode != 200) {
        Fluttertoast.showToast(msg: '이미지를 불러오지 못했습니다.');
        return;
      }
      bytes = resp.bodyBytes;
      
      } else if (isAsset) {
        //  에셋 이미지
        final bd = await rootBundle.load(imagePath);
        bytes = bd.buffer.asUint8List();
      } else {
        //  로컬 파일
        final file = File(imagePath);
        if (!file.existsSync()) {
          Fluttertoast.showToast(msg: '이미지 파일을 찾을 수 없습니다.');
          return;
        }
        bytes = await file.readAsBytes();
      }

      // 3) 파일 이름 만들기
      //    - 한글 허용: 상대방닉네임_sajindongnae_YYYYMMDD_HHmmss
      //    - 닉네임 비어있으면: sajindongnae_YYYYMMDD_HHmmss
      final now = DateTime.now();
      final ts = DateFormat('yyyyMMdd_HHmmss').format(now);
      final trimmedNick = (photoOwnerNickname ?? '').trim();
      final fileNameBase = trimmedNick.isNotEmpty
          ? '${trimmedNick}_sajindongnae_$ts'
          : 'sajindongnae_$ts';

      // 4) 갤러리에 저장
      final result = await ImageGallerySaverPlus.saveImage(
        bytes,
        name: fileNameBase,
      );
      dev.log('save result: $result');

      final isSuccess = (result['isSuccess'] == true || result['isSuccess'] == 1);

      if (isSuccess) {
        Fluttertoast.showToast(msg: '갤러리에 저장되었습니다.');
      } else {
        Fluttertoast.showToast(msg: '저장에 실패했습니다. 잠시 후 다시 시도해주세요.');
      }
    } catch (e, st) {
      debugPrint('갤러리 저장 중 오류: $e\n$st');
      Fluttertoast.showToast(msg: '저장 중 오류가 발생했습니다.');
    }
  }


  @override
  Widget build(BuildContext context) {
    late final Widget imageWidget;

    if (imagePath.startsWith('http')) {
      // 네트워크 이미지 -> firestore용 이것만 빼고 나중에 지워도 됨
      imageWidget = Image.network(
        imagePath,
        fit: BoxFit.contain,
      );
    } else if (isAsset) {
      // 에셋
      imageWidget = Image.asset(
        imagePath,
        fit: BoxFit.contain,
      );
    } else {
      // 로컬 파일
      imageWidget = Image.file(
        File(imagePath),
        fit: BoxFit.contain,
      );
    } 

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          '사진 보기',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () async{
              await _saveImageToGallery(context);
            },
          ),
    ],
      ),
      body: Center(
        child: Hero(
          tag: heroTag,
          child: InteractiveViewer(
            minScale: 0.8,
            maxScale: 4.0,
            child: imageWidget,
          ),
        ),
      ),
    );
  }
}
