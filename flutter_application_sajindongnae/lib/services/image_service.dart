import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';

import 'package:permission_handler/permission_handler.dart'; // 카메라, 갤러리 권한 요청 패키지
import 'package:image_picker/image_picker.dart'; // 사진 찍거나, 갤러리의 사진을 가져오기 위한 패키지
import 'package:image_cropper/image_cropper.dart'; // 이미지 자르기 
import 'package:flutter_image_compress/flutter_image_compress.dart'; // 이미지 압축
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:developer';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;





/* !이미지 권한! 
 * 권한 확보 순서
 * 이미지 권한은 위치 권한 처럼 [사용중에만 허용->항상 허용]으로 단계적 권한을 요구하지 않음
 * 단순히 허용/불가 만 검사하면 됨. 다만 버전에 따라 요구하는 권한이 다르기 때문에 해당 처리를 할 필요가 있음
 * 
 * 버전 조회 - sdk 13이상은 바로 갤러리로 이동 - 12이하는 권한 확인
 */
final ImagePicker _picker = ImagePicker(); // ImagePicker 객체 생성

  // Android SDK 버전 조회 (ios 등은 null)
  // 13 이상에서는 시스템 photo picker를 도입하여 권한이 불필요해짐 -> 버전에 따라 다른 처리 필요
  // READ_EXTERNAL_STORAGE대신 세분화된 미디어 권한을 요청(이건 플러터 패키지가 알아서 하는듯)
  Future<int?> _androidSdkInt() async {
    if(!Platform.isAndroid) return null;
    final info = await DeviceInfoPlugin().androidInfo; // 안드로이드 정보 가져오기
    return info.version.sdkInt;                        // sdk 버전 정보만 가져오기
  }

  // 갤러리, 파일 접근 권한 확인
  Future<bool> _ensureLegacyStoragePermission(BuildContext context) async {
    final st = await Permission.storage.status;    // 갤러리 권한 상태 가져옴
    if (st.isGranted) return true;                 // [허용] 이면 true

    if (st.isPermanentlyDenied){
      final go = await _showGoToSettingsDialog(context, reason: '사진을 불러오려면 갤러리 접근 권한이 필요합니다.\n설정에서 권한을 확인해주세요');
      if (go) await openAppSettings(); // 설정 화면 열기
      return false;
    }

    final req = await Permission.storage.request();
    if (req.isGranted) return true;
    if (req.isPermanentlyDenied){
      final go = await _showGoToSettingsDialog(context, reason: '갤러리 접근 권한이 거절되었습니다.\n설정에서 권한을 허용해주세요');
      if (go) await openAppSettings(); // 설정 화면 열기
    }else {
        _toast(context, '설정에서 갤러리 접근 권한을 허용할 수 있습니다');
      }
      return false;
  }


  // -------------------------------
  //  갤러리 관련
  // -------------------------------


  // 갤러리 사진 선택 (한 장)
  // 13이상 -> 권한 불필요
  // 12이하 -> 권한 요청
  Future<XFile?> pickImageFromGallery(BuildContext context) async {
    final sdk = await _androidSdkInt();                             // 위 함수로 안드로이드 정보 return받옴
    print(sdk);

    if (sdk == null){
      return await _picker.pickImage(source: ImageSource.gallery);  
    }

    if (sdk >= 33){
      return await _picker.pickImage(source: ImageSource.gallery);  // 갤러리에서 바로 이미지 가져옴
    }       
    else{
      final ok = await _ensureLegacyStoragePermission(context);
      if(ok) return await _picker.pickImage(source: ImageSource.gallery); 

    }
  }

  // 갤러리 사진 선택 (여러 장)
  Future<List<XFile?>> pickMultiImagesFromGallery(BuildContext context) async {
    final sdk = await _androidSdkInt();                             // 위 함수로 안드로이드 정보 return받옴
    List<XFile> files = [];

    if (sdk == null || sdk >= 33){
      files =  await _picker.pickMultiImage();
    }       
    else{
      final ok = await _ensureLegacyStoragePermission(context);
      if(ok) files =  await _picker.pickMultiImage();
      return [];
    }
    if (files.length > 4){
      _toast(context, '최대 4장까지만 선택할 수 있습니다. 처음 4장만 사용됩니다.');
      return files.sublist(0,4);
    }
    return files;
  }


  // -------------------------------
  //  카메라 관련
  // -------------------------------


  // 카메라에서 사진 찍기
  Future<XFile?> pickImageFromCamera(BuildContext context) async {
    final ok = await _ensureCameraPermission(context);
    if (!ok) return null;
    return await _picker.pickImage(source: ImageSource.camera);        // 카메라에서 이미지 가져옴
  }

  // 카메라 권한 확인-요청
  Future<bool> _ensureCameraPermission(BuildContext context) async {
    final st = await Permission.camera.status;

    if (st.isGranted) return true;
    if (st.isPermanentlyDenied){
      final go = await _showGoToSettingsDialog(context, reason: '사진 촬영을 위해 카메라 접근 권한이 필요합니다.\n설정에서 권한을 확인해주세요');
      if (go) await openAppSettings(); // 설정 화면 열기
      return false;
    } 

    final req = await Permission.camera.request();
    if (req.isGranted) return true;
    if (req.isPermanentlyDenied){
      final go = await _showGoToSettingsDialog(context, reason: '카메라 접근 권한이 거절되었습니다.\n설정에서 권한을 허용해주세요');
      if (go) await openAppSettings(); // 설정 화면 열기
    }else {
        _toast(context, '설정에서 권한을 허용할 수 있습니다');
      }
      return false;


  }


  // -------------------------------
  //  파일 관련
  // -------------------------------


  // 파일 사진 선택 (한 장)
  // 13이상 -> 권한 불필요
  // 12이하 -> 권한 요청
  Future<XFile?> pickImageFromFileSystem(BuildContext context) async {
    final sdk = await _androidSdkInt();                             // 위 함수로 안드로이드 정보 return받옴
    print(sdk);
    if(sdk != null && sdk <= 32){
      final ok = await _ensureLegacyStoragePermission(context);
      if(!ok) return null;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false
      );

    if (result==null || result.files.isEmpty) return null;  // result는 FilePickerResult 타입

    final f = result.files.single.path;                     // 선택된 파일 리스트 중 하나의 실제 경로
    if(f != null){
      return XFile(f!);
    }
    return null;
    
   
  }



class ImageService {

  // 접근 권한 요청에 대한 결과 반환
  Future<bool> requestPermission() async {
    bool storage = await Permission.storage.request().isGranted; // 갤러리
    bool camera = await Permission.camera.request().isGranted;   // 카메라


    if (!storage || !camera) return false; // 하나라도 거부되면 false
    return true;
  }

  // 카메라 접근 권한 요청에 대한 결과 반환
  Future<bool> requestPermissionForCamera() async {
    bool camera = await Permission.camera.request().isGranted; // 카메라
    if (!camera) return false; // 거부되면 false
    return true;
  }

  // 갤러리 접근 권한 요청에 대한 결과 반환
  Future<bool> requestPermissionForGallery() async {
    bool storage = await Permission.storage.request().isGranted; // 갤러리
    if (!storage) return false; // 하나라도 거부되면 false
    return true;
  }

  // 사진을 찍고 XFile객체 반환, 안찍으면 null
  Future<XFile?> takePhoto() async {
    log('1. 카메라 열기 시도');

    return await _picker.pickImage(source: ImageSource.camera);
  }

  // 갤러리에서 사진을 선택하면 XFile반환, 안고르면 null
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

      return XFile(result.files.single.path!); // image_picker와 호환
    }
    return null;
  }
 
  // 이미지 경로를 받아서 자른 후 결과로 CroppedFile을 반환
  Future<CroppedFile?> cropImage(String imagePath) async {
    try {
      // 원본 확장자 보존
      final ext = path.extension(imagePath).toLowerCase();
      ImageCompressFormat format; // 저장되는 최종 파일 확장자 지정
      if(ext == '.png') {format = ImageCompressFormat.png;}
      else {format = ImageCompressFormat.jpg;}

      final cropped = await ImageCropper().cropImage(
        sourcePath: imagePath,
        compressFormat: format,
        uiSettings: [
          AndroidUiSettings(
            toolbarColor: Colors.white,
            toolbarTitle: '사진 편집',
            toolbarWidgetColor: const Color.fromARGB(255, 0, 0, 0),
            hideBottomControls: false,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
          )
        ]
      );
      return cropped; 

    } catch (e) {
      print('Crop error: $e');
      return null; // 반드시 null 리턴
    }
  }

  // 이미지 경로를 받아서 압축된 이미지 XFile 반환, 예외 발생시 null
  Future<XFile?> compressImage(String imagePath) async {
    try {
      final ext = imagePath.split('.').last;                             
      final outputPath = imagePath.replaceAll(".$ext", '_compressed.webp'); 

      return await FlutterImageCompress.compressAndGetFile(
        imagePath,
        outputPath,
        format: CompressFormat.webp,
        quality: 88,
      );
    } catch (e) {
      print(e);
      return null;
    }
  }

  // uploadImageToFirebase 를 대체하는 uplaodImage함수 -> 좀더 유연한 사용 가능함
  static Future<String> uploadImage(File file, String fullPath) async {
    try {
      final ref = FirebaseStorage.instance.ref().child(fullPath);
      final metadata = SettableMetadata(contentType: 'image/jpeg');
      await ref.putFile(file, metadata);
      return await ref.getDownloadURL();
    } catch (e) {
      print('이미지 업로드 실패: $e');
      rethrow;
    }
  }


  

  /// 사진 거래 게시글 전용 업로드 함수
  static Future<String> uploadPhotoTradeImage(File file, String userId) async {
    final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final fullPath = 'photo_trades/$fileName';
    return await uploadImage(file, fullPath);
  }



}


Future<bool> _showGoToSettingsDialog(BuildContext context, {required String reason}) async {
  return await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('권한이 필요합니다'),
      content: Text(reason),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('설정으로 이동')),
      ],
    ),
  ) ?? false;
}

void _toast(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
}

