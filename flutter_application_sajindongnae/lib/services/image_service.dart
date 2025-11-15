// image_service.dart
// 각주: 워터마크 생성 + 이미지 선택/권한/크롭/압축 유틸을 모아둔 서비스 파일

import 'dart:developer';
import 'dart:io'; // 각주: Android/iOS 네이티브 파일 접근용 (웹에서는 사용 불가)
import 'dart:math' as math;
import 'dart:ui' as ui; // 각주: Canvas, PictureRecorder 등 로우레벨 드로잉

import 'package:device_info_plus/device_info_plus.dart'; // 각주: SDK 버전 확인
import 'package:file_picker/file_picker.dart';            // 각주: 파일 선택 (갤러리 외)
import 'package:firebase_storage/firebase_storage.dart';  // 각주: 이미지 업로드
import 'package:flutter/material.dart';                   // 각주: TextPainter 등 머터리얼 의존
import 'package:flutter/widgets.dart';                   // 각주: UI 위젯 기본 (중복 import 허용)
import 'package:flutter_image_compress/flutter_image_compress.dart'; // 이미지 압축
import 'package:image_cropper/image_cropper.dart';                     // 이미지 크롭
import 'package:image_picker/image_picker.dart';                       // 카메라/갤러리
import 'package:path/path.dart' as path;                               // 경로/확장자
import 'package:path_provider/path_provider.dart';                     // 임시 디렉토리
import 'package:permission_handler/permission_handler.dart';           // 권한
import 'package:flutter/foundation.dart' show kIsWeb;                  // 웹 가드

// 기존 import들 아래에 추가
import 'package:flutter/painting.dart' as painting; // Future<ui.Image> decodeImageFromList 사용


final ImagePicker _picker = ImagePicker(); // 각주: image_picker 인스턴스

// Android SDK 버전 조회 (iOS/웹은 null)
Future<int?> _androidSdkInt() async {
  // 각주: 웹에서는 dart:io가 동작하지 않으므로 Platform 접근을 피한다
  if (!Platform.isAndroid) return null;
  final info = await DeviceInfoPlugin().androidInfo;
  return info.version.sdkInt;
}

// 갤러리/파일 접근 권한 확인 (SDK 32 이하에서만 유효)
Future<bool> _ensureLegacyStoragePermission(BuildContext context) async {
  final st = await Permission.storage.status;
  if (st.isGranted) return true;

  if (st.isPermanentlyDenied) {
    final go = await _showGoToSettingsDialog(
      context,
      reason: '사진을 불러오려면 갤러리 접근 권한이 필요합니다.\n설정에서 권한을 확인해주세요',
    );
    if (go) await openAppSettings();
    return false;
  }

  final req = await Permission.storage.request();
  if (req.isGranted) return true;

  if (req.isPermanentlyDenied) {
    final go = await _showGoToSettingsDialog(
      context,
      reason: '갤러리 접근 권한이 거절되었습니다.\n설정에서 권한을 허용해주세요',
    );
    if (go) await openAppSettings();
  } else {
    _toast(context, '설정에서 갤러리 접근 권한을 허용할 수 있습니다');
  }
  return false;
}

// -------------------------------
//  갤러리 관련
// -------------------------------
Future<XFile?> pickImageFromGallery(BuildContext context) async {
  // 각주: 웹은 권한 없이 동작
  if (kIsWeb) return await _picker.pickImage(source: ImageSource.gallery);

  final sdk = await _androidSdkInt();
  if (sdk == null || sdk >= 33) {
    // 각주: Android 13+는 시스템 Photo Picker라 권한 불필요
    return await _picker.pickImage(source: ImageSource.gallery);
  } else {
    final ok = await _ensureLegacyStoragePermission(context);
    if (!ok) return null;
    return await _picker.pickImage(source: ImageSource.gallery);
  }
}

// 여러 장 (최대 4장 예시)
Future<List<XFile?>> pickMultiImagesFromGallery(BuildContext context) async {
  if (kIsWeb) {
    final files = await _picker.pickMultiImage();
    if (files.length > 4) {
      _toast(context, '최대 4장까지만 선택할 수 있습니다. 처음 4장만 사용됩니다.');
      return files.sublist(0, 4);
    }
    return files;
  }

  final sdk = await _androidSdkInt();
  List<XFile> files = [];
  if (sdk == null || sdk >= 33) {
    files = await _picker.pickMultiImage();
  } else {
    final ok = await _ensureLegacyStoragePermission(context);
    if (ok) {
      files = await _picker.pickMultiImage();
    } else {
      return [];
    }
  }

  if (files.length > 4) {
    _toast(context, '최대 4장까지만 선택할 수 있습니다. 처음 4장만 사용됩니다.');
    return files.sublist(0, 4);
  }
  return files;
}

// -------------------------------
//  카메라 관련
// -------------------------------
Future<XFile?> pickImageFromCamera(BuildContext context) async {
  final ok = await _ensureCameraPermission(context);
  if (!ok) return null;
  return await _picker.pickImage(source: ImageSource.camera);
}

Future<bool> _ensureCameraPermission(BuildContext context) async {
  final st = await Permission.camera.status;
  if (st.isGranted) return true;

  if (st.isPermanentlyDenied) {
    final go = await _showGoToSettingsDialog(
      context,
      reason: '사진 촬영을 위해 카메라 접근 권한이 필요합니다.\n설정에서 권한을 확인해주세요',
    );
    if (go) await openAppSettings();
    return false;
  }

  final req = await Permission.camera.request();
  if (req.isGranted) return true;

  if (req.isPermanentlyDenied) {
    final go = await _showGoToSettingsDialog(
      context,
      reason: '카메라 접근 권한이 거절되었습니다.\n설정에서 권한을 허용해주세요',
    );
    if (go) await openAppSettings();
  } else {
    _toast(context, '설정에서 권한을 허용할 수 있습니다');
  }
  return false;
}

// -------------------------------
//  파일 관련
// -------------------------------
Future<XFile?> pickImageFromFileSystem(BuildContext context) async {
  final sdk = await _androidSdkInt();
  if (sdk != null && sdk <= 32) {
    final ok = await _ensureLegacyStoragePermission(context);
    if (!ok) return null;
  }

  final result = await FilePicker.platform.pickFiles(
    type: FileType.image,
    allowMultiple: false,
  );

  if (result == null || result.files.isEmpty) return null;

  final f = result.files.single.path;
  if (f != null) return XFile(f);
  return null;
}

class ImageService {
  // 접근 권한 요청 일괄
  Future<bool> requestPermission() async {
    bool storage = await Permission.storage.request().isGranted;
    bool camera = await Permission.camera.request().isGranted;
    if (!storage || !camera) return false;
    return true;
  }

  Future<bool> requestPermissionForCamera() async {
    bool camera = await Permission.camera.request().isGranted;
    return camera;
  }

  Future<bool> requestPermissionForGallery() async {
    bool storage = await Permission.storage.request().isGranted;
    return storage;
  }

  // 카메라/갤러리 단순 래핑
  Future<XFile?> takePhoto() async {
    log('1. 카메라 열기 시도');
    return await _picker.pickImage(source: ImageSource.camera);
  }

  Future<XFile?> pickImageFromGallery() async {
    return await _picker.pickImage(source: ImageSource.gallery);
  }

  Future<XFile?> pickImageFromFileSystem() async {
    log('1. 파일시스템 열기 시도');
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    log('2. 파일 받아옴');
    if (result != null && result.files.single.path != null) {
      log('3. 파일 리턴');
      return XFile(result.files.single.path!);
    }
    return null;
  }

  static Future<String> uploadProfileImage(String uid, File file) async {
    final ref = FirebaseStorage.instance.ref().child('profileImages/$uid/${DateTime.now().millisecondsSinceEpoch}');
    final uploadTask = await ref.putFile(file);
    final url = await ref.getDownloadURL();
    return url;
  }

  // 크롭
  Future<CroppedFile?> cropImage(String imagePath, {bool lockSquare = false}) async {
    try {
      final ext = path.extension(imagePath).toLowerCase();
      ImageCompressFormat format =
          (ext == '.png') ? ImageCompressFormat.png : ImageCompressFormat.jpg;

      final cropped = await ImageCropper().cropImage(
        sourcePath: imagePath,
        compressFormat: format,
        uiSettings: [
          AndroidUiSettings(
            toolbarColor: Colors.white,
            toolbarWidgetColor: Colors.black,
            toolbarTitle: '사진 편집',
            lockAspectRatio: lockSquare,
            initAspectRatio:
                lockSquare ? CropAspectRatioPreset.square : CropAspectRatioPreset.original,
          ),
          IOSUiSettings(
            aspectRatioLockEnabled: lockSquare,
          ),
        ],
      );
      return cropped;
    } catch (e) {
      debugPrint('Crop error: $e');
      return null;
    }
  }



  // 압축
  Future<XFile?> compressImage(String imagePath) async {
    try {
      final ext = imagePath.split('.').last;
      final outputPath = imagePath.replaceAll(".$ext", '_compressed.webp');

      return await FlutterImageCompress.compressAndGetFile(
        imagePath,
        outputPath,
        format: CompressFormat.webp,
        quality: 88, // 각주: 품질/용량 밸런스
      );
    } catch (e) {
      debugPrint('Compress error: $e');
      return null;
    }
  }

  // Firebase 업로드
  static Future<String> uploadImage(File file, String fullPath) async {
    try {
      final ref = FirebaseStorage.instance.ref().child(fullPath);
      final metadata = SettableMetadata(contentType: 'image/jpeg');
      await ref.putFile(file, metadata);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('이미지 업로드 실패: $e');
      rethrow; // 각주: 호출부에서 재처리
    }
  }

  /// 사진 거래 게시글 전용 업로드
  static Future<String> uploadPhotoTradeImage(File file, String userId) async {
    final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final fullPath = 'photo_trades/$fileName';
    return await uploadImage(file, fullPath);
  }

  // ==============================
  //  워터마크(대각선 반복 텍스트) 생성
  // ==============================
  ///
  /// 선택한 사진 위에 대각선 방향으로 텍스트 워터마크를 반복 배치한 이미지를 생성한다.
  /// 반환: 임시파일에 저장된 PNG를 XFile로 반환 (null이면 실패)
  Future<XFile?> createFilledWatermark(
      XFile source, {
        required String watermarkText,
        double opacity = 0.18,      // 텍스트 투명도 (0.16~0.22 권장)
        double paddingFactor = 2.5, // 텍스트 간격 (15~25% 느낌)
        double angleDeg = -45.0,    // 회전 각도(음수면 ↘ 방향)
        bool withStroke = true,     // 외곽선 유사 효과(밝은 배경 가독성↑)
      }) async {
    try {
      final bytes = await source.readAsBytes();
      final original = await painting.decodeImageFromList(bytes);

      final width = original.width.toDouble();
      final height = original.height.toDouble();
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder, ui.Rect.fromLTWH(0, 0, width, height));

      // 1) 원본 먼저 그림
      final paint = ui.Paint();
      canvas.drawImage(original, ui.Offset.zero, paint);

      // 2) 텍스트 스타일 계산
      final shortestSide = math.min(width, height);
      final fontSize = (shortestSide * 0.04).clamp(18.0, 64.0);

      // 3) 텍스트 레이아웃 함수 (채움/외곽선용 별도)
      TextPainter _textPainter(Color color, double alpha) {
        return TextPainter(
          text: TextSpan(
            text: watermarkText,
            style: TextStyle(
              color: color.withOpacity(alpha),
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.left,
        )..layout();
      }

      final tpFill = _textPainter(Colors.white, opacity);
      final tpStroke = _textPainter(
        Colors.black,
        (opacity - 0.06).clamp(0.0, 1.0),
      );

      // 4) 대각선으로 전체 화면 채우기
      final diagonal = math.sqrt(width * width + height * height);
      final stepX = tpFill.width + fontSize * paddingFactor;
      final stepY = tpFill.height + fontSize * paddingFactor;

      // 회전(중심 기준)
      canvas.save();
      canvas.translate(width / 2, height / 2);
      canvas.rotate(angleDeg * math.pi / 180.0);
      canvas.translate(-width / 2, -height / 2);

      for (double y = -diagonal; y < diagonal; y += stepY) {
        for (double x = -diagonal; x < diagonal; x += stepX) {
          final offset = ui.Offset(x, y);
          if (withStroke) {
            // 살짝 어긋난 검은 텍스트로 의사 외곽선
            tpStroke.paint(canvas, offset + const ui.Offset(1, 1));
          }
          tpFill.paint(canvas, offset);
        }
      }
      canvas.restore();

      // 5) 결과 PNG 저장
      final picture = recorder.endRecording();
      final result = await picture.toImage(original.width, original.height);
      final byteData =
      await result.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      final tempDir = await getTemporaryDirectory();
      final filePath = path.join(
        tempDir.path,
        'watermarked_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      final file = await File(filePath).writeAsBytes(
        byteData.buffer.asUint8List(),
        flush: true,
      );
      return XFile(file.path);
    } catch (e, st) {
      debugPrint('createFilledWatermark error: $e\n$st');
      return null;
    }
  }
}

// ===== 공용 다이얼로그/토스트 =====
Future<bool> _showGoToSettingsDialog(
    BuildContext context, {
      required String reason,
    }) async {
  return await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('권한이 필요합니다'),
      content: Text(reason),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('설정으로 이동'),
        ),
      ],
    ),
  ) ??
      false;
}

void _toast(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
}