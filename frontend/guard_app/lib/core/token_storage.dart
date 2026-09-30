import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _key = 'jwt_token';

  // iOS: readable only while the phone is unlocked, and never copied to
  // iCloud/iTunes backups or a new phone (the *_this_device class).
  // Android: stored with EncryptedSharedPreferences (Keystore-backed keys).
  static const _storage = FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.unlocked_this_device,
    ),
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static Future<void> save(String token) async {
    await _storage.write(key: _key, value: token);
  }

  static Future<String?> read() async {
    return await _storage.read(key: _key);
  }

  static Future<void> clear() async {
    await _storage.delete(key: _key);
  }
}
