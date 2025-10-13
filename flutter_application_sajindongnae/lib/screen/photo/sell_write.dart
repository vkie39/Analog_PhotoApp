// sell_write.dart
// 각주: 판매 글 작성 화면. 이미지 선택→크롭→워터마크→미리보기→업로드 전 폼 검증까지.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_application_sajindongnae/screen/photo/location_select.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import 'package:flutter_application_sajindongnae/screen/photo/tag_select.dart';
import 'package:flutter_application_sajindongnae/services/image_service.dart';
import 'package:flutter_application_sajindongnae/services/permission_service.dart';
import 'package:flutter_application_sajindongnae/models/tag_model.dart';
import 'package:flutter_application_sajindongnae/models/location_model.dart';

// 외부 util: image_service.dart 상단의 top-level 함수들을 사용
// pickImageFromGallery(context), pickImageFromCamera(context), pickImageFromFileSystem(context)

// Form을 관리하기 위한 키
final _formKey = GlobalKey<FormState>();

class SellWriteScreen extends StatefulWidget {
  const SellWriteScreen({super.key});

  @override
  State<SellWriteScreen> createState() => _SellWriteScreenState();
}

class _SellWriteScreenState extends State<SellWriteScreen> {
  // 원본 / 워터마크 이미지
  XFile? _originalImage;
  XFile? _watermarkedImage; // 각주: 최종 미리보기/업로드용
  bool _cropping = false;
  late ImageService _imageService;

  // 태그 상태
  SelectedTagState _selectedTagState = SelectedTagState();
  List<String> get tagList => [
    ..._selectedTagState.singleTags.values,
    ..._selectedTagState.multiTags.values.expand((set) => set),
  ];

  void _removeTag(String tag) {
    final newSingleTags =
    Map<String, String>.from(_selectedTagState.singleTags);
    final newMultiTags = _selectedTagState.multiTags
        .map((key, value) => MapEntry(key, Set<String>.from(value)));

    String? singleKeyToRemove;
    newSingleTags.forEach((sectionId, selectedTag) {
      if (selectedTag == tag) singleKeyToRemove = sectionId;
    });
    if (singleKeyToRemove != null) {
      newSingleTags.remove(singleKeyToRemove);
    }

    newMultiTags.removeWhere((key, set) {
      set.remove(tag);
      return set.isEmpty;
    });

    setState(() {
      _selectedTagState =
          SelectedTagState(singleTags: newSingleTags, multiTags: newMultiTags);
    });
  }

  Future<void> _openTagSelector(BuildContext context) async {
    final result = await Navigator.push<SelectedTagState>(
      context,
      MaterialPageRoute(
        builder: (context) => TagSelectionScreen(initialState: _selectedTagState),
      ),
    );
    if (result != null) {
      setState(() {
        _selectedTagState = result;
      });
    }
  }

  Future<void> _openLocationSelector(BuildContext context) async {
    final result = await Navigator.push<LocationPickResult>(
      context,
      MaterialPageRoute(builder: (context) => LocationSelectScreen()),
    );
    if (result != null) {
      setState(() {
        locationController.text = result.address;
      });
    }
  }

  // 컨트롤러
  final TextEditingController photoNameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController locationController = TextEditingController();

  static final baseDecoration = InputDecoration(
    labelStyle:
    TextStyle(fontSize: 14, color: Color.fromARGB(255, 136, 136, 136)),
    hintStyle:
    TextStyle(fontSize: 10, color: Color.fromARGB(255, 136, 136, 136)),
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
    photoNameController.dispose();
    priceController.dispose();
    descriptionController.dispose();
    locationController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _imageService = ImageService(); // 각주: 서비스 인스턴스
  }

  String? _validateNotEmpty(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName을(를) 입력하세요';
    }
    return null;
  }

  String? _validateNumeric(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '숫자를 입력하세요';
    }
    final parsedValue = int.tryParse(value.replaceAll(',', '').trim());
    if (parsedValue == null || parsedValue <= 0) {
      return '유효한 숫자를 입력하세요';
    }
    return null;
  }

  void _submitForm() {
    if (_watermarkedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('사진을 업로드하세요.')),
      );
      return;
    }
    if (_formKey.currentState == null) return;

    if (_formKey.currentState!.validate()) {
      final photoName = photoNameController.text.trim();
      final price = int.parse(priceController.text.replaceAll(',', '').trim());
      final description = descriptionController.text.trim();
      final location = locationController.text.trim();
      final tags = tagList;

      // TODO: 여기서 _watermarkedImage를 업로드하고, 메타데이터와 함께 Firestore에 저장
      // 예) await ImageService.uploadPhotoTradeImage(File(_watermarkedImage!.path), userId);

      debugPrint(
        "폼 제출됨: $photoName / $price / $location / 태그:${tags.length} / file=${_watermarkedImage!.path}",
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('등록 처리되었습니다.')),
      );
    } else {
      debugPrint("폼 검증 실패");
    }
  }

  // ============= 이미지 선택/크롭/워터마크 파이프라인 =============
  Future<void> _pickImageFromGallery(BuildContext context) async {
    final picked = await pickImageFromGallery(context);
    if (picked == null) {
      Fluttertoast.showToast(msg: '사진 선택이 취소되었습니다.');
      return;
    }
    _originalImage = picked;
    await _processCropAndWatermark(_originalImage!.path);
  }

  Future<void> _pickImageFromCamera(BuildContext context) async {
    final picked = await pickImageFromCamera(context);
    if (picked == null) {
      Fluttertoast.showToast(msg: '사진 촬영이 취소되었습니다.');
      return;
    }
    _originalImage = picked;
    // 각주: 카메라 촬영 직후 크롭 없이 바로 워터마크를 원하면 _applyWatermark(_originalImage!) 호출
    await _processCropAndWatermark(_originalImage!.path);
  }

  Future<void> _pickImageFromFileSystem(BuildContext context) async {
    final picked = await pickImageFromFileSystem(context);
    if (picked == null) {
      Fluttertoast.showToast(msg: '파일 선택이 취소되었습니다.');
      return;
    }
    _originalImage = picked;
    await _processCropAndWatermark(_originalImage!.path);
  }

  Future<void> _processCropAndWatermark(String imagePath) async {
    if (_cropping) return; // 각주: 중복 호출 방지
    _cropping = true;
    try {
      // 임시 디렉토리로 복사(권장: 접근성/권한 이슈 완화)
      final normalizedPath = await _toTempFilePath(imagePath);
      final croppedFile = await _imageService.cropImage(normalizedPath);

      XFile baseFile;
      if (croppedFile != null) {
        baseFile = XFile(croppedFile.path);
      } else {
        // 크롭 취소 시 원본으로 진행
        baseFile = XFile(normalizedPath);
      }

      await _applyWatermark(baseFile);
    } catch (e, st) {
      debugPrint('crop/wm error : $e\n$st');
      Fluttertoast.showToast(msg: '편집 중 오류 발생');
    } finally {
      _cropping = false;
    }
  }

  Future<void> _applyWatermark(XFile baseFile) async {
    // TODO: 실제 서비스에서는 uid를 wmText에 포함 (유출 추적 강화)
    // final uid = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    final yyyyMmDd = DateTime.now().toIso8601String().substring(0, 10);
    final wmText = '사진동네 • $yyyyMmDd'; // 예: '사진동네 • uid • 2025-09-30'

    final wm = await _imageService.createFilledWatermark(
      baseFile,
      watermarkText: wmText,
      opacity: 0.18,
      paddingFactor: 2.5,
      angleDeg: -45.0,
      withStroke: true,
    );

    if (!mounted) return;
    if (wm == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('워터마크 생성에 실패했습니다.')),
      );
      return;
    }

    setState(() {
      _watermarkedImage = wm;
    });
  }

  // 원본 경로를 앱 임시 디렉토리로 복사
  Future<String> _toTempFilePath(String pickedPath) async {
    final bytes = await XFile(pickedPath).readAsBytes();
    final ext =
    path.extension(pickedPath).isNotEmpty ? path.extension(pickedPath) : '.jpg';
    final dir = await getTemporaryDirectory();
    final f = File('${dir.path}/${DateTime.now().millisecondsSinceEpoch}$ext');
    await f.writeAsBytes(bytes, flush: true);
    return f.path;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        title: const Text(
          '사진 판매글 작성',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        scrolledUnderElevation: 0,
      ),

      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.disabled,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 미리보기: 항상 워터마크 이미지 보여줌
                if (_watermarkedImage != null)
                  ClipRRect(
                    child: Image.file(
                      File(_watermarkedImage!.path),
                      width: double.infinity,
                      fit: BoxFit.fitWidth,
                    ),
                  ),
                const SizedBox(height: 10),

                // 사진 삭제 버튼
                if (_watermarkedImage != null)
                  TextButton(
                    onPressed: () async {
                      final file = File(_watermarkedImage!.path);
                      if (file.existsSync()) {
                        file.deleteSync();
                      }
                      setState(() {
                        _originalImage = null;
                        _watermarkedImage = null;
                      });
                    },
                    style: ButtonStyle(
                      // 각주: WidgetStateProperty → MaterialStateProperty 로 교체 (빌드 실패 원인 해결)
                      minimumSize: MaterialStateProperty.all<Size>(
                        const Size(double.infinity, 30),
                      ), // 각주: 고정 크기 상태값

                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          side: const BorderSide(
                            color: Color.fromARGB(255, 255, 230, 230),
                          ),
                        ),
                      ), // 각주: 버튼 모양/테두리

                      backgroundColor:
                      MaterialStateProperty.resolveWith<Color>((states) {
                        if (states.contains(MaterialState.pressed)) {
                          return const Color.fromARGB(255, 255, 230, 230);
                        }
                        return const Color.fromARGB(255, 255, 245, 245);
                      }), // 각주: 상태별 배경색
                    ),
                    child: const Text(
                      '사진 삭제',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color.fromARGB(255, 213, 81, 81),
                      ),
                    ),
                  ),

                // 사진 업로드 / 다시 선택
                ElevatedButton(
                  onPressed: () async {
                    await _pickImageFromGallery(context);
                  },
                  style: ButtonStyle(
                    backgroundColor:
                    MaterialStateProperty.resolveWith<Color>((states) {
                      if (states.contains(MaterialState.pressed)) {
                        return const Color(0xFFDDECC7);
                      }
                      return const Color.fromARGB(255, 238, 238, 238);
                    }), // 각주: 눌림/기본 배경색

                    minimumSize: (_watermarkedImage == null)
                        ? MaterialStateProperty.all<Size>(
                      const Size(double.infinity, 150),
                    )
                        : MaterialStateProperty.all<Size>(
                      const Size(double.infinity, 30),
                    ), // 각주: 선택 여부에 따라 높이 변경

                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        side: const BorderSide(
                          color: Color.fromARGB(255, 221, 221, 221),
                        ),
                      ),
                    ), // 각주: 라운드/테두리
                  ),
                  child: Column(
                    children: [
                      _watermarkedImage == null
                          ? const Icon(
                        Icons.upload_rounded,
                        size: 50,
                        color: Color.fromARGB(255, 136, 136, 136),
                      )
                          : const SizedBox.shrink(),
                      _watermarkedImage == null
                          ? const SizedBox(height: 10)
                          : const SizedBox.shrink(),
                      _watermarkedImage == null
                          ? const Text(
                        "사진 업로드",
                        style: TextStyle(
                          fontSize: 15,
                          color: Color.fromARGB(255, 136, 136, 136),
                        ),
                      )
                          : const Text(
                        "다시 선택하기",
                        style: TextStyle(
                          fontSize: 12,
                          color: Color.fromARGB(255, 136, 136, 136),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 사진 정보 입력칸(사진명, 가격, 추가 설명)
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color.fromARGB(255, 221, 221, 221),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 사진명
                      TextFormField(
                        controller: photoNameController,
                        decoration: baseDecoration.copyWith(
                          labelText: '사진명*',
                          hintText: '사진명을 입력하세요',
                        ),
                        validator: (v) => _validateNotEmpty(v, '사진명'),
                      ),
                      const SizedBox(height: 5),

                      // 가격
                      TextFormField(
                        controller: priceController,
                        decoration: baseDecoration.copyWith(
                          labelText: '가격*',
                          hintText: '가격을 입력하세요',
                        ),
                        validator: (v) => _validateNumeric(v),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 5),

                      // 추가 설명
                      TextField(
                        controller: descriptionController,
                        decoration: baseDecoration.copyWith(
                          labelText: '추가 설명',
                          hintText: '추가 설명을 입력하세요',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                        maxLines: 5,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 위치 입력칸
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 0.0,
                    horizontal: 8.0,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color.fromARGB(255, 221, 221, 221),
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
                      if (!permissionLocation) return;
                      _openLocationSelector(context);
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Text(
                        locationController.text.isEmpty
                            ? '위치를 입력하세요' // 각주: 오타 수정 ("위를" → "위치를")
                            : locationController.text,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color.fromARGB(255, 136, 136, 136),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 태그 선택
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 0.0,
                    horizontal: 8.0,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color.fromARGB(255, 221, 221, 221),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: InkWell(
                    onTap: () => _openTagSelector(context),
                    borderRadius: BorderRadius.circular(10),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                const SizedBox(height: 10),

                // 태그 리스트
                if (tagList.isNotEmpty)
                  Padding(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                    child: Wrap(
                      children: tagList.map((tag) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Chip(
                            label: Text(tag),
                            backgroundColor: Colors.white,
                            labelStyle:
                            const TextStyle(color: Colors.black87),
                            side: const BorderSide(
                              color: Color(0xFFE0E0E0),
                              width: 1,
                            ),
                            deleteIcon: const Icon(
                              Icons.close,
                              size: 18,
                              color: Colors.black54,
                            ),
                            onDeleted: () {
                              setState(() {
                                _removeTag(tag);
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                const SizedBox(height: 20),

                // 등록 버튼
                ElevatedButton(
                  onPressed: _submitForm,
                  style: ButtonStyle(
                    backgroundColor:
                    MaterialStateProperty.resolveWith<Color>((states) {
                      if (states.contains(MaterialState.pressed)) {
                        return const Color(0xFFDDECC7);
                      }
                      return const Color(0xFF8BC34A);
                    }), // 각주: 눌림/기본 배경

                    minimumSize: MaterialStateProperty.all<Size>(
                      const Size(double.infinity, 50),
                    ), // 각주: 가로 꽉/세로 50

                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        side: const BorderSide(color: Color(0xFF8BC34A)),
                      ),
                    ), // 각주: 라운드/테두리
                  ),
                  child: const Text(
                    "등록",
                    style: TextStyle(fontSize: 15, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
