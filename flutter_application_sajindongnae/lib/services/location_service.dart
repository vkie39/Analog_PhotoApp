import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LocationService {
  static Future<void> updateUserLocation() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // 위치 권한 요청
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      print("❌ 위치 권한 없음");
      return;
    }

    try {
      // 현재 위치 가져오기
      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Firestore 업데이트
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'position': GeoPoint(pos.latitude, pos.longitude),
      });

      print("📍 사용자 위치 업데이트 완료: ${pos.latitude}, ${pos.longitude}");
    } catch (e) {
      print("🔥 위치 업데이트 실패: $e");
    }
  }
}
