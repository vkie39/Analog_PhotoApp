// image_service.dart
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart'; // 카메라, 갤러리 권한 요청 패키지
import 'package:image_picker/image_picker.dart'; // 사진 찍거나, 갤러리의 사진을 가져오기 위한 패키지
import 'package:image_cropper/image_cropper.dart'; // 이미지 자르기 
import 'package:flutter_image_compress/flutter_image_compress.dart'; // 이미지 압축
// 이미지 업로드를 위해 필요
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';


class ImageService {
  final ImagePicker _picker = ImagePicker(); // ImagePicker 객체 생성

  // 접근 권한 요청에 대한 결과 반환
  Future<bool> requestPermission() async {
    bool storage = await Permission.storage.request().isGranted; // 갤러리
    bool camera = await Permission.camera.request().isGranted; // 카메라

    if (!storage || !camera) return false; // 하나라도 거부되면 false
    return true;
  }

  // 사진을 찍고 XFile객체 반환, 안찍으면 null
  Future<XFile?> takePhoto() async {
    return await _picker.pickImage(source: ImageSource.camera);
  }

  // 갤러리에서 사진을 선택하면 XFile반환, 안고르면 null
  Future<XFile?> pickImageFromGallery() async {
    return await _picker.pickImage(source: ImageSource.gallery);
  }

  Future<XFile?> pickImageFromFileSystem() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result != null && result.files.single.path != null) {
      return XFile(result.files.single.path!); // image_picker와 호환
    }
    return null;
  }
 
  // 이미지 경로를 받아서 자른 후 결과로 CroppedFile을 반환
  Future<CroppedFile?> cropImage(String imagePath) async {
    try {
      final cropped = await ImageCropper().cropImage(
        sourcePath: imagePath,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        compressFormat: ImageCompressFormat.jpg,
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
