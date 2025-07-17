abstract class PermissionClient {
  /// Check notification permission status
  Future<bool> checkNotificationPermission();

  /// Request notification permission
  Future<bool> requestNotificationPermission();

  /// Check camera permission status
  Future<bool> checkCameraPermission();

  /// Request camera permission
  Future<bool> requestCameraPermission();

  /// Check photo gallery (storage) permission status
  Future<bool> checkPhotosPermission();

  /// Request photo gallery (storage) permission
  Future<bool> requestPhotosPermission();

  /// Check location permission status
  Future<bool> checkLocationPermission();

  /// Request location permission
  Future<bool> requestLocationPermission();

  /// Check microphone permission status
  Future<bool> checkMicrophonePermission();

  /// Request microphone permission
  Future<bool> requestMicrophonePermission();

  /// Open app settings page
  Future<bool> launchAppSettings();
}

