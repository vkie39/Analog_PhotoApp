import 'package:permission_handler/permission_handler.dart';

/// Handles permission requests needed by the app.
class PermissionService {
  /// Requests location, gallery/storage, and camera permissions.
  /// This should be called when the app starts.
  Future<void> requestInitialPermissions() async {
    await [
      Permission.location,
      Permission.storage,
      Permission.photos,
      Permission.camera,
    ].request();
  }
}
