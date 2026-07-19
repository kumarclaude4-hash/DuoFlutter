import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecurePrefs {
  static final SecurePrefs _instance = SecurePrefs._();
  static SecurePrefs get instance => _instance;

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  SecurePrefs._();

  Future<void> init() async {}

  Future<String?> get(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (_) {
      return null;
    }
  }

  Future<void> set(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (_) {}
  }

  Future<void> remove(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (_) {}
  }

  Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
    } catch (_) {}
  }

  Future<bool> getBool(String key, {bool defaultValue = false}) async {
    final v = await get(key);
    if (v == null) return defaultValue;
    return v == 'true';
  }

  Future<void> setBool(String key, bool value) async {
    await set(key, value.toString());
  }

  Future<int?> getInt(String key) async {
    final v = await get(key);
    if (v == null) return null;
    return int.tryParse(v);
  }

  Future<void> setInt(String key, int value) async {
    await set(key, value.toString());
  }
}
