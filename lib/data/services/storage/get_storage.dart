import 'package:get_storage/get_storage.dart';

/// Implementation of [StorageProvider] using the GetStorage package.
/// This class provides a concrete implementation of the storage interface
/// using GetStorage as the underlying storage mechanism.
class GetxStorage {
  /// The underlying GetStorage instance used for storage operations
  final GetStorage _storage = GetStorage('video_app');

  Future<void> clear() async {
    await _storage.erase();
    logger('Cleared storage');
  }

  Future<void> delete(String key) async {
    _storage.remove(key);
    logger('Deleted key: $key');
  }

  T? read<T>(String key) {
    logger('Reading from storage: $key');
    final value = _storage.read(key);
    logger('Read value: $value');
    if (value is T) {
      return value;
    }
    return null;
  }

  Future<void> write<T>(String key, T value) async {
    logger('Writing to storage: $key -> $value');
    await _storage.write(key, value);
    logger('Verifying write: ${_storage.read<T>(key)}');
  }

  /// Internal logging method for debugging purposes.
  /// Currently disabled but can be enabled by uncommenting the log statement.
  void logger(String s) {
    // log('GetxStorage: $s');
  }
}
