import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_sajindongnae/component/action_button.dart';
import 'package:flutter_application_sajindongnae/component/expandable_fab.dart';
import 'package:flutter_application_sajindongnae/main.dart';
import 'package:flutter_application_sajindongnae/services/image_service.dart';
import 'package:uuid/uuid.dart';
import '../../services/post_service.dart';
import '../../models/post_model.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:fluttertoast/fluttertoast.dart';

class UpdateScreen extends StatefulWidget {
  final PostModel? existingPost;

  const UpdateScreen({super.key, this.existingPost});

  @override
  State<UpdateScreen> createState() => UpdateScreenState();
}

class UpdateScreenState extends State<UpdateScreen> {
  final List<String> categoryList = ['자유', '카메라추천', '피드백'];
  late String _selectedCategory;
  late ImageService _imageService;
  XFile? _originalImage;
  XFile? _cropedImage;
  bool? _isPictureUploaded;

  late TextEditingController _titleController;
  late TextEditingController _contentController;

  final FocusNode contentFocusNode = FocusNode(); // 내용 필드로 커서 띄우기 위함

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    contentFocusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.existingPost!.title);
    _contentController = TextEditingController(text: widget.existingPost!.content);

    _selectedCategory = widget.existingPost!.category;
    _imageService = ImageService();

    // 기존 이미지 유무 반영
    _cropedImage = null;
    _isPictureUploaded = widget.existingPost!.imageUrl != null;
  }


  void updatePost() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    final category = _selectedCategory;

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('제목을 입력해주세요')));
      return;
    }
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('내용을 입력해주세요')));
      return;
    }

    try {
      String? imageUrl = widget.existingPost!.imageUrl;

      if (_cropedImage != null) {
        imageUrl = await PostService.uploadImage(File(_cropedImage!.path), widget.existingPost!.postId);
      } else if (_isPictureUploaded == false) {
        // 이미지 삭제한 경우
        imageUrl = null;
      }

      final updatedData = {
        'title': title,
        'content': content,
        'category': category,
        'updatedAt': DateTime.now(),
        'imageUrl': imageUrl,
      };

      await PostService.updatePost(widget.existingPost!.postId, updatedData);

      Fluttertoast.showToast(msg: '게시글이 수정되었습니다.');

      final updatedPost = PostModel(
        postId: widget.existingPost!.postId,
        uId: widget.existingPost!.uId,
        nickname: widget.existingPost!.nickname,
        profileImageUrl: widget.existingPost!.profileImageUrl,
        category: category,
        likeCount: widget.existingPost!.likeCount,
        commentCount: widget.existingPost!.commentCount,
        timestamp: widget.existingPost!.timestamp,
        title: title,
        content: content,
        imageUrl: imageUrl,
      );

      Navigator.pop(context, updatedPost);
    } catch (e) {
      Fluttertoast.showToast(msg: '게시글 수정 중 오류가 발생했습니다.');
    }
  }


  Future<void> _requestPermission() async {
    await _imageService.requestPermission();
  }

  // 디바이스 갤러리에서 사진 가져오기
  Future<void> _pickImageFromGallery(BuildContext context) async {
    _originalImage = await _imageService.pickImageFromGallery();
    if (_originalImage != null) {
      setState(() {
        _cropedImage = _originalImage;
        _isPictureUploaded = true;
      });
    } else {
      Fluttertoast.showToast(msg: '사진 선택이 취소되었습니다.');
    }
  }

  Future<void> _takePhoto(BuildContext context) async {}
  Future<void> _pickImageFromFileSystem(BuildContext context) async {}

  // 사진 자르고 압축
  Future<void> _cropAndCompressImage(String imagePath) async {
    final croppedFile = await _imageService.cropImage(imagePath);
    if (croppedFile != null) {
      _cropedImage = await _imageService.compressImage(croppedFile.path);
      setState(() {
        _isPictureUploaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final globalContext = Globals.navigatorKey.currentContext;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 255, 255, 255),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            '글수정',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          actions: [
            TextButton(
              onPressed: updatePost,
              child: const Text(
                '수정',
                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 카테고리 드롭다운
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color.fromARGB(255, 203, 227, 167)),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton2<String>(
                    isExpanded: true,
                    value: _selectedCategory,
                    items: categoryList.map((value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value,
                          style: const TextStyle(fontSize: 12, color: Colors.black),
                        ),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedCategory = newValue!;
                      });
                    },
                    buttonStyleData: const ButtonStyleData(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      height: 40,
                      width: 110,
                    ),
                    dropdownStyleData: DropdownStyleData(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.white,
                      ),
                      offset: const Offset(0, -5),
                    ),
                    iconStyleData: const IconStyleData(
                      icon: Icon(Icons.arrow_drop_down),
                      iconSize: 24,
                      iconEnabledColor: Colors.black,
                    ),
                    menuItemStyleData: const MenuItemStyleData(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      height: 40,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 제목/내용 입력란
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        hintText: '제목을 입력해주세요',
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: Color.fromARGB(255, 173, 173, 173)),
                      ),
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                    ),
                    const Divider(
                      color: Color.fromARGB(255, 173, 173, 173),
                      thickness: 1,
                      height: 24,
                    ),
                    GestureDetector(
                      onTap: () => FocusScope.of(context).requestFocus(contentFocusNode),
                      child: Column(
                        children: [
                          TextField(
                            controller: _contentController,
                            focusNode: contentFocusNode,
                            decoration: const InputDecoration(
                              hintText: '내용을 작성해주세요',
                              border: InputBorder.none,
                              hintStyle: TextStyle(color: Color.fromARGB(255, 173, 173, 173)),
                            ),
                            maxLines: null,
                            keyboardType: TextInputType.multiline,
                          ),
                          SizedBox(height: (_cropedImage != null || (_isPictureUploaded == true && widget.existingPost!.imageUrl != null)) ? 10 : 300),
                        ],
                      ),
                    ),

                    // 이미지 미리보기 및 삭제 버튼
                    if (_cropedImage != null || (_isPictureUploaded == true && widget.existingPost!.imageUrl != null)) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 0),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: _cropedImage != null
                                  ? Image.file(File(_cropedImage!.path), width: double.infinity, fit: BoxFit.cover)
                                  : Image.network(widget.existingPost!.imageUrl!, width: double.infinity, fit: BoxFit.cover),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _cropedImage = null;
                                    _isPictureUploaded = false;
                                  });
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
        floatingActionButton: ExpandableFab(
          distance: 100.0,
          children: [
            ActionButton(onPressed: () async => await _takePhoto(context), icon: Icons.camera_alt),
            ActionButton(onPressed: () async => await _pickImageFromGallery(context), icon: Icons.photo_library),
            ActionButton(onPressed: () async => await _pickImageFromFileSystem(context), icon: Icons.insert_drive_file),
          ],
        ),
      ),
    );
  }
}
