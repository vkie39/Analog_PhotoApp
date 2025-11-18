import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> requestPermission() async {
    if (Platform.isIOS) {
      // iOS 권한 요청
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      print("📱 iOS 알림 권한 상태: ${settings.authorizationStatus}");
    } else {
      // Android 13+ 권한 요청
      NotificationSettings settings = await _messaging.requestPermission();
      print("🤖 Android 알림 권한 상태: ${settings.authorizationStatus}");
    }
  }
}
