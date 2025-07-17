import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

class PermissionHandlerClient {
  const PermissionHandlerClient();

  Future<bool> _requestPermission(Permission permission) async {
    try {
      final status = await permission.request();
      return status.isGranted;
    } catch (e) {
      debugPrint('Error requesting permission: $e');
      return false;
    }
  }

  Future<bool> _hasPermission(Permission permission) async {
    try {
      final status = await permission.status;
      debugPrint('Permission status for ${permission.toString()}: $status');
      return status.isGranted;
    } catch (e) {
      debugPrint('Error checking permission status: $e');
      return false;
    }
  }


  Future<bool> checkStoragePermission() async {
    return await _hasPermission(Permission.storage);
  }

  Future<bool> requestStoragePermission() async {
    return await _requestPermission(Permission.storage);
  }

  Future<bool> launchAppSettings() async {
    try {
      return await openAppSettings();
    } catch (e) {
      debugPrint('Error launching app settings: $e');
      return false;
    }
  }
}
