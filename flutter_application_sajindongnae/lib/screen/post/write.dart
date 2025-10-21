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
import 'package:firebase_storage/firebase_storage.dart';

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
  final List<String> categoryList = ['자유', '카메라추천', '피드백'];
  late String selectedCategory;
  late ImageService _imageService;
  XFile? _originalImage; // ?는 null의 의미
  XFile? _resultImage;
  bool? _isPictureUploaded;
  bool _isFabExpanded = false;
  bool _cropping = false;


  final TextEditingController titleController = TextEditingController(); // 제목 필드
  final TextEditingController contentController = TextEditingController(); // 내용 필드
  final FocusNode contentFocusNode = FocusNode(); // 내용 필드로 커서 띄우기 위함

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
/*
void submitPost() async {
  // firestore에 저장
  final title = titleController.text.trim(); // 제목
  final content = contentController.text.trim(); // 내용
  final category = selectedCategory; // 카테고리

  if (title.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('제목을 입력해주세요')));
    return;
  } 
  if (content.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('내용을 입력해주세요')));
    return;
  } 

  String? imageUrl;
  
  // 이미지가 있을 경우, ImageService를 통해 Firebase Storage에 업로드하고 URL 받기
  if (_cropedImage != null) {
    try {
      final file = File(_cropedImage!.path);
      imageUrl = await _imageService.uploadImageToFirebase(file); // ✅ uploadImageToFirebase 호출
    } catch (e) {
      print('이미지 업로드 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('이미지 업로드에 실패했어요.')));
      return;
    }
  }

  // 제목, 내용 다 있으면 저장장
  final newPost = PostModel(
    postId: const Uuid().v4(),
<<<<<<< HEAD
    uId: '임시유저ID', // 로그인된 사용자 ID로 수정 필요
=======
    uid: '임시유저ID', // 로그인된 사용자 ID로 수정 필요
>>>>>>> f3b10538e18754fbb41904f5e4e2d78f1f407743
    nickname: '용용선생',
    profileImageUrl: '', // 프로필 이미지 URL
    category: category,
    likeCount: 0, // 기본 0
    commentCount: 0,
    timestamp: DateTime.now(),
    title: title,
    content: content,
    imageUrl: imageUrl, // 이미지 업로드 기능이 추가되면 수정
  );

  try {
    print('업로드 시도');
    await PostService.createPost(newPost);
    print('Post created!');
    if (mounted) {
      Navigator.pop(context, true); // ✅ 정상 업로드 시 작성 페이지 닫기
    } else {
      print('위젯이 죽음');
    }
  } 
  catch (e) {
    print('예외!!!!!!!!!    $e');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('게시글 등록에 실패했어요. 다시 시도해주세요.')));
  }
}

*/
void submitPost() async {
  // firestore에 저장
  final title = titleController.text.trim(); // 제목
  final content = contentController.text.trim(); // 내용
  final category = selectedCategory; // 카테고리

  if (title.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('제목을 입력해주세요')));
    return;
  }
  if (content.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('내용을 입력해주세요')));
    return;
  }

  String? imageUrl;

  // 이미지 업로드 전 경로 및 파일 존재 여부 확인
  if (_resultImage != null) {
    try {
      final path = _resultImage!.path;
      print('[DEBUG] _cropedImage.path: $path');

      final file = File(path);
      final fileExists = file.existsSync();
      print('[DEBUG] File exists: $fileExists');


      if (!fileExists) {
        throw Exception('파일이 존재하지 않음: $path');
      }

      imageUrl = await ImageService.uploadImage(file, 'post_images/${Uuid().v4()}.jpg');
      print('✅ [DEBUG] 업로드 성공: $imageUrl');
    } catch (e) {
      print('❌ 이미지 업로드 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이미지 업로드에 실패했어요.')),
      );
      return; // 이미지 업로드 실패 시 종료
    }
  }

  final newPost = PostModel(
    postId: const Uuid().v4(),
<<<<<<< HEAD
    uId: '임시지밥ID', // 로그인된 사용자 ID로 수정 필요
    nickname: '스폰지밥',
=======
    uid: '임시유저ID', // 로그인된 사용자 ID로 수정 필요
    nickname: '용용선생',
>>>>>>> f3b10538e18754fbb41904f5e4e2d78f1f407743
    profileImageUrl: '',
    category: category,
    likeCount: 0,
    commentCount: 0,
    timestamp: DateTime.now(),
    title: title,
    content: content,
    imageUrl: imageUrl,
  );

  try {
    print('🔥 업로드 시도');
    await PostService.createPost(newPost);
    print('✅ Post created!');
    if (mounted) {
      Navigator.pop(context, true); // 작성 완료 후 페이지 닫기
    } else {
      print('❗ 위젯이 이미 dispose됨');
    }
  } catch (e) {
    print('❌ 예외 발생: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('게시글 등록에 실패했어요. 다시 시도해주세요.')),
    );
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
            onPressed: () {
              Navigator.pop(context); // 뒤로가기
            },
          ),
          title: Text(
            '글쓰기',
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          actions: [
            TextButton(
              onPressed: submitPost,
              child: const Text(
                '등록',
                style: TextStyle(
                  color: Colors.green, // 완료 텍스트 색상 (예시로 연두 계열)
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        body: Container(
          color: const Color.fromARGB(255, 255, 255, 255),
          child: SingleChildScrollView(
            // 스크롤뷰로 만듦듦
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, // 왼쪽 정렬
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color.fromARGB(255, 203, 227, 167),
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton2<String>(
                      isExpanded: true,
                      value: selectedCategory,
                      items:
                          categoryList.map((String value) {
                            // 드롭 다운 항목 생성
                            return DropdownMenuItem<String>(
                              value: value, // value는 실제값, text는 유저에게 보여지는 라벨벨
                              child: Text(
                                value,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black,
                                ),
                              ),
                            );
                          }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedCategory = newValue!;
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

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          hintText: '제목을 입력해주세요',
                          border: InputBorder.none,
                          hintStyle: TextStyle(
                            color: Color.fromARGB(255, 173, 173, 173),
                          ),
                        ),
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                      ),
                      const Divider(
                        color: Color.fromARGB(255, 173, 173, 173),
                        thickness: 1,
                        height: 24, // 위/아래 간격 조절
                      ),
                      GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: (){
                          FocusScope.of(context).requestFocus(contentFocusNode);
                        },
                        
                          child: Column(
                            children: [
                              TextField(
                                controller: contentController,
                                focusNode: contentFocusNode,
                                decoration: const InputDecoration(
                                  hintText: '내용을 작성해주세요',
                                  border: InputBorder.none,
                                  hintStyle: TextStyle(
                                    color: Color.fromARGB(255, 173, 173, 173),
                                  ),
                                ),
                                maxLines: null,
                                keyboardType: TextInputType.multiline,
                              ),
                              SizedBox(height: _resultImage != null? 10:300)

                            ],
                          ),
                      ),
                      
                      if (_resultImage != null) ...[
                        const SizedBox(height: 0),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 0),
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
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 20,
                                    ),
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
        ),
        floatingActionButton: ExpandableFab(
          distance: 100.0,
          children: [
            ActionButton(
              onPressed: () async{
                await _pickImageFromCamera(context);

              },
              icon: Icons.camera_alt,
            ),
            ActionButton(
              onPressed: () async{
                await _pickImageFromGallery(context);
              },
              icon: Icons.photo_library,
            ),
            ActionButton(
              onPressed:() async{
                await _pickImageFromFileSystem(context);
              },
              icon: Icons.insert_drive_file,
            ),
          ],
        ),
      ),
    );
  }
}

<<<<<<< HEAD
=======
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../services/post_service.dart';
import '../../models/post_model.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
// import 'package:permission_handler/permission_handler.dart'; // 권한 요청용 (주석처리됨)

enum BlockType { text, image }

class ContentBlock {
  BlockType type;
  String? text;
  File? imageFile;

  ContentBlock.text([this.text])
      : type = BlockType.text,
        imageFile = null;

  ContentBlock.image(this.imageFile)
      : type = BlockType.image,
        text = null;

  Map<String, dynamic> toJson() => {
        'type': type.toString().split('.').last,
        'value': type == BlockType.text ? text : imageFile?.path,
      };
}

class WriteScreen extends StatefulWidget {
  final String category;

  const WriteScreen({super.key, required this.category});

  @override
  State<WriteScreen> createState() => _WriteScreenState();
}

class _WriteScreenState extends State<WriteScreen> {
  final List<String> categoryList = ['자유', '카메라추천', '피드백'];
  late String selectedCategory;

  final TextEditingController titleController = TextEditingController();
  final List<ContentBlock> contentBlocks = [];
  final Map<int, TextEditingController> textControllers = {};

  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    selectedCategory = widget.category;
    contentBlocks.add(ContentBlock.text(''));
  }

  Future<void> addImageAtCursor(int index) async {
    print('addImageAtCursor called for index: $index');

    if (!textControllers.containsKey(index)) {
      print('❗ textControllers[$index] not found');
      return;
    }

    // 권한 요청 코드 주석처리됨
    // await Permission.photos.request();

    final picked = await picker.pickImage(source: ImageSource.gallery);
    print('Image picked: ${picked?.path}');

    if (picked != null) {
      final controller = textControllers[index]!;
      final cursor = controller.selection.baseOffset;
      final fullText = controller.text;

      final before = cursor >= 0 ? fullText.substring(0, cursor) : fullText;
      final after = cursor >= 0 ? fullText.substring(cursor) : '';

      setState(() {
        contentBlocks.removeAt(index);
        contentBlocks.insertAll(index, [
          ContentBlock.text(before),
          ContentBlock.image(File(picked.path)),
          ContentBlock.text(after),
        ]);
      });
    }
  }

  void submitPost() async {
    final title = titleController.text.trim();
    final validBlocks = contentBlocks
        .where((b) => (b.type == BlockType.text && b.text!.trim().isNotEmpty) ||
                      (b.type == BlockType.image && b.imageFile != null))
        .toList();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('제목을 입력해주세요')));
      return;
    } else if (validBlocks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('내용을 입력해주세요')));
      return;
    }

    final post = PostModel(
      postId: const Uuid().v4(),
      uid: 'tempUser',
      nickname: 'tempNick',
      profileImageUrl: '',
      category: selectedCategory,
      likeCount: 0,
      commentCount: 0,
      timestamp: DateTime.now(),
      title: title,
      content: validBlocks.map((e) => e.toJson()).toList().toString(),
      imageUrl: null,
    );

    try {
      await PostService.createPost(post);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('적용 중 오류가 발생했습니다. 다시 시도해주세요.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('글쓰기', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        leading: BackButton(color: Colors.black),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: submitPost,
            child: const Text('등록', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCategoryDropdown(),
            const SizedBox(height: 20),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(hintText: '제목을 입력해주세요', border: InputBorder.none),
              maxLines: null,
            ),
            const Divider(),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: contentBlocks.length,
              itemBuilder: (context, index) {
                final block = contentBlocks[index];
                if (block.type == BlockType.text) {
                  if (!textControllers.containsKey(index)) {
                    textControllers[index] = TextEditingController(text: block.text);
                  }
                  final controller = textControllers[index]!;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: controller,
                            maxLines: null,
                            onChanged: (value) => block.text = value,
                            decoration: const InputDecoration.collapsed(hintText: "내용을 입력해주세요"),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.image, size: 20),
                          onPressed: () => addImageAtCursor(index),
                        )
                      ],
                    ),
                  );
                } else {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Image.file(block.imageFile!),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        border: Border.all(color: const Color.fromARGB(255, 203, 227, 167)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton2<String>(
          isExpanded: true,
          value: selectedCategory,
          items: categoryList.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value, style: const TextStyle(fontSize: 12, color: Colors.black)),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              selectedCategory = newValue!;
            });
          },
          buttonStyleData: const ButtonStyleData(
            padding: EdgeInsets.symmetric(horizontal: 8),
            height: 40,
            width: 110,
          ),
          dropdownStyleData: DropdownStyleData(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.white),
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
    );
  }
}
*/
>>>>>>> f3b10538e18754fbb41904f5e4e2d78f1f407743
