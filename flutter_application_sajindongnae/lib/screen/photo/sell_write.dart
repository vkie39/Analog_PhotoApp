import 'dart:io';
import 'dart:typed_data';

import 'package:image_editor_plus/image_editor_plus.dart';
import 'package:image_editor_plus/options.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_sajindongnae/screen/photo/location_select.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter_application_sajindongnae/screen/photo/tag_select.dart';
import 'package:flutter_application_sajindongnae/services/image_service.dart';
import 'package:flutter_application_sajindongnae/services/permission_service.dart';
import 'package:flutter_application_sajindongnae/models/tag_model.dart';
import 'package:flutter_application_sajindongnae/models/location_model.dart';
import 'package:flutter_application_sajindongnae/services/photo_trade_service.dart';
import 'package:flutter_application_sajindongnae/models/photo_trade_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Form을 관리하기 위한 키 (입력칸이 빈칸인지, 숫자인지 확인하고 업로드 하는 용도) -> 글로벌 키
final _formKey = GlobalKey<FormState>();

class SellWriteScreen extends StatefulWidget {
  // 화면이 바뀌는 경우가 많으므로 StatefulWidget 사용
  final PhotoTradeModel? initialPhoto;
  const SellWriteScreen({
    super.key,
    this.initialPhoto, // null이면 새 글 작성, not null이면 수정 모드
  });

  bool get isEditing => initialPhoto != null; // 편하게 쓰기 위한 getter

  @override
  State<SellWriteScreen> createState() => _SellWriteScreenState();
}

class _SellWriteScreenState extends State<SellWriteScreen> {
  // 선택한 이미지 파일
  XFile? _originalImage;
  XFile? _selectedImage;
  bool _cropping = false;
  late ImageService _imageService;

  // 선택된 위치
  LatLng? pos;

  String _selectedLocation = '';
  LatLng? _selectedPosition;

  // 선택된 태그
  SelectedTagState _selectedTagState =
      SelectedTagState(); // 선택된 태그 상태 관리 모델 (붕어빵 하나. 초기값은 빈 상태)

  // 선택된 태그 리스트 (태그 UI 표시용)
  // getter로 정의하여 _selectedTagState가 변경될 때마다 자동으로 최신 태그 리스트를 반환
  List<String> get tagList => [
    ..._selectedTagState
        .singleTags
        .values, // 단일 선택 태그들 -> ...은 스프레드 연산자로 컬렉션을 펼쳐 다른 컬렉션에 삽입할 때 사용함(단일 태그와 다중 태그를 합치는 역할)
    ..._selectedTagState.multiTags.values.expand(
      (set) => set,
    ), // 다중 선택 태그들 (expand는 Iterable의 메서드로 Set을 펼쳐서 리스트로 변환)
  ];

  void _removeTag(String tag) {
    // 1) 현 상태의 복사본 만들기 (맵과 Set 모두 불변이므로 수정하려면 복사본 필요)
    final newSingleTags = Map<String, String>.from(
      _selectedTagState.singleTags,
    );
    final newMultiTags = _selectedTagState.multiTags.map(
      (key, value) => MapEntry(key, Set<String>.from(value)),
    );

    // 2) 단일 선택에서 태그 제거
    String? singleKeyToRemove;
    newSingleTags.forEach((sectionId, selectedTag) {
      if (selectedTag == tag) {
        singleKeyToRemove = sectionId;
      }
    });
    if (singleKeyToRemove != null) {
      newSingleTags.remove(singleKeyToRemove);
    }

    // 3) 다중 선택에서 태그 제거
    newMultiTags.removeWhere((key, set) {
      // 반환값이 true이면 key와 value(set)을 삭제
      // 1. set에서 tag제거
      set.remove(tag);
      // 2. 섹션이 비었으면 true리턴 -> 맵에서 key제거
      return set.isEmpty;
    });
    /*
    // 3) 다중 선택에서 태그 제거
    for(final entry in newMultiTags.entries.toList()){  // entries = [MapEntry('camera_type',{'sony', 'canon'}), MapEntry..]
      final set = entry.value;                          // entry = MapEntry('camera_type',{'sony', 'canon'})
      if(set.contains(tag)){                            // set = {'sony', 'canon'}
        set.remove(tag);
        if(set.isEmpty){
          newMultiTags.remove(entry.key);               // 'camera_type'이 비어있으면  'camera_type'이라는 key자체를 삭제
        }
      }
    }
*/
    setState(() {
      _selectedTagState = SelectedTagState(
        singleTags: newSingleTags,
        multiTags: newMultiTags,
      );
    });
  }

  // 태그 선택 화면으로 이동하고 선택된 태그 리스트를 받아오는 함수
  Future<void> _openTagSelector(BuildContext context) async {
    // 비동기 함수. 그래서 future로 선언 (이후에 값이 돌아온다는 의미)
    final result = await Navigator.push<SelectedTagState>(
      context,
      MaterialPageRoute(
        builder:
            (_) => TagSelectionScreen(
              initialState: _selectedTagState, // 현재 선택 상태 전달
              forceMultiSelect: false, // 섹션 규칙 그대로 (기본값)
              title: '태그 선택',
              showAppBar: true,
            ),
      ),
    );

    // TagSelectionScreen에서 선택된 태그를 받아와서 상태 업데이트
    if (result != null) {
      // result가 null이 아니면 (태그를 선택하고 돌아왔을 때)
      setState(() {
        _selectedTagState = result; // 선택된 태그 상태 업데이트
      });
    }
  }

  // 위치 선택 화면으로 이동하고 선택된 위치를 받아오는 함수
  Future<void> _openLocationSelector(BuildContext context) async {
    final result = await Navigator.push<LocationPickResult>(
      context,
      MaterialPageRoute(
        builder:
            (context) => LocationSelectScreen(
              initialPosition: pos,
              initialAddress:
                  locationController.text.isEmpty
                      ? locationController.text
                      : null,
            ),
      ),
    );

    // LocationSelectScreen 선택된 위치를 받아와서 상태 업데이트
    if (result != null) {
      setState(() {
        locationController.text = result.address; // 선택된 상태 업데이트
        pos = result.position;
      });
    }
  }

  // 컨트롤러 (입력칸 제어용)
  final TextEditingController photoNameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController locationController = TextEditingController();

  // 공통 InputDecoration 스타일 정의 (입력칸 스타일)
  static final baseDecoration = InputDecoration(
    labelStyle: TextStyle(
      fontSize: 14,
      color: Color.fromARGB(255, 136, 136, 136),
    ),
    hintStyle: TextStyle(
      fontSize: 10,
      color: Color.fromARGB(255, 136, 136, 136),
    ),
    enabledBorder: UnderlineInputBorder(
      borderSide: BorderSide(
        color: Color.fromARGB(255, 221, 221, 221),
        width: 1.5,
      ),
    ),
    focusedBorder: UnderlineInputBorder(
      borderSide: BorderSide(
        color: Color.fromARGB(255, 136, 136, 136),
        width: 1.5,
      ),
    ),
  );

  @override
  void dispose() {
    // 컨트롤러 해제 (메모리 누수 방지)
    photoNameController.dispose();
    priceController.dispose();
    descriptionController.dispose();
    locationController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _imageService = ImageService();

    final initial = widget.initialPhoto;
    if (initial != null) {
      // 1) 기본 텍스트 필드들
      photoNameController.text = initial.title;
      priceController.text = initial.price.toString();
      descriptionController.text = initial.description;
      locationController.text = initial.location;
      pos = initial.position;

      // 2) 태그 복원: section id를 'restored' 같은 가짜가 아니라
      //    실제 tagSections에서 찾아서 제대로 나누기
      final Map<String, String> restoredSingle = {};
      final Map<String, Set<String>> restoredMulti = {};

      for (final tag in initial.tags) {
        // 이 태그가 포함된 섹션 찾기
        final section = tagSections.firstWhere(
          (s) => s.tags.contains(tag),
          orElse:
              () =>
                  TagSection(id: 'unknown', title: '알 수 없는 섹션', tags: const []),
        );

        if (section.tags.isEmpty) {
          // 매칭되는 섹션이 전혀 없으면 그냥 무시
          continue;
        }

        final bool isMultiSelect = section.isMultiSelect;
        // (혹시 SellWriteScreen에서 forceMultiSelect를 true로 넘기면,
        //  그걸 같이 고려하도록 수정할 수도 있음)

        if (isMultiSelect) {
          restoredMulti.putIfAbsent(section.id, () => <String>{}).add(tag);
        } else {
          // 단일 선택 섹션은 마지막 태그 기준으로 덮어씀
          restoredSingle[section.id] = tag;
        }
      }

      _selectedTagState = SelectedTagState(
        singleTags: restoredSingle,
        multiTags: restoredMulti,
      );
    }
  }

  // 유효성 검사 함수 (빈칸)
  String? _validateNotEmpty(String? value, String fieldName) {
    // String?은 null또는 String 가능이란 의미. 삼항연산자 내부에선 Dart가 반환타입을 명시하지 않아도 추론할 수 있음
    if (value == null || value.trim().isEmpty) {
      return '$fieldName을(를) 입력하세요'; // 빈칸이면 오류 메시지, 유효하면 null 반환
    }
    return null;
  }

  // 유효성 검사 함수 (숫자)
  String? _validateNumeric(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '숫자를 입력하세요'; // 빈칸이면 오류 메시지
    }
    final parsedValue = int.tryParse(
      value.replaceAll(',', '').trim(),
    ); // 콤마 제거 후 정수로 변환 시도
    if (parsedValue == null || parsedValue <= 0) {
      return '유효한 숫자를 입력하세요'; // 숫자가 아니거나 0 이하이면 오류 메시지
    }
    return null;
  }

  // 폼 제출 함수 (입력칸 검증 후 업로드 처리)
  Future<void> _submitForm() async {
    final bool isEditing = widget.isEditing;
    final initial = widget.initialPhoto;

    // 1) 사진이 선택되지 않았을 경우 (로컬 or 기존)
    //  - 새 글 작성: _selectedImage 가 있어야만 통과
    //  - 수정 모드: _selectedImage 가 없더라도 initial.imageUrl 이 있으면 통과
    final bool hasLocalImage = _selectedImage != null;
    final bool hasExistingImage =
        isEditing && (initial?.imageUrl.isNotEmpty ?? false);
    final bool hasImage = hasLocalImage || hasExistingImage;

    if (!hasImage) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('사진을 업로드하세요.')));
      return;
    }

    // 2) FormState 접근 가능 여부 확인
    if (_formKey.currentState == null)
      return; // Form 위젯을 연결해야 FormState에 접근 가능. null이면 함수 종료

    // 현재 로그인된 유저 정보 가져오기
    final user = FirebaseAuth.instance.currentUser;

    // Firestore users 컬렉션에서 현재 로그인된 유저 닉네임 가져오기
    final uid = user!.uid;
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final nickname =
        userDoc.data()?['nickname'] ?? '사용자'; // 닉네임이 없으면 '사용자'로 기본값 설정

    // 3) 폼 유효성 검증 (모든 TextFormField의 validator가 통과해야 true)
    if (_formKey.currentState!.validate()) {
      // 로그인 사용자 정보 가져오기 (Firebase Auth)
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('로그인 후 이용해주세요.')));
        return; // 로그인 안 되어 있으면 종료
      }

      // 4) 입력 데이터 가져오기
      final photoName = photoNameController.text.trim(); // 사진명
      final price = int.parse(
        priceController.text.replaceAll(',', '').trim(),
      ); // 가격 (콤마 제거 후 정수 변환)
      final description = descriptionController.text.trim(); // 추가 설명
      final location = locationController.text.trim(); // 위치

      // 태그: 새로 선택한 게 있으면 그걸, 아니면 기존 글의 태그 유지
      final List<String> tags =
          tagList.isNotEmpty
              ? tagList
              : (widget.initialPhoto?.tags ?? <String>[]);

      try {
        if (isEditing) {
          // ─────────────────────────────
          // 수정 모드: updateTrade 호출
          // ─────────────────────────────
          final original = widget.initialPhoto!;
          final tradeId = original.id;
          if (tradeId == null) {
            throw Exception('tradeId가 없습니다. (수정 불가)');
          }

          await PhotoTradeService().updateTrade(
            tradeId: tradeId,
            title: photoName,
            description: description,
            price: price,
            tags: tags,
            newImageFile:
                _selectedImage != null
                    ? File(_selectedImage!.path)
                    : null, // 새 이미지 있으면 전달, 없으면 null
            uid: original.uid, // 스토리지 경로는 원래 작성자의 uid 사용
          );

          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('판매글이 수정되었습니다.')));
          if (mounted) {
            Navigator.pop(context);
          }
        } else {
          // ─────────────────────────────
          // 새 글 작성 모드: addTrade 호출
          // ─────────────────────────────
          print("🔥 위치 값: $_selectedLocation");
          print("🔥 userDoc exists: ${userDoc.exists}");
          print("🔥 userDoc keys = ${userDoc.data()?.keys}");
          print("🔥 nickname raw = ${userDoc.data()?['nickname']}");

          // 5) Firestore + Storage 업로드 (사진 업로드 후 문서 생성)
          await PhotoTradeService().addTrade(
            imageFile: File(_selectedImage!.path), // 선택된 이미지 파일
            title: photoName, // 사진명
            description: description, // 추가 설명
            price: price, // 가격
            uid: user.uid, // 작성자 UID
            nickname: nickname, // 닉네임
            profileImageUrl: user.photoURL ?? '', // 프로필 이미지
            tags: tags, // 선택된 태그들
            position: pos,
            location: location,
          );

          // 6) 성공 메시지 출력
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('판매글이 등록되었습니다.')));

          // 7) 작성 완료 후 이전 화면으로 돌아가기
          // Navigator.pop(context);
          // 성공 시 이전 화면으로 돌아가기
          if (mounted) {
            Navigator.pop(context);
          }
        }
      } catch (e, st) {
        // 8) 오류 발생 시 콘솔 및 사용자 알림
        debugPrint('업로드/수정 실패: $e\n$st');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('업로드 중 오류가 발생했습니다.')));
      }
    } else {
      // 9) 폼 검증 실패 시 처리
      debugPrint("폼 검증 실패");
    }
  }

  // image_service에서 pickImageFromGallery와 pickImageFromCamera로
  // 이미지를 가져오면 null여부 확인 후 setState로 화면에 반영

  Future<void> _pickImageFromGallery(BuildContext context) async {
    _originalImage = await pickImageFromGallery(context);
    if (_originalImage != null) {
      await _openImageEditor(_originalImage!);  // 크롭 + 필터 + 낙서 등 가능
      //await _cropImage(_originalImage!.path);
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
        _selectedImage = _originalImage; // 크롭, 압축 없이 바로 사용
      });
      // 크롭 하고 싶으면 setState() 지우고 주석 처리된 내용으로 하기
      // await _cropImage(_originalImage!.path);
    } else {
      Fluttertoast.showToast(msg: '사진 촬영이 취소되었습니다.');
    }
  }

  Future<void> _pickImageFromFileSystem(BuildContext context) async {
    final file = await pickImageFromFileSystem(context);
    if (file != null) {
      setState(() {
        _selectedImage = file;
      });
      // 크롭 하고 싶으면 setState() 지우고 주석 처리된 내용으로 하기
      // await _cropImage(_originalImage!.path);
    } else {
      Fluttertoast.showToast(msg: '파일 선택이 취소되었습니다.');
    }
  }


  // 사진 편집기(image_editor_plus) 열어서 결과를 _selectedImage에 반영
  Future<void> _openImageEditor(XFile xfile) async {
    try {
      // 1) 원본 이미지 바이트 읽기
      final bytes = await xfile.readAsBytes();

      // 2) 에디터 화면 띄우기 (crop 옵션 포함)
      final Uint8List? editedBytes = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ImageEditor(
            image: bytes,
            // 필요하면 옵션 추가 (크롭 가능 등)
            cropOption: const CropOption(
              reversible: false, // 취소 시 옛날 상태로 되돌리기 여부
            ),
            // features: const ImageEditorFeatures(
            //   crop: true,
            //   rotate: true,
            //   flip: true,
            //   brush: true,
            //   text: true,
            //   filters: true,
            //   emoji: true,
            // ),
          ),
        ),
      );

      // 3) 사용자가 "완료" 안 누르고 나가면 null
      if (editedBytes == null) {
        // 편집 취소 시, 그냥 원본 그대로 쓸 거면 여기서 세팅 가능
        if (!mounted) return;
        setState(() {
          _selectedImage = xfile;
        });
        return;
      }

      // 4) 편집 결과를 임시 파일로 저장
      final dir = await getTemporaryDirectory();
      final ext = path.extension(xfile.path).isNotEmpty
          ? path.extension(xfile.path)
          : '.jpg';
      final filePath =
          '${dir.path}/edited_${DateTime.now().millisecondsSinceEpoch}$ext';
      final file = File(filePath);
      await file.writeAsBytes(editedBytes, flush: true);

      // 5) 상태 반영
      if (!mounted) return;
      setState(() {
        _selectedImage = XFile(file.path);
      });
    } catch (e, st) {
      debugPrint('image_editor_plus error: $e\n$st');
      Fluttertoast.showToast(msg: '사진 편집 중 오류가 발생했습니다.');
    }
  }

  // 찍거나 가져온 사진 편집(크롭,회전)하는 함수
  Future<void> _cropImage(String imagePath) async {
    if (_cropping) return; // 크롭 동작을 동시에 여러개 하지 못하도록 막음
    _cropping = true;
    try {
      // 경로 복사
      final normalizedPath = await _toTempFilePath(
        imagePath,
      ); // 앱의 임시 디렉토리로 경로 복사 -> 좀 더 안전한 접근
      final croppedFile = await _imageService.cropImage(
        normalizedPath,
      ); // 크롭 결과

      if (croppedFile != null) {
        if (!mounted) return; // 크롭 처리하는 동안 화면이 없어지지 않았는지 확인
        setState(() {
          _selectedImage = XFile(croppedFile.path);
        });
      }
    } catch (e, st) {
      debugPrint('crop error : $e\n$st');
      Fluttertoast.showToast(msg: '편집 중 오류 발생');
    } finally {
      _cropping = false;
    }
  }

  // 사진 경로를 받아서 어플의 임시 디렉토리 경로를 반환하는 함수
  Future<String> _toTempFilePath(String pickedPath) async {
    // 갤러리나 카메라에서 가져온 사진 경로를 받음
    final bytes =
        await XFile(pickedPath).readAsBytes(); // 원본을 XFile로 감싸서 전체 바이트를 읽어옴
    final ext =
        path.extension(pickedPath).isNotEmpty
            ? path.extension(pickedPath)
            : '.jpg';
    final dir = await getTemporaryDirectory(); // 앱 전용 임시 디렉토리
    final f = File(
      '${dir.path}/${DateTime.now().millisecondsSinceEpoch}$ext',
    ); // 임시 디렉토리에 새로운 파일 만듦
    await f.writeAsBytes(
      bytes,
      flush: true,
    ); // 읽어온 바이트를 만든 파일에 기록. flush는 버퍼링된 내용을 바로 사용할 수 있도록 보장
    return f.path;
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditing = widget.isEditing; // [11/18 추가]
    final initial =
        widget.initialPhoto; // 수정해야 할 정보를 sell_detail에서 받아와서 사진이 존재하는지 검사
    final bool hasAnyImage =
        _selectedImage != null ||
        (isEditing && initial?.imageUrl.isNotEmpty == true);

    return Scaffold(
      backgroundColor: Colors.white, // 전체 배경색
      // AppBar: 뒤로가기 버튼, 제목
      appBar: AppBar(
        title: Text(
          isEditing ? '사진 판매글 수정' : '사진 판매글 작성', // [11/18 수정]
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        centerTitle: true, // 제목 가운데 정렬
        backgroundColor: Colors.white, // AppBar 배경색
        foregroundColor: Colors.black, // AppBar 글자색
        elevation: 0.5, // AppBar 그림자
        scrolledUnderElevation:
            0, // 스크롤 시 그림자 제거 (앱바가 스크롤에 가려질 때 그림자 제거) -> surfaceTintColor: Colors.transparent 도 동일한 효과
      ),

      // 본문: 사진 업로드 버튼(창), 사진 정보 입력칸, 위치 입력칸, 카테고리 선택란, 등록 버튼
      body: SingleChildScrollView(
        keyboardDismissBehavior:
            ScrollViewKeyboardDismissBehavior
                .onDrag, // 스크롤 시 키보드 숨기기 (입력칸 벗어나면 키보드 숨김)
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            // Form 위젯으로 감싸기 (입력칸 검증용) ->Form위젯에 child로 유효성 검사가 필요한 위젯 넣기
            key:
                _formKey, // 폼 키 설정 (입력칸 검증용) -> 위에서 선언. 이 줄이 있어야 _formKey.currentState가 null이 아님
            autovalidateMode:
                AutovalidateMode.disabled, // 자동 검증 모드 (disabled: 수동 검증)
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, // 왼쪽 정렬
              children: [
                // [11/18 수정] 선택된 사진 혹은 기존 사진(수정 모드) 표시
                Builder(
                  builder: (context) {
                    final initial = widget.initialPhoto;
                    final hasLocalImage = _selectedImage != null;
                    final hasRemoteImage =
                        !hasLocalImage &&
                        initial != null &&
                        initial.imageUrl.isNotEmpty;

                    if (!hasLocalImage && !hasRemoteImage) {
                      return const SizedBox.shrink();
                    }

                    Widget imageWidget;

                    if (hasLocalImage) {
                      imageWidget = Image.file(
                        File(_selectedImage!.path),
                        width: double.infinity,
                        fit: BoxFit.fitWidth,
                      );
                    } else {
                      imageWidget = Image.network(
                        initial!.imageUrl,
                        width: double.infinity,
                        fit: BoxFit.fitWidth,
                      );
                    }

                    return Column(
                      children: [
                        ClipRRect(child: imageWidget),
                        const SizedBox(height: 10),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 10), // 사진과 버튼 사이 간격

                if (_selectedImage != null) // 사진 삭제 버튼
                  TextButton(
                    onPressed: () async {
                      final file = File(_selectedImage!.path);
                      if (file.existsSync()) {
                        // 파일이 존재하는지 확인 (선택된 이미지가 있는지 확인)
                        file.deleteSync(); // 파일 삭제
                      }
                      setState(() {
                        _selectedImage = null; // 선택된 이미지 상태 초기화
                      });
                    },
                    style: ButtonStyle(
                      minimumSize: WidgetStateProperty.all<Size>(
                        const Size(double.infinity, 30),
                      ), // 버튼 크기
                      shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0), // 모서리 둥글게
                          side: const BorderSide(
                            color: Color.fromARGB(255, 255, 230, 230),
                          ), // 테두리 색상
                        ),
                      ),
                      backgroundColor: WidgetStateProperty.resolveWith<Color>((
                        Set<WidgetState> states,
                      ) {
                        if (states.contains(WidgetState.pressed)) {
                          return const Color.fromARGB(
                            255,
                            255,
                            230,
                            230,
                          ); // 눌렀을 때 연한 빨간색
                        }
                        return const Color.fromARGB(255, 255, 245, 245); // 기본색
                      }),
                    ),
                    child: const Text(
                      '사진 삭제',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color.fromARGB(255, 213, 81, 81),
                      ),
                    ),
                  ),

                // 사진 업로드 버튼 (다시 선택 버튼)
                ElevatedButton(
                  onPressed: () async {
                    _pickImageFromGallery(context);
                  },
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith<Color>((
                      Set<WidgetState> states,
                    ) {
                      if (states.contains(WidgetState.pressed)) {
                        return const Color(0xFFDDECC7); // 눌렀을 때 연두색
                      }
                      return const Color.fromARGB(255, 238, 238, 238); // 기본색
                    }),
                    minimumSize:
                        hasAnyImage
                            ? WidgetStateProperty.all<Size>(
                              const Size(double.infinity, 30),
                            ) // '사진 업로드' 버튼 크기 (가로 꽉 채우기, 세로 150)
                            : WidgetStateProperty.all<Size>(
                              const Size(double.infinity, 150),
                            ), // '다시 선택' 버튼 크기 (가로 꽉 채우기, 세로 30)

                    shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0), // 모서리 둥글게
                        side: const BorderSide(
                          color: Color.fromARGB(255, 221, 221, 221),
                        ), // 테두리 색상
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      if (!hasAnyImage) ...[
                        const Icon(
                          Icons.upload_rounded,
                          size: 50,
                          color: Color.fromARGB(255, 136, 136, 136),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "사진 업로드",
                          style: TextStyle(
                            fontSize: 15,
                            color: Color.fromARGB(255, 136, 136, 136),
                          ),
                        ),
                      ] else ...[
                        Text(
                          "다시 선택하기",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color.fromARGB(255, 136, 136, 136),
                          ),
                        ),
                      ],
                    ],
                    /*children: [
                      hasAnyImage ? Icon( Icons.upload_rounded, size: 50, color: Color.fromARGB(255, 136, 136, 136)): const SizedBox.shrink(), // 이미지 선택 전 아이콘, 후 빈칸
                      hasAnyImage ? const SizedBox(height: 10): const SizedBox.shrink(),                                                         // 아이콘과 텍스트 사이 간격
                      hasAnyImage ? const Text("사진 업로드", style: TextStyle(fontSize: 15, color: Color.fromARGB(255, 136, 136, 136)))        // 선택된 이미지가 없을 땐 '사진 업로드' 텍스트
                                             : Text("다시 선택하기", style: TextStyle(fontSize: 12, color: Color.fromARGB(255, 136, 136, 136))),           // 선택된 이미지가 있으면 '다시 선택하기' 텍스트
                    ],*/
                  ),
                ),
                SizedBox(height: 20), // 사진 업로드 버튼과 입력칸 사이 간격
                // 사진 정보 입력칸(사진명, 가격, 추가 설명)
                Container(
                  padding: const EdgeInsets.all(8.0), // 안쪽 여백
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Color.fromARGB(255, 221, 221, 221), // 테두리 색상
                      width: 1.5, // 테두리 두께
                    ),
                    borderRadius: BorderRadius.circular(10), // 모서리 둥글게
                  ),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 사진명 입력란
                      TextFormField(
                        controller: photoNameController, // 컨트롤러 연결
                        decoration: baseDecoration.copyWith(
                          labelText: '사진명*',
                          hintText: '사진명을 입력하세요',
                        ),
                        // 유효성 검사 -> 위에서 선언한 함수 사용
                        validator: (value) => _validateNotEmpty(value, '사진명'),
                      ),
                      const SizedBox(height: 5), // 간격
                      // 가격 입력란
                      TextFormField(
                        controller: priceController,
                        decoration: baseDecoration.copyWith(
                          labelText: '가격*',
                          hintText: '가격을 입력하세요',
                        ),
                        // 유효성 검사 -> 빈칸 or 숫자가 아니면 오류 메시지, 유효하면 null 반환
                        validator: (value) => _validateNumeric(value),
                        keyboardType: TextInputType.number, // 숫자 키패드
                      ),
                      const SizedBox(height: 5), // 간격
                      // 추가 설명 입력란
                      TextField(
                        controller: descriptionController,
                        decoration: baseDecoration.copyWith(
                          labelText: '추가 설명',
                          hintText: '추가 설명을 입력하세요',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                        maxLines: 5, // 여러 줄 입력 가능
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20), // 입력칸과 위치 입력칸 사이 간격
                // 위치 입력칸
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 0.0,
                    horizontal: 8.0,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Color.fromARGB(255, 221, 221, 221),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),

                  child: InkWell(
                    onTap: () async {
                      final permissionLocation = await ensureLocationPermission(
                        context,
                        needAlways: false,
                      );
                      if (!permissionLocation) return; // 권한 없으면 중단

                      _openLocationSelector(context);
                    },
                    borderRadius: BorderRadius.circular(10), // 클릭 영역 모서리 둥글게
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12.0,
                      ), // 위아래 여백
                      child: Text(
                        locationController.text.isEmpty
                            ? '위치를 입력하세요'
                            : locationController.text,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color.fromARGB(255, 136, 136, 136),
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 20), // 위치 입력칸과 등록 버튼 사이 간격
                // 태그 입력란
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 0.0,
                    horizontal: 8.0,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Color.fromARGB(255, 221, 221, 221),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),

                  child: InkWell(
                    onTap: () {
                      _openTagSelector(context); // 태그 선택 화면으로 이동
                    },
                    borderRadius: BorderRadius.circular(10), // 클릭 영역 모서리 둥글게
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12.0,
                      ), // 위아래 여백
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween, // 좌우 끝 정렬
                        children: [
                          Text(
                            '태그를 선택하세요',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color.fromARGB(255, 136, 136, 136),
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16,
                            color: Color.fromARGB(255, 136, 136, 136),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 10), // 태그 입력란과 태그 리스트 사이 간격
                // 태그 리스트
                if (tagList.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children:
                        tagList.map((tag) {
                          return Chip(
                            label: Text(
                              tag,
                              style: TextStyle(
                                color: Colors.white, // 글자색
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            backgroundColor: Color(0xFFBBD18B), // 배경색
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side:BorderSide(
                                color:Color(0xFFBBD18B)
                              )
                            ),
                            onDeleted: () {
                              setState(() {
                                _removeTag(tag);
                              });
                            },
                            deleteIcon: Icon(
                              Icons.close,
                              color: Colors.white, // 삭제 아이콘 색상
                            ),
                          );
                        }).toList(),
                  ),

                SizedBox(height: 20), // 태그 리스트와 등록 버튼 사이 간격
                // 등록 버튼
                ElevatedButton(
                  onPressed: () {
                    _submitForm(); // 클릭시 폼 제출 함수 호출 (입력칸 검증 후 업로드) -> 위에서 선언
                  },
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith<Color>((
                      Set<WidgetState> states,
                    ) {
                      if (states.contains(WidgetState.pressed)) {
                        return const Color(0xFFDDECC7); // 눌렀을 때 연두색
                      }
                      return const Color(0xFF8BC34A); // 기본색
                    }),
                    minimumSize: WidgetStateProperty.all<Size>(
                      const Size(double.infinity, 50),
                    ), // 버튼 크기 (가로 꽉 채우기, 세로 50)
                    shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0), // 모서리 둥글게
                        side: const BorderSide(
                          color: Color(0xFF8BC34A),
                        ), // 테두리 색상
                      ),
                    ),
                  ),
                  child: const Text(
                    "등록",
                    style: TextStyle(fontSize: 15, color: Colors.white),
                  ),
                ),
              ], // body children
            ),
          ),
        ),
      ),
    );
  }
}
