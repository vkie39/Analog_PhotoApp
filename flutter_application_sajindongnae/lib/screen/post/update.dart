import 'dart:io';
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

import 'package:flutter_application_sajindongnae/models/post_model.dart';
import 'package:flutter_application_sajindongnae/services/post_service.dart';
import 'package:flutter_application_sajindongnae/component/action_button.dart';
import 'package:flutter_application_sajindongnae/component/expandable_fab.dart';
import 'package:flutter_application_sajindongnae/main.dart';
import 'package:flutter_application_sajindongnae/services/image_service.dart';

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
  XFile? _resultImage;
  bool? _isPictureUploaded;
  bool _cropping = false;

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
    _resultImage = null;
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

      if (_resultImage != null) {
        imageUrl = await PostService.uploadImage(File(_resultImage!.path), widget.existingPost!.postId);
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
        uid: widget.existingPost!.uid,
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


  // image_service에서 pickImageFromGallery와 pickImageFromCamera로 
  // 이미지를 가져오면 null여부 확인 후 setState로 화면에 반영
  
  Future<void> _pickImageFromGallery(BuildContext context) async {
    _originalImage = await pickImageFromGallery(context);
    if (_originalImage != null) {
      await _cropImage(_originalImage!.path);
      // 크롭 없이 바로 이미지 삽입할 거면 주석처리된 내용으로 하기
      //setState(() {
      //  _cropedImage = _originalImage; // 크롭, 압축 없이 바로 사용
      //  _isPictureUploaded = true;
      //});
    } else {
      Fluttertoast.showToast(msg: '사진 선택이 취소되었습니다.');
    }
  }

  Future<void> _pickImageFromCamera(BuildContext context) async {
    _originalImage = await pickImageFromCamera(context); // 카메라에서 이미지 촬영
    if (_originalImage != null) {
      setState(() {
        _resultImage = _originalImage; // 크롭, 압축 없이 바로 사용
        _isPictureUploaded = true;
      });
    } else {
      Fluttertoast.showToast(msg: '사진 촬영이 취소되었습니다.');
    }
  }

  Future<void> _pickImageFromFileSystem(BuildContext context) async {
    final file = await pickImageFromFileSystem(context);
    if (file != null) {
      setState(() {
        _resultImage = file;
        _isPictureUploaded = true;
      });
    } else {
      Fluttertoast.showToast(msg: '파일 선택이 취소되었습니다.');
    }
  }


  // 찍거나 가져온 사진 편집(크롭,회전)하는 함수
  Future<void> _cropImage(String imagePath) async {
    if(_cropping) return;  // 크롭 동작을 동시에 여러개 하지 못하도록 막음
    _cropping = true;
    try{
      // 경로 복사
      final normalizedPath = await _toTempFilePath(imagePath);           // 앱의 임시 디렉토리로 경로 복사 -> 좀 더 안전한 접근 
      final croppedFile = await _imageService.cropImage(normalizedPath); // 크롭 결과

      if (croppedFile != null) {
        if (!mounted) return;  // 크롭 처리하는 동안 화면이 없어지지 않았는지 확인
        setState(() {
          _resultImage = XFile(croppedFile.path);
          _isPictureUploaded = true;
        });
      }
    } catch (e, st){
      debugPrint('crop error : $e\n$st');
      Fluttertoast.showToast(msg: '편집 중 오류 발생');
    }finally{_cropping = false;}
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
                          SizedBox(height: (_resultImage != null || (_isPictureUploaded == true && widget.existingPost!.imageUrl != null)) ? 10 : 300),
                        ],
                      ),
                    ),

                    // 이미지 미리보기 및 삭제 버튼
                    if (_resultImage != null || (_isPictureUploaded == true && widget.existingPost!.imageUrl != null)) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 0),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: _resultImage != null
                                  ? Image.file(File(_resultImage!.path), width: double.infinity, fit: BoxFit.cover)
                                  : Image.network(widget.existingPost!.imageUrl!, width: double.infinity, fit: BoxFit.cover),
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
            ActionButton(onPressed: () async => await _pickImageFromCamera(context), icon: Icons.camera_alt),
            ActionButton(onPressed: () async => await _pickImageFromGallery(context), icon: Icons.photo_library),
            ActionButton(onPressed: () async => await _pickImageFromFileSystem(context), icon: Icons.insert_drive_file),
          ],
        ),
      ),
    );
  }
}
