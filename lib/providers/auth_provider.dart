import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/auth_user.dart';
import '../models/user_role.dart';
import '../services/auth_api.dart';
import '../services/auth_http_client.dart';
import '../services/secure_storage_service.dart';

enum AuthStatus { unknown, unauthenticated, authenticating, authenticated }

class AuthProvider extends ChangeNotifier {
  final AuthApi _api;
  final SecureStorageService _storage;

  AuthProvider({AuthApi? api, SecureStorageService? storage})
      : _api = api ?? AuthApi(),
        _storage = storage ?? SecureStorageService();

  late final AuthHttpClient _apiClient = AuthHttpClient(
    storage: _storage,
    onSessionExpired: _handleSessionExpired,
  );
  http.Client get apiClient => _apiClient;
  Future<void> _handleSessionExpired() async {
    await logout();
  }

  AuthStatus _status = AuthStatus.unknown;
  AuthUser? _user;
  String? _accessToken;
  String? _errorMessage;

  AuthStatus get status => _status;
  AuthUser? get user => _user;
  String? get accessToken => _accessToken;
  UserRole get role => _user?.role ?? UserRole.unknown;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == AuthStatus.authenticating;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  Future<void> restoreSession() async {
    final refreshToken = await _storage.readRefreshToken();

    if (refreshToken == null || refreshToken.isEmpty) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    try {
      final result = await _api.refresh(refreshToken: refreshToken);

      await _storage.saveTokens(
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
        role: result.user.role.name,
      );

      _accessToken = result.accessToken;
      _user = result.user;
      _status = AuthStatus.authenticated;
    } catch (_) {
      // Refresh invalido o expirado, limpia y vuelve a pedir loguearse
      await _storage.clear();
      _accessToken = null;
      _user = null;
      _status = AuthStatus.unauthenticated;
    }

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

      _accessToken = result.accessToken;
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

  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    required String rol,
  }) async {
    final token = _accessToken;
    if (token == null || token.isEmpty) {
      _errorMessage =
          'Necesitás iniciar sesión con un rol autorizado para registrar usuarios.';
      notifyListeners();
      return false;
    }

    _errorMessage = null;
    try {
      await _api.register(
        accessToken: token,
        email: email,
        password: password,
        fullName: fullName,
        rol: rol,
      );
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'No se pudo registrar el usuario. Intenta de nuevo.';
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
    _accessToken = null;
    _user = null;
    _errorMessage = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
