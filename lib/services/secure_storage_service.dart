import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
            );

  static const String _kAccessToken = 'access_token';
  static const String _kRefreshToken = 'refresh_token';
  static const String _kRole = 'user_role';
  static const String _kSessionEmail = 'session_email';
  static const String _kBiometricEnabled = 'biometric_enabled';
  static const String _kBiometricOwnerEmail = 'biometric_owner_email';

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    String? role,
    String? email,
  }) async {
    await _storage.write(key: _kAccessToken, value: accessToken);
    await _storage.write(key: _kRefreshToken, value: refreshToken);
    if (role != null) {
      await _storage.write(key: _kRole, value: role);
    }
    if (email != null && email.isNotEmpty) {
      await _storage.write(key: _kSessionEmail, value: email);
    }
  }

  Future<String?> readAccessToken() => _storage.read(key: _kAccessToken);

  Future<String?> readRefreshToken() => _storage.read(key: _kRefreshToken);

  Future<String?> readRole() => _storage.read(key: _kRole);
  Future<String?> readSessionEmail() => _storage.read(key: _kSessionEmail);

  Future<bool> hasSession() async {
    final token = await readAccessToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> saveBiometricEnabled(bool enabled, {String? ownerEmail}) async {
    await _storage.write(key: _kBiometricEnabled, value: enabled.toString());
    if (enabled && ownerEmail != null && ownerEmail.isNotEmpty) {
      await _storage.write(key: _kBiometricOwnerEmail, value: ownerEmail);
    } else if (!enabled) {
      await _storage.delete(key: _kBiometricOwnerEmail);
    }
  }
  Future<bool> readBiometricEnabled() async {
    final value = await _storage.read(key: _kBiometricEnabled);
    return value == 'true';
  }
  Future<String?> readBiometricOwnerEmail() =>
      _storage.read(key: _kBiometricOwnerEmail);

  Future<bool> isBiometricEnabledFor(String? email) async {
    if (email == null || email.isEmpty) return false;
    final enabled = await readBiometricEnabled();
    if (!enabled) return false;
    final owner = await readBiometricOwnerEmail();
    if (owner == null || owner.isEmpty) {
      await _storage.write(key: _kBiometricOwnerEmail, value: email);
      return true;
    }
    return owner.toLowerCase() == email.toLowerCase();
  }

  Future<void> clear() async {
    await _storage.delete(key: _kAccessToken);
    await _storage.delete(key: _kRefreshToken);
    await _storage.delete(key: _kRole);
    await _storage.delete(key: _kSessionEmail);
  }
}
