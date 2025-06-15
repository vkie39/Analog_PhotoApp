import 'package:flutter/material.dart';
import 'package:flutter_application_sajindongnae/services/location_service.dart';
import 'package:geolocator/geolocator.dart';


class PhotoSellScreen extends StatefulWidget {
  const PhotoSellScreen({super.key});
  
  @override
  State<PhotoSellScreen> createState() => _PhotoSellScreenState();
} 

class _PhotoSellScreenState extends State<PhotoSellScreen> {
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    final position = await LocationService().getCurrentLocation();
    setState(() {
      _currentPosition = position;
    });
    // TODO: 위치 정보(_currentPosition)를 화면에 표시하는 위젯을 추가하세요.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('사진 판매'),),
      // TODO: 사진 판매 UI 구현 시 _currentPosition을 활용해 위치 기반 기능을 추가하세요.
    );
  }
}