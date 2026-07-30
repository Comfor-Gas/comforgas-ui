import 'package:flutter/foundation.dart';

import '../models/auth_user.dart';
import '../models/user_role.dart';
import '../services/auth_api.dart';
import '../services/secure_storage_service.dart';

enum AuthStatus { unknown, unauthenticated, authenticating, authenticated }

class AuthProvider extends ChangeNotifier {
  final AuthApi _api;
  final SecureStorageService _storage;

  AuthProvider({AuthApi? api, SecureStorageService? storage})
      : _api = api ?? AuthApi(),
        _storage = storage ?? SecureStorageService();

  AuthStatus _status = AuthStatus.unknown;
  AuthUser? _user;
  String? _errorMessage;

  AuthStatus get status => _status;
  AuthUser? get user => _user;
  UserRole get role => _user?.role ?? UserRole.unknown;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == AuthStatus.authenticating;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  Future<void> restoreSession() async {
    final hasSession = await _storage.hasSession();
    _status = hasSession ? AuthStatus.authenticated : AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<bool> login({required String email, required String password}) async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _api.login(email: email, password: password);

      await _storage.saveTokens(
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
        role: result.user.role.name,
      );

      _user = result.user;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'Ocurrió un error inesperado. Intenta de nuevo.';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _storage.clear();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
