import 'package:permission_handler/permission_handler.dart';

/// ═══════════════════════════════════════════════════════════════════
/// PERMISSION HELPER
/// ═══════════════════════════════════════════════════════════════════
/// Manages all runtime permissions required by the browser.
/// Only requests permissions that are actually needed for functionality.
/// ═══════════════════════════════════════════════════════════════════

class PermissionHelper {
  /// Request all necessary permissions on app startup
  static Future<void> requestAll() async {
    // Camera: needed for file uploads (camera capture)
    await Permission.camera.request();

    // Microphone: needed for video recording with audio
    await Permission.microphone.request();

    // Photos: needed for file uploads from gallery
    await Permission.photos.request();

    // Storage: needed for downloads
    await Permission.storage.request();

    // Notification: optional, for download completion notifications
    await Permission.notification.request();
  }

  /// Check if a specific permission is granted
  static Future<bool> isGranted(Permission permission) async {
    return await permission.isGranted;
  }

  /// Request a single permission
  static Future<bool> request(Permission permission) async {
    final status = await permission.request();
    return status.isGranted;
  }
}
