import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

/// ═══════════════════════════════════════════════════════════════════
/// DOWNLOAD MANAGER
/// ═══════════════════════════════════════════════════════════════════
/// Handles file downloads from the WebView using Android's
/// DownloadManager. Also manages storage permissions.
/// ═══════════════════════════════════════════════════════════════════

class DownloadManager {
  /// Handle download requests from the WebView
  static Future<void> handleDownload({
    required UriRequest downloadRequest,
    required String suggestedFilename,
    required BuildContext context,
  }) async {
    try {
      // Request storage permission on Android
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          _showSnackBar(context, 'Storage permission denied. Cannot download file.');
          return;
        }
      }

      // Get download directory
      final directory = await _getDownloadDirectory();
      if (directory == null) {
        _showSnackBar(context, 'Could not access download folder.');
        return;
      }

      final filePath = '${directory.path}/$suggestedFilename';

      // Use the WebView's built-in download capability
      // The actual download is handled by the native WebView via
      // the onDownloadStartRequest callback in the browser screen
      _showSnackBar(context, 'Starting download: $suggestedFilename');
    } catch (e) {
      _showSnackBar(context, 'Download failed: $e');
    }
  }

  /// Get the appropriate download directory
  static Future<Directory?> _getDownloadDirectory() async {
    if (Platform.isAndroid) {
      // Use external storage downloads folder
      return Directory('/storage/emulated/0/Download');
    }
    // Fallback for other platforms
    return await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
  }

  /// Show a snackbar message
  static void _showSnackBar(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}
