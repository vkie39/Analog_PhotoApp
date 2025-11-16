import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import 'package:cloud_firestore/cloud_firestore.dart';   // [수정] Firestore 닉네임/프로필 조회를 위해 추가

import 'package:flutter_application_sajindongnae/component/action_button.dart';
import 'package:flutter_application_sajindongnae/component/expandable_fab.dart';
import 'package:flutter_application_sajindongnae/main.dart';
import 'package:flutter_application_sajindongnae/services/image_service.dart';
import 'package:flutter_application_sajindongnae/models/post_model.dart';
import 'package:flutter_application_sajindongnae/services/post_service.dart';

class WriteScreen extends StatefulWidget {
  final String category;
  
  const WriteScreen({super.key, required this.category});
  
  @override
  State<WriteScreen> createState() => _WriteScreenState();
}

class _WriteScreenState extends State<WriteScreen> {
  // 로그인한 사용자
  final User? user = FirebaseAuth.instance.currentUser;

  final List<String> categoryList = ['자유', '카메라추천', 'QnA'];
  late String selectedCategory;
  late ImageService _imageService;

  XFile? _originalImage;
  XFile? _resultImage;
  bool? _isPictureUploaded;
  bool _cropping = false;

  bool _isFabExpanded = false;

  final TextEditingController titleController = TextEditingController();
  final TextEditingController contentController = TextEditingController();
  final FocusNode contentFocusNode = FocusNode();

  @override
  void dispose() {
    titleController.dispose();
    contentController.dispose();
    contentFocusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    selectedCategory = widget.category;
    _imageService = ImageService();
  }

  // -------------------------------------------------------------------
  // [수정된 submitPost] Firestore users/{uid}에서 nickname / profileImageUrl 읽기 추가
  // -------------------------------------------------------------------
  void submitPost() async {
    final title = titleController.text.trim();
    final content = contentController.text.trim();
    final category = selectedCategory;

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('제목을 입력해주세요')),
      );
      return;
    }

    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('내용을 입력해주세요')),
      );
      return;
    }

    // -------------------------------------------------------------------
    // [수정] Firestore users/{uid}에서 nickname, profileImageUrl 읽기
    // -------------------------------------------------------------------
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('로그인이 필요합니다.')),
      );
      return;
    }

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();

    final nickname = userDoc.data()?['nickname'] ?? '사용자';
    final profileImageUrl = userDoc.data()?['profileImageUrl'] ?? '';

    print("[DEBUG] nickname=$nickname, profile=$profileImageUrl");

    // -------------------------------------------------------------------
    // 이미지 업로드
    // -------------------------------------------------------------------
    String? imageUrl;

    if (_resultImage != null) {
      try {
        final file = File(_resultImage!.path);

        if (!file.existsSync()) {
          throw Exception('파일이 존재하지 않습니다.');
        }

        imageUrl = await ImageService.uploadImage(
          file,
          'post_images/${Uuid().v4()}.jpg',
        );

      } catch (e) {
        print("이미지 업로드 실패: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이미지 업로드 실패')),
        );
        return;
      }
    }

    // -------------------------------------------------------------------
    // Firestore에 저장할 PostModel 생성
    // nickname / profileImageUrl 이 Firestore 값 기반으로 수정됨
    // -------------------------------------------------------------------
    final newPost = PostModel(
      postId: const Uuid().v4(),
      uid: user!.uid,
      nickname: nickname,                 // [수정]
      profileImageUrl: profileImageUrl,   // [수정]
      category: category,
      likeCount: 0,
      commentCount: 0,
      timestamp: DateTime.now(),
      title: title,
      content: content,
      imageUrl: imageUrl,
    );

    try {
      print("업로드 시도");
      await PostService.createPost(newPost);
      print("업로드 성공");

      if (mounted) Navigator.pop(context, true);

    } catch (e) {
      print("예외: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('게시글 등록 실패')),
      );
    }
  }

  // -------------------------------------------------------------------
  // 이미지 편집용 함수들
  // -------------------------------------------------------------------
  Future<String> _toTempFilePath(String pickedPath) async {
    final bytes = await XFile(pickedPath).readAsBytes();
    final ext = path.extension(pickedPath).isNotEmpty ? path.extension(pickedPath) : '.jpg';
    final dir = await getTemporaryDirectory();
    final f = File('${dir.path}/${DateTime.now().millisecondsSinceEpoch}$ext');
    await f.writeAsBytes(bytes, flush: true);
    return f.path;
  }

  Future<void> _cropImage(String imagePath) async {
    if (_cropping) return;
    _cropping = true;

    try {
      final normalizedPath = await _toTempFilePath(imagePath);
      final croppedFile = await _imageService.cropImage(normalizedPath);

      if (croppedFile != null) {
        if (!mounted) return;
        setState(() {
          _resultImage = XFile(croppedFile.path);
          _isPictureUploaded = true;
        });
      }
    } catch (e, st) {
      print('crop error: $e\n$st');
      Fluttertoast.showToast(msg: '편집 중 오류 발생');
    } finally {
      _cropping = false;
    }
  }

  Future<void> _pickImageFromGallery(BuildContext context) async {
    _originalImage = await pickImageFromGallery(context);
    if (_originalImage != null) {
      await _cropImage(_originalImage!.path);
    }
  }

  Future<void> _pickImageFromCamera(BuildContext context) async {
    _originalImage = await pickImageFromCamera(context);
    if (_originalImage != null) {
      setState(() {
        _resultImage = _originalImage;
        _isPictureUploaded = true;
      });
    }
  }

  Future<void> _pickImageFromFileSystem(BuildContext context) async {
    final file = await pickImageFromFileSystem(context);
    if (file != null) {
      setState(() {
        _resultImage = file;
        _isPictureUploaded = true;
      });
    }
  }

  // -------------------------------------------------------------------
  // UI 구성
  // -------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            '글쓰기',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          actions: [
            TextButton(
              onPressed: submitPost,   // [수정된 submitPost 적용됨]
              child: Text(
                '등록',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),

        body: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 카테고리 드롭다운
              Container(
                padding: EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  border: Border.all(color: Color.fromARGB(255, 203, 227, 167)),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton2<String>(
                    value: selectedCategory,
                    items: categoryList.map((value) {
                      return DropdownMenuItem(
                        value: value,
                        child: Text(
                          value,
                          style: TextStyle(fontSize: 12, color: Colors.black),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedCategory = value!;
                      });
                    },
                  ),
                ),
              ),

              SizedBox(height: 20),

              // 입력 필드들
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  hintText: '제목을 입력해주세요',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey),
                ),
              ),

              Divider(color: Colors.grey),

              TextField(
                controller: contentController,
                focusNode: contentFocusNode,
                decoration: InputDecoration(
                  hintText: '내용을 작성해주세요',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey),
                ),
                maxLines: null,
              ),

              SizedBox(height: 20),

              if (_resultImage != null)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          File(_resultImage!.path),
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _resultImage = null;
                              _isPictureUploaded = false;
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.close, color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),

        floatingActionButton: ExpandableFab(
          distance: 100.0,
          children: [
            ActionButton(
              onPressed: () async => await _pickImageFromCamera(context),
              icon: Icons.camera_alt,
            ),
            ActionButton(
              onPressed: () async => await _pickImageFromGallery(context),
              icon: Icons.photo_library,
            ),
            ActionButton(
              onPressed: () async => await _pickImageFromFileSystem(context),
              icon: Icons.insert_drive_file,
            ),
          ],
        ),
      ),
    );
  }
}
