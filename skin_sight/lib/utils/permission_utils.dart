import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionUtils {
  /// Request a specific permission and handle the result
  static Future<bool> requestPermission(
    BuildContext context,
    Permission permission,
    String permissionName,
    String deniedMessage,
    String permanentlyDeniedMessage,
  ) async {
    try {
      final status = await permission.request();
      
      if (status.isGranted) {
        return true;
      } else if (status.isPermanentlyDenied) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(permanentlyDeniedMessage),
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Settings',
                onPressed: () => openAppSettings(),
              ),
            ),
          );
        }
        return false;
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(deniedMessage),
              duration: const Duration(seconds: 3),
            ),
          );
        }
        return false;
      }
    } catch (e) {
      debugPrint('Error requesting $permissionName permission: $e');
      return false;
    }
  }
  
  /// Request camera permission specifically
  static Future<bool> requestCameraPermission(BuildContext context) async {
    return requestPermission(
      context,
      Permission.camera,
      'camera',
      'Camera permission denied. Cannot access camera.',
      'Camera permission is required to use this feature. Please enable it in app settings.',
    );
  }
  
  /// Request storage permission specifically
  static Future<bool> requestStoragePermission(BuildContext context) async {
    return requestPermission(
      context,
      Permission.storage,
      'storage',
      'Storage permission denied. Cannot save images.',
      'Storage permission is required to save images. Please enable it in app settings.',
    );
  }
} 