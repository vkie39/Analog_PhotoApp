import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_application_sajindongnae/services/image_service.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final TextEditingController _nicknameController = TextEditingController();
  XFile? _originalImage;
  XFile? _selectedImage;
  bool _cropping = false;
  late ImageService _imageService;
  String? _currentProfileUrl;

  static const String defaultProfileUrl =
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSaU9XZQQJUo7hXDLwGcgbWgxkku3A7aVZEgBFEArMUa6C18WhOcnf4RRTLPrFITajVVNI&usqp=CAU';

  @override
  void initState() {
    super.initState();
    _imageService = ImageService();
    _loadCurrentProfile();
  }

  Future<void> _loadCurrentProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance.doc('users/${user.uid}').get();
    final data = doc.data();
    _nicknameController.text = (data?['nickname'] as String?) ?? '';
    String? url = data?['profileImageUrl'] as String?;
    _currentProfileUrl = url != null ? url + '?ts=${DateTime.now().millisecondsSinceEpoch}' : null;
    setState(() {});
  }

  Future<void> _pickImageOption() async {
    final result = await showModalBottomSheet<int>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('갤러리에서 선택'),
              onTap: () => Navigator.pop(context, 0),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('카메라로 촬영'),
              onTap: () => Navigator.pop(context, 1),
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('기본 이미지로 변경'),
              onTap: () => Navigator.pop(context, 2),
            ),
          ],
        ),
      ),
    );

    switch (result) {
      case 0: // 갤러리
        final picked = await _imageService.pickImageFromGallery();
        if (picked != null) {
          // 이미지 선택 후 정사각형으로 크롭
          final cropped = await _imageService.cropImage(
            picked.path,
            lockSquare: true, // 정사각형 고정 옵션
          );
          if (cropped != null) setState(() => _selectedImage = XFile(cropped.path));
        }
        break;
      case 1: // 카메라
        final picked = await _imageService.takePhoto();
        if (picked != null) {
          final cropped = await _imageService.cropImage(
            picked.path,
            lockSquare: true,
          );
          if (cropped != null) setState(() => _selectedImage = XFile(cropped.path));
        }
        break;
      case 2: // 기본 이미지
        setState(() {
          _selectedImage = null;
          _currentProfileUrl = defaultProfileUrl + '?ts=${DateTime.now().millisecondsSinceEpoch}';
        });
        break;
      default:
        break;
    }
  }


  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String? photoUrl;

    if (_selectedImage != null && _selectedImage!.path != _originalImage?.path) {
      photoUrl = await ImageService.uploadProfileImage(user.uid, File(_selectedImage!.path));
      photoUrl += '?ts=${DateTime.now().millisecondsSinceEpoch}';
    } else if (_selectedImage == null) {
      photoUrl = _currentProfileUrl ?? defaultProfileUrl + '?ts=${DateTime.now().millisecondsSinceEpoch}';
    }

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'nickname': _nicknameController.text.trim(),
      'profileImageUrl': photoUrl,
    }, SetOptions(merge: true));

    Fluttertoast.showToast(msg: '프로필 업데이트 완료');
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/mypage',       // 마이페이지 라우트 이름
      (route) => false, // 기존 화면 스택 전부 제거
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          '프로필 설정',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 20),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImageOption,
              child: CircleAvatar(
                key: ValueKey(_selectedImage?.path ?? _currentProfileUrl ?? 'default'),
                radius: 50,
                backgroundImage: _selectedImage != null
                    ? FileImage(File(_selectedImage!.path))
                    : NetworkImage(_currentProfileUrl ?? defaultProfileUrl) as ImageProvider,
              ),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _nicknameController,
              decoration: InputDecoration(
                labelText: "닉네임",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDBEFC4),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 165
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadiusGeometry.circular(8)
                )
              ),
              child: const Text(
                "저장",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
