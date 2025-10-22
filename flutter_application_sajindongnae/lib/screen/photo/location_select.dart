import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:flutter_application_sajindongnae/component/search.dart';
import 'package:flutter_application_sajindongnae/models/location_model.dart';
import 'package:flutter_application_sajindongnae/component/search.dart';



class LocationSelectScreen extends StatefulWidget{
  final LatLng? initialPosition; // 이미 선택된 위치가 있다면 받아와서 표시해줌
  final String ? initialAddress; 
  const LocationSelectScreen({super.key, this.initialPosition, this.initialAddress});
  
  @override
  State<LocationSelectScreen> createState() => LocationSelectScreenState();  
  
}

class LocationSelectScreenState extends State<LocationSelectScreen>{
  
  final _searchController = TextEditingController();   // 검색창 컨트롤러
  GoogleMapController? _mapController;                 // 구글맵 생성 컨트롤러
  CameraPosition? _initialCamera;                      // 지도 초기 위치 설정용 
  bool _initialized = false;                           // 지도를 처음 켤 때만 초기 위치를 세팅해주도록 하는 bool

  Marker? _selectedMarker;                             // 마커 
  String? _selectedAddress;                            // sell_write로 넘겨줄 주소
  LatLng? _selectedLatLng;                             // 위경도값
  final MarkerId _pickedId = const MarkerId('picked');
  static const String _googleApiKey = 'AIzaSyD08a7ITr6A8IgDYt4zDcmeXHvyYKhZrdE'; // TODO: 여긴 나중에 보안을 위해 수정해야 함
  

  @override
  void initState(){
    super.initState();
    _setInitialCameraToCurrentLocation();
  }
  @override
  void dispose() {
    _mapController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _setInitialCameraToCurrentLocation() async{

    // 이전에 선택한 위치가 있으면 그 위치로 초기화
    if(widget.initialPosition != null){
      final pos = widget.initialPosition!;
      final addr = widget.initialAddress ?? await _getAddressFromLatLng(pos);

      _selectedLatLng = pos;
      _selectedAddress = addr;

      _initialCamera = CameraPosition(target: pos, zoom: 14.0);
      _setMarker(pos, title: '선택한 위치', snippet: addr ?? '');

      if (mounted) setState(() {});
      return;
    }

    // 이전 선택이 없으면 현재 위치로 초기화
    CameraPosition target;
    try{
      dev.log('현재 위치 찾는중');
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high, distanceFilter: 0,  // 애뮬레이터 위치는 미국임
        )
      ).timeout(const Duration(seconds: 8));
      target = CameraPosition(target: LatLng(pos.latitude, pos.longitude), zoom:14.0);
    }
    catch(e){
      target = CameraPosition(target: LatLng(37.4665, 126.9326), zoom:14.0);

    }
    if(!mounted) return;
    setState(() {
      _initialCamera = target;    
    });
  
  }



  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,

        appBar: AppBar(
          title: const Text('위치 선택', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),),
          centerTitle: true,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0.5,
          scrolledUnderElevation: 0,
        ),

        body: Column(
          children: [
            SearchBarWidget(
              controller: _searchController,
              onChanged: (value) {
                print('검색어 : $value');
              },
              leadingIcon: IconButton(
                icon: const Icon(Icons.menu, color: Colors.black54),
                onPressed: () {
                  print('photo_sell 메뉴 클릭');
                },
              ),
            ),
            Expanded(
              child: _initialCamera == null
                  ? const Center(child: CircularProgressIndicator())
                  : GoogleMap(
                      initialCameraPosition: _initialCamera!,
                      onMapCreated: (c) => _mapController = c,  // animateCamera 불필요    
                      myLocationButtonEnabled: true,            // 버튼 클릭시 내 위치로 카메라 이동
                      myLocationEnabled: true,                  // 지도 위에 내 위치 표시
                      zoomControlsEnabled: false,               // 줌 버튼(없어도 제스쳐로 줌 가능)
                      markers: {
                          if(_selectedMarker != null) _selectedMarker!,  // setSate에서 생성되는 마커
                      },
                      // 지도 탭하면 마커 갱신
                      onTap: _onMapTap,
                    ),
            ),
            
          ],
        ), 
          
        bottomNavigationBar: Padding( // 하단의 완료 버튼
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: _selectedMarker == null
            ? null
            : () {
                  
                  Navigator.pop(context, LocationPickResult(address: _selectedAddress!, position: _selectedLatLng!));
            },

            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8BC34A),
              foregroundColor: Colors.white,
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              minimumSize: const Size(double.infinity, 50), // 가로 꽉 채우기
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            child: const Text('선택 완료'),
          ),
        ),
      ),
    );
  }

  // 지도 클릭 시 동작
  Future<void> _onMapTap(LatLng pos) async {
    // 1) Geocoding API로 주소 요청
    final address = await _getAddressFromLatLng(pos); // 클릭한 곳을 매개변수로 제공
    _selectedLatLng = pos;

    // 2) 마커와 infoWindow 표시
    if(address != null){
      _selectedAddress = address;
      _setMarker(pos, title: '선택한 위치', snippet: address);

      
      // 마커가 렌더링 되면 주소 정보창을 열기
      await Future.delayed(const Duration(milliseconds: 50));
      _mapController?.showMarkerInfoWindow(_pickedId);
    } 
    else{
      if(mounted){ // 위젯이 죽으면 ScaffoldMessenger.of(context)를 호출할 때 에러남. 이를 방지하기 위해 mounted == true인지 확인
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('주소를 가져올 수 없음')),
        );
      }
    }
  }
  

  // 마커 생성 함수
  void _setMarker(LatLng pos, {required String title, required String snippet}){
    final marker = Marker(
      markerId: _pickedId,
      position: pos,
      infoWindow: InfoWindow(title: title, snippet: snippet),
      );
    
    setState(() {
      _selectedMarker = marker;
    });
  }

  // Geocoding API로 주소 요청 -> 지도에서 사용자가 클릭한 곳의 위경도를 주고 도로명 주소를 받아오는 함수
  Future<String?> _getAddressFromLatLng(LatLng pos) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/geocode/json'
      '?latlng=${pos.latitude},${pos.longitude}'
      '&language=ko'
      '&key=$_googleApiKey'
    );

    final res = await http.get(url);                             // 구글 Geocoding에 요청을 보내고 받은 response
    if (res.statusCode != 200) return null;                      // 200은 정상처리를 의미. 정상이 아니면 null 

    final data = json.decode(res.body) as Map<String, dynamic>;  // body엔 {}객체가 들어있어서 List가 아닌 Map으로 캐스팅. key는 String타입 value는 어떤 타입이든 올 수 있어 dynamic
    if(data['status'] != 'OK') return null;                      // status가 ok일 때만 정상 결과 

    final results = data['results'] as List;                     // 역지오코딩 결과가 여러개일 수 있어 list로 가져옴
    if(results.isEmpty) return null;                             // 빈 list이면 주소를 못 찾은 것

    return results.first['formatted_address'] as String?;        // 아무 문제 x
  }
}
  

