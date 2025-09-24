// 위치(한국어 주소와 위경도)를 페이지끼리 주고 받기 위한 모델  
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationPickResult {
  final String address;
  final LatLng position;

  const LocationPickResult({
    required this.address,
    required this.position,
  });
}
