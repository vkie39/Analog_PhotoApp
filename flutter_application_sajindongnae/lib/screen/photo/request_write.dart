import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as dev;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/request_service.dart';
import '../../models/request_model.dart';
import 'package:flutter_application_sajindongnae/screen/photo/location_select.dart';
import 'package:flutter_application_sajindongnae/component/search.dart';
import 'package:flutter_application_sajindongnae/services/permission_service.dart';
import 'package:flutter_application_sajindongnae/models/location_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';   // [수정] Firestore import 추가



// 가격(유료,무료) 선택용
enum RequestFeeType {free, paid}

class RequestWriteScreen extends StatefulWidget {
  const RequestWriteScreen({super.key});

  @override
  State<RequestWriteScreen> createState() => RequestWriteScreenScreenState();
}

class RequestWriteScreenScreenState extends State<RequestWriteScreen> with SingleTickerProviderStateMixin {

  // 입력칸 컨트롤러
  final TextEditingController requestTitleController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController locationController = TextEditingController();

  // 지도 컨트롤러와 주소 저장 변수, 반경 표시용 서클 보관
  GoogleMapController? _miniMapController;
  LatLng? pickedPos;
  Set<Circle> circles = {};

  // 입력칸 검증용 폼키
  final _formKey = GlobalKey<FormState>();

  // RequestFeeType으로 기본값을 paid인 feeType 만듦
  List<bool> _feeTypeIsSelected = [true, false];

  // 설명문 상태 관리용
  bool _showExplanation = false;

  @override
  void initState() {
    super.initState();
    priceController.value = const TextEditingValue(text: '0');
  }

  @override
  void dispose() {
    _miniMapController?.dispose();
    requestTitleController.dispose();
    priceController.dispose();
    descriptionController.dispose();
    locationController.dispose();
    super.dispose();
  }


  // 위치 선택 화면으로 이동하고 선택된 위치를 받아오는 함수
  Future<void> _openLocationSelector(BuildContext context) async {
    final result = await Navigator.push<LocationPickResult>(
      context,
      MaterialPageRoute(
          builder: (context) => LocationSelectScreen(
            initialPosition: pickedPos,
            initialAddress: locationController.text.isEmpty
                ? locationController.text : null,
          )
      ),
    );

    // LocationSelectScreen 선택된 위치를 받아와서 상태 업데이트
    if (result != null) {
      setState(() {
        locationController.text = result.address;        // 선택된 상태 업데이트
        pickedPos = result.position;

        circles = {
          Circle(
            circleId: CircleId('miniCircle'),
            fillColor : const Color.fromARGB(54, 116, 235, 106),
            center : pickedPos!,
            radius : 2500,
            strokeColor : const Color.fromARGB(54, 116, 235, 106),
            strokeWidth : 1,
            visible : true,
          ),
        };
      });
      await _miniMapController?.animateCamera(
        CameraUpdate.newLatLngZoom(pickedPos!, 12),
      );
    }
  }


  // 유효성 검사 함수 (빈칸)
  String? _validateNotEmpty(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName을(를) 입력하세요';
    }
    return null;
  }

  // 유효성 검사 함수 (숫자)
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



  // 폼 제출 함수 수정
  Future<void> _submitForm() async {
    if (_formKey.currentState == null) return;

    if (_formKey.currentState!.validate()) {
      if (pickedPos == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("위치를 선택해주세요.")),
        );
        return;
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("로그인 후 이용해주세요.")),
        );
        return;
      }

      // [수정] Firestore users 컬렉션에서 닉네임과 프로필 이미지 가져오기
      final userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();

      final nickname = userDoc.data()?["nickname"] ?? "사용자";                 // [수정]
      final profileImageUrl = userDoc.data()?["profileImageUrl"]
          ?? user.photoURL
          ?? "";                                         // [수정]

      final photoName = requestTitleController.text.trim();
      final price =
      int.parse(priceController.text.replaceAll(',', '').trim());
      final description = descriptionController.text.trim();
      final location = locationController.text.trim();

      // RequestModel 생성
      final request = RequestModel(
        requestId: const Uuid().v4(),
        uid: user.uid,
        nickname: nickname,                // [수정]
        profileImageUrl: profileImageUrl,  // [수정]
        category: null,
        dateTime: DateTime.now(),
        title: photoName,
        description: description,
        price: price,
        location: location,
        position: pickedPos!,
        bookmarkedBy: [],
        status: '의뢰중',
        isFree: _feeTypeIsSelected[0],
        isPaied: false,
        reportCount: 0,
      );
    
      dev.log('request 모델 생성 완료 *********************');
    

      dev.log('request 모델 생성 완료 *********************');


      // 등록
      await RequestService().addRequest(request);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("의뢰글이 등록되었습니다.")),
      );

    dev.log('request 업로드 완료 *********************');
    }
  }


  // 유료-무료 선택했을 때 호출
  void onPressedPrice(int index){
    setState(() {
      for(int i = 0; i<_feeTypeIsSelected.length; i++){
        _feeTypeIsSelected[i] = i == index;
      }
      final isFree = _feeTypeIsSelected[0];
      if (isFree){
        priceController.value = const TextEditingValue(
          text: '0',
        );
      } else {
        if (_feeTypeIsSelected[1]) priceController.clear();
      }
    });
  }

  // 유료-무료 버튼 디자인
  Widget _feeChip(String label, bool selected){
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFE0E0E0) : Colors.transparent,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.black87),
      ),
    );
  }

  // 설명문 토글 함수
  void _onTextPressed(){
    setState(() {
      _showExplanation = !_showExplanation;
    });
  }

  // 공통 InputDecoration 스타일 정의 (입력칸 스타일)
  final baseDecoration = InputDecoration(
    labelStyle: TextStyle(fontSize: 14, color: Color.fromARGB(255, 136, 136, 136)),
    hintStyle: TextStyle(fontSize: 10, color: Color.fromARGB(255, 136, 136, 136)),
    enabledBorder: UnderlineInputBorder( borderSide: BorderSide(color: Color.fromARGB(255, 221, 221, 221), width: 1.5)),
    focusedBorder: UnderlineInputBorder( borderSide: BorderSide(color: Color.fromARGB(255, 136, 136, 136), width: 1.5)),
  );



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        title: const Text('사진 의뢰글 작성', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
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

                // 사진 정보 입력칸(의뢰명, 추가 설명)
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Color.fromARGB(255, 221, 221, 221),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),

                  child : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: requestTitleController,
                        decoration: baseDecoration.copyWith(
                          labelText: '의뢰 제목*',
                          hintText: '제목을 입력하세요',
                        ),
                        validator: (value) => _validateNotEmpty(value, '의뢰 제목'),
                      ),
                      const SizedBox(height: 5),

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

                SizedBox(height: 20),

                // 가격 입력란
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Color.fromARGB(255, 221, 221, 221),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),

                  child : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ToggleButtons(
                        onPressed: (index)=> onPressedPrice(index),
                        isSelected: _feeTypeIsSelected,
                        renderBorder: false,
                        fillColor: Colors.transparent,
                        color: Colors.black87,
                        selectedColor: Colors.black87,
                        highlightColor: Colors.transparent,
                        children: [
                          _feeChip('무료 의뢰', _feeTypeIsSelected[0]),
                          _feeChip('유료 의뢰', _feeTypeIsSelected[1]),
                        ],
                      ),
                      const SizedBox(height: 5),

                      TextFormField(
                        controller: priceController,
                        enabled: _feeTypeIsSelected[1],
                        decoration: baseDecoration.copyWith(
                          labelText: '가격*',
                          hintText: '가격을 입력하세요',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                        validator: _feeTypeIsSelected[1]? (value) => _validateNumeric(value): null,
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20),

                // 위치 입력칸
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 8.0),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Color.fromARGB(255, 221, 221, 221),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),

                  child: InkWell(
                    onTap: () async {
                      final permissionLocation = await ensureLocationPermission(context, needAlways: false);
                      if (!permissionLocation) return;

                      _openLocationSelector(context);
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Text(
                        locationController.text.isEmpty
                            ? '의뢰자가 사진을 찍을 위치를 선택하세요'
                            : locationController.text,
                        style: const TextStyle(fontSize: 14, color: Color.fromARGB(255, 136, 136, 136)),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 20),

                if (pickedPos != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadiusGeometry.circular(10),
                    child: SizedBox(
                      height: 180,
                      width: double.infinity,
                      child: IgnorePointer(
                        child: GoogleMap(
                          liteModeEnabled: true,
                          initialCameraPosition: CameraPosition(target: pickedPos!, zoom: 12),
                          onMapCreated: (c) => _miniMapController = c,
                          markers:{
                            Marker(
                                markerId: const MarkerId('mini'),
                                position: pickedPos!,
                                infoWindow: const InfoWindow(title: '선택 위치'),
                                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)
                            ),
                          },
                          myLocationEnabled: false,
                          myLocationButtonEnabled: false,
                          circles: circles,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                ],

                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black54,
                    padding: const EdgeInsets.symmetric(horizontal: 5.5, vertical: 3),
                  ),
                  onPressed: _onTextPressed,
                  child: Container(
                    decoration: const BoxDecoration(
                      border: Border(
                          bottom: BorderSide(color: Colors.black54, width: 1)
                      ),
                    ),
                    child: const Text('위치 지정은 왜 필요한 건가요?'),
                  ),
                ),

                if (_showExplanation) ...[
                  SizedBox(height: 10),
                  Column(
                    children: [
                      Image.asset(
                        'assets/icons/parrot.png',
                        width: 80, height: 80,
                      ),
                      const SizedBox(height: 15),
                      const Text(
                        '지정한 위치를 기준으로 반경 2.5km 이내의 이웃들에게 알림이 전달돼요.\n'
                            '알림을 통해 의뢰한 사진을 더 빠르게 받아보실 수 있습니다.\n'
                            '위치 정보는 알림 서비스 제공에만 사용되며, 다른 용도로 저장되거나 공유되지 않으니 안심하세요',
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                        textAlign: TextAlign.left,
                      )
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),

      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 18),
        child: ElevatedButton(
          onPressed: (){
            _submitForm();
          },
          style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
                if (states.contains(WidgetState.pressed)) {
                  return const Color(0xFFDDECC7);
                }
                return const Color(0xFF8BC34A);
              }),
              minimumSize: WidgetStateProperty.all<Size>(const Size(double.infinity, 50)),
              shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      side: const BorderSide(color: Color(0xFF8BC34A))
                  )
              )
          ),
          child: const Text("등록", style: TextStyle(fontSize: 15, color: Colors.white)),
        ),
      ),
    );
  }
}
  
