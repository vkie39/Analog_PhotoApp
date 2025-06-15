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

  // 이미지 파일을 Firebase Storage에 업로드하고 다운로드 URL을 반환하는 함수
  Future<String> uploadImageToFirebase(File file) async {
    try {
     // 1. 파일 이름을 UUID 기반으로 고유하게 생성 (중복 방지)
     final fileName = 'post_images/${const Uuid().v4()}.jpg';

      // 2. Storage에 업로드할 위치 참조 객체 생성
      final ref = FirebaseStorage.instance.ref().child(fileName);

      // 3. 업로드할 이미지의 메타데이터 설정
      //    - contentType: 이미지의 타입 명시 (생략 시 Android에서 오류 발생 가능)
      final metadata = SettableMetadata(contentType: 'image/jpeg'); // 중요! Android에서 null 오류 방지함

      // 4. 파일을 Storage에 업로드 (메타데이터와 함께)
      await ref.putFile(file, metadata);

      // 5. 업로드가 완료되면 다운로드 URL 반환
      return await ref.getDownloadURL();

    } catch (e) {
      // 오류 발생 시 콘솔에 출력 후 상위로 전달
      print('이미지 업로드 실패: $e');
      rethrow; // 호출한 쪽에서 catch할 수 있도록 예외 다시 던짐
    }
  }


}
