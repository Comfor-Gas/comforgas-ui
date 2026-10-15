import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(),
              iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
            );

  static const String _kAccessToken = 'access_token';
  static const String _kRefreshToken = 'refresh_token';
  static const String _kRole = 'user_role';
  static const String _kSessionEmail = 'session_email';
  static const String _kBiometricEnabled = 'biometric_enabled';
  static const String _kBiometricOwnerEmail = 'biometric_owner_email';

  // En web sin HTTPS el navegador no expone crypto.subtle y
  // flutter_secure_storage falla al escribir. En ese caso se usa Hive.
  static const String _webBoxName = 'sesion_web';

  static bool get _usarHiveEnWeb {
    if (!kIsWeb) return false;
    final uri = Uri.base;
    final esLocal = uri.host == 'localhost' || uri.host == '127.0.0.1';
    return uri.scheme != 'https' && !esLocal;
  }

  Future<Box<String>> _webBox() async {
    if (Hive.isBoxOpen(_webBoxName)) return Hive.box<String>(_webBoxName);
    return Hive.openBox<String>(_webBoxName);
  }

  Future<void> _write(String key, String value) async {
    if (_usarHiveEnWeb) {
      await (await _webBox()).put(key, value);
      return;
    }
    await _storage.write(key: key, value: value);
  }

  Future<String?> _read(String key) async {
    if (_usarHiveEnWeb) return (await _webBox()).get(key);
    return _storage.read(key: key);
  }

  Future<void> _delete(String key) async {
    if (_usarHiveEnWeb) {
      await (await _webBox()).delete(key);
      return;
    }
    await _storage.delete(key: key);
  }

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    String? role,
    String? email,
  }) async {
    await _write(_kAccessToken, accessToken);
    await _write(_kRefreshToken, refreshToken);
    if (role != null) {
      await _write(_kRole, role);
    }
    if (email != null && email.isNotEmpty) {
      await _write(_kSessionEmail, email);
    }
  }

  Future<String?> readAccessToken() => _read(_kAccessToken);

  Future<String?> readRefreshToken() => _read(_kRefreshToken);

  Future<String?> readRole() => _read(_kRole);
  Future<String?> readSessionEmail() => _read(_kSessionEmail);

  Future<bool> hasSession() async {
    final token = await readAccessToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> saveBiometricEnabled(bool enabled, {String? ownerEmail}) async {
    await _write(_kBiometricEnabled, enabled.toString());
    if (enabled && ownerEmail != null && ownerEmail.isNotEmpty) {
      await _write(_kBiometricOwnerEmail, ownerEmail);
    } else if (!enabled) {
      await _delete(_kBiometricOwnerEmail);
    }
  }
  Future<bool> readBiometricEnabled() async {
    final value = await _read(_kBiometricEnabled);
    return value == 'true';
  }
  Future<String?> readBiometricOwnerEmail() => _read(_kBiometricOwnerEmail);

  Future<bool> isBiometricEnabledFor(String? email) async {
    if (email == null || email.isEmpty) return false;
    final enabled = await readBiometricEnabled();
    if (!enabled) return false;
    final owner = await readBiometricOwnerEmail();
    if (owner == null || owner.isEmpty) {
      await _write(_kBiometricOwnerEmail, email);
      return true;
    }
    return owner.toLowerCase() == email.toLowerCase();
  }

  Future<void> clear() async {
    await _delete(_kAccessToken);
    await _delete(_kRefreshToken);
    await _delete(_kRole);
    await _delete(_kSessionEmail);
  }
}