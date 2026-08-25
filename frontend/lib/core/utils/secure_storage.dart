import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _keyToken = 'auth_token';
  static const _keyRole = 'user_role';
  static const _keyUserId = 'user_id';
  static const _keyUserName = 'user_name';
  static const _keyUserEmail = 'user_email';
  static const _keyPin = 'app_pin';
  static const _keyLastLoginDate = 'last_login_date';

  // ── Token ──────────────────────────────────────────────────────────────────
  static Future<void> saveToken(String token) =>
      _storage.write(key: _keyToken, value: token);
  static Future<String?> getToken() => _storage.read(key: _keyToken);

  // ── Role ───────────────────────────────────────────────────────────────────
  static Future<void> saveRole(String role) =>
      _storage.write(key: _keyRole, value: role);
  static Future<String?> getRole() => _storage.read(key: _keyRole);

  // ── User ID ────────────────────────────────────────────────────────────────
  static Future<void> saveUserId(String id) =>
      _storage.write(key: _keyUserId, value: id);
  static Future<String?> getUserId() => _storage.read(key: _keyUserId);

  // ── User Name ──────────────────────────────────────────────────────────────
  static Future<void> saveUserName(String name) =>
      _storage.write(key: _keyUserName, value: name);
  static Future<String?> getUserName() => _storage.read(key: _keyUserName);

  // ── User Email ─────────────────────────────────────────────────────────────
  static Future<void> saveUserEmail(String email) =>
      _storage.write(key: _keyUserEmail, value: email);
  static Future<String?> getUserEmail() => _storage.read(key: _keyUserEmail);

  // ── PIN Lock ────────────────────────────────────────────────────────────────
  static Future<void> savePin(String pin) =>
      _storage.write(key: _keyPin, value: pin);
  static Future<String?> getPin() => _storage.read(key: _keyPin);
  static Future<void> deletePin() => _storage.delete(key: _keyPin);

  // ── Last Login Date (for 30-day auto-logout) ───────────────────────────────
  static Future<void> saveLastLoginDate(String date) =>
      _storage.write(key: _keyLastLoginDate, value: date);
  static Future<String?> getLastLoginDate() =>
      _storage.read(key: _keyLastLoginDate);

  // ── Clear all ──────────────────────────────────────────────────────────────
  static Future<void> deleteAll() => _storage.deleteAll();
}
