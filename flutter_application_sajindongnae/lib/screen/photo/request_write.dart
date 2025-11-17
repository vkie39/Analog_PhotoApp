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
      await _miniMapController?.animateCamera(CameraUpdate.newLatLngZoom(pickedPos!, 12),);
    }
  }


  // 유효성 검사 함수 (빈칸)
  String? _validateNotEmpty(String? value, String fieldName) { // String?은 null또는 String 가능이란 의미. 삼항연산자 내부에선 Dart가 반환타입을 명시하지 않아도 추론할 수 있음
    if (value == null || value.trim().isEmpty) {
      return '$fieldName을(를) 입력하세요';                      // 빈칸이면 오류 메시지, 유효하면 null 반환
    }
    return null; 
  }

  // 유효성 검사 함수 (숫자)
  String? _validateNumeric(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '숫자를 입력하세요';                                          // 빈칸이면 오류 메시지
    }
    final parsedValue = int.tryParse(value.replaceAll(',', '').trim()); // 콤마 제거 후 정수로 변환 시도
    if (parsedValue == null || parsedValue <= 0) {
      return '유효한 숫자를 입력하세요';                                    // 숫자가 아니거나 0 이하이면 오류 메시지
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

    dev.log('유효성 검사 완료 *********************');

    final photoName = requestTitleController.text.trim();
    final price =
        int.parse(priceController.text.replaceAll(',', '').trim());
    final description = descriptionController.text.trim();
    final location = locationController.text.trim();
    dev.log('데이터 공백 처리 완료 *********************');


    final request = RequestModel(
      requestId: const Uuid().v4(),
      uid: user.uid,
      nickname: user.displayName ?? '사용자',
      profileImageUrl: user.photoURL ?? '',
      category: null,
      dateTime: DateTime.now(),
      title: photoName,
      description: description,
      price: price,
      location: location,
      position: pickedPos!,
      bookmarkedBy: [],
      isFree: _feeTypeIsSelected[0],
      isPaied: false,
    );

    dev.log('request 모델 생성 완료 *********************');
    
    try{
      await RequestService().addRequest(request);
    } catch (e){
      dev.log('request_upload_error: ${e}');
    }
    
    dev.log('request 업로드 완료 *********************');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("의뢰글이 등록되었습니다.")),
    );

    Navigator.pop(context);
  } else {
    print("폼 검증 실패");
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
        // 무료 일때 가격은 0으로 
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
        style: TextStyle(color: Colors.black87),
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
  static final baseDecoration = InputDecoration(
    labelStyle: TextStyle(fontSize: 14, color: Color.fromARGB(255, 136, 136, 136)),
    hintStyle: TextStyle(fontSize: 10, color: Color.fromARGB(255, 136, 136, 136)),
    enabledBorder: UnderlineInputBorder( borderSide: BorderSide(color: Color.fromARGB(255, 221, 221, 221), width: 1.5)),
    focusedBorder: UnderlineInputBorder( borderSide: BorderSide(color: Color.fromARGB(255, 136, 136, 136), width: 1.5)),
  );


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,    // 전체 배경색

      // AppBar: 뒤로가기 버튼, 제목
      appBar: AppBar(
        title: const Text('사진 의뢰글 작성', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),),
        centerTitle: true,                // 제목 가운데 정렬
        backgroundColor: Colors.white,  // AppBar 배경색
        foregroundColor: Colors.black,  // AppBar 글자색
        elevation: 0.5,                   // AppBar 그림자
        scrolledUnderElevation: 0,        // 스크롤 시 그림자 제거 (앱바가 스크롤에 가려질 때 그림자 제거) -> surfaceTintColor: Colors.transparent 도 동일한 효과
      ),
    
      // 본문: 의뢰 정보 입력칸, 가격 입력란, 위치 입력칸, 등록 버튼
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag, // 스크롤 시 키보드 숨기기 (입력칸 벗어나면 키보드 숨김)  
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(                                       // Form 위젯으로 감싸기 (입력칸 검증용) ->Form위젯에 child로 유효성 검사가 필요한 위젯 넣기
            key: _formKey,                                   // 폼 키 설정 (입력칸 검증용) -> 위에서 선언. 이 줄이 있어야 _formKey.currentState가 null이 아님
            autovalidateMode: AutovalidateMode.disabled,     // 자동 검증 모드 (disabled: 수동 검증)
            child: Column( 
              crossAxisAlignment: CrossAxisAlignment.start,  // 왼쪽 정렬
              children: [

                // 사진 정보 입력칸(의뢰명, 추가 설명, )
                Container(
                  padding: const EdgeInsets.all(8.0),                  // 안쪽 여백
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Color.fromARGB(255, 221, 221, 221),     // 테두리 색상
                      width: 1.5,                                      // 테두리 두께
                    ),
                    borderRadius: BorderRadius.circular(10),           // 모서리 둥글게
                  ),

                  child : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 사진명 입력란  
                      TextFormField(
                        controller: requestTitleController,              // 컨트롤러 연결
                        decoration: baseDecoration.copyWith(
                          labelText: '의뢰 제목*', 
                          hintText: '제목을 입력하세요',
                        ),
                        // 유효성 검사 -> 위에서 선언한 함수 사용
                        validator: (value) => _validateNotEmpty(value, '의뢰 제목'),
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
                SizedBox(height: 20), // 의뢰 정보 입력칸과 가격 입력칸 사이 간격
                
                // 가격 입력란 
                Container(
                  padding: const EdgeInsets.all(8.0),                  // 안쪽 여백
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Color.fromARGB(255, 221, 221, 221),     // 테두리 색상
                      width: 1.5,                                      // 테두리 두께
                    ),
                    borderRadius: BorderRadius.circular(10),           // 모서리 둥글게
                  ),

                  child : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 유료, 무료 선택 버튼
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
                      const SizedBox(height: 5), // 간격

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
                        // 유효성 검사 -> 빈칸 or 숫자가 아니면 오류 메시지, 유효하면 null 반환. 무료일땐 검사 x
                        validator: _feeTypeIsSelected[1]? (value) => _validateNumeric(value): null,
                        keyboardType: TextInputType.number, // 숫자 키패드
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20), // 가격 입력칸과 위치 입력칸 사이 간격

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
                    onTap: ()  async{
                      final permissionLocation = await ensureLocationPermission(context,needAlways: false);
                      if (!permissionLocation) return; // 권한 없으면 중단

                      _openLocationSelector(context);   // 권한 있으면 -> 위치 선택 화면
                    },
                    borderRadius: BorderRadius.circular(10), // 클릭 영역 모서리 둥글게
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0), // 위아래 여백
                      child: Text(
                        locationController.text.isEmpty
                        ? '의뢰자가 사진을 찍을 위치를 선택하세요'
                        : locationController.text,
                        style: const TextStyle(fontSize: 14, color: Color.fromARGB(255, 136, 136, 136)),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20), // 위치 입력칸과 등록 버튼 사이 간격

                if(pickedPos != null)...[
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
                SizedBox(height: 20), // 위치 입력칸과 등록 버튼 사이 간격
                ],

                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black54,
                    padding: EdgeInsetsGeometry.symmetric(horizontal: 5.5, vertical: 3),

                  ),
                  onPressed: _onTextPressed,
                  child: Container(
                    decoration:BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.black54, width: 1)
                      ),
                    ),
                    child:Text(
                      '위치 지정은 왜 필요한 건가요?',
                    ),
                  ), 
                ),

                if(_showExplanation)...[
                  SizedBox(height: 10,),
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
                        textAlign: TextAlign.left,)
                      ],


                  ),
                ],
                  


              

                


              ], // body children
            ),
          ),
        ),
      ),

      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 18),
        child:
          ElevatedButton(
            onPressed:(){
              _submitForm(); // 클릭시 폼 제출 함수 호출 (입력칸 검증 후 업로드) -> 위에서 선언
            },
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty .resolveWith<Color>((Set<WidgetState> states) {
                if (states.contains(WidgetState.pressed)) {
                  return const Color(0xFFDDECC7);                                                // 눌렀을 때 연두색
                }
                return const Color(0xFF8BC34A);                                                  // 기본색
              }), 
              minimumSize: WidgetStateProperty .all<Size>(const Size(double.infinity, 50)),        // 버튼 크기 (가로 꽉 채우기, 세로 50)
              shape: WidgetStateProperty .all<RoundedRectangleBorder>(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),                                       // 모서리 둥글게
                  side: const BorderSide(color: Color(0xFF8BC34A))                               // 테두리 색상
                )
              )
            ) ,
            child: const Text("등록", style: TextStyle(fontSize: 15, color: Colors.white)),
          ),
      ),// 등록 버튼
                


      
    );
  }
}