import 'dart:async';
import 'package:flutter/widgets.dart';
import 'biometric_service.dart';
import 'secure_storage_service.dart';


class AppLockController extends ChangeNotifier with WidgetsBindingObserver {
  static const int maxAttempts = 3;

  final BiometricService _biometrics;
  final SecureStorageService _storage;

  AppLockController({BiometricService? biometrics, SecureStorageService? storage})
      : _biometrics = biometrics ?? BiometricService(),
        _storage = storage ?? SecureStorageService() {
    WidgetsBinding.instance.addObserver(this);
  }

  bool _locked = false;
  bool _authenticating = false;
  bool _protectSession = false;
  int _failedAttempts = 0;
  bool _attemptsExhausted = false;

  bool get isLocked => _locked;
  bool get isAuthenticating => _authenticating;
  bool get attemptsExhausted => _attemptsExhausted;
  int get remainingAttempts => (maxAttempts - _failedAttempts).clamp(0, maxAttempts);


  Future<void> onSessionChanged({
    required bool isAuthenticated,
    String? userEmail,
  }) async {
    if (!isAuthenticated) {
      _protectSession = false;
      _locked = false;
      _failedAttempts = 0;
      _attemptsExhausted = false;
      notifyListeners();
      return;
    }

    _protectSession = await _storage.isBiometricEnabledFor(userEmail);

    if (_protectSession) {
      _failedAttempts = 0;
      _attemptsExhausted = false;
      _locked = true;
      notifyListeners();
      unawaited(_tryUnlock());
    }
  }

  Future<void> refreshFromStorage({String? userEmail}) async {
    final enabled = await _storage.isBiometricEnabledFor(userEmail);
    _protectSession = enabled;
    if (!enabled) {
      _locked = false;
    }
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_protectSession || _attemptsExhausted) return;

    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _locked = true;
      notifyListeners();
    } else if (state == AppLifecycleState.resumed && _locked) {
      unawaited(_tryUnlock());
    }
  }

  Future<void> _tryUnlock() async {
    if (_authenticating || _attemptsExhausted) return;
    _authenticating = true;
    notifyListeners();

    final ok = await _biometrics.authenticate();

    _authenticating = false;

    if (ok) {
      _failedAttempts = 0;
      _locked = false;
    } else {
      _failedAttempts++;
      if (_failedAttempts >= maxAttempts) {
        // Se agotaron los intentos: quien escucha este controlador
        // (ver _AppShell en main.dart) se encarga de cerrar la sesión
        // y mandar de vuelta al login con correo y contraseña.
        _attemptsExhausted = true;
      }
    }

    notifyListeners();
  }

  /// Botón "Reintentar" / tocar el ícono de huella en la pantalla de bloqueo.
  Future<void> retry() => _tryUnlock();

  /// Limpia el contador después de forzar el logout por intentos
  /// agotados, para que quede en cero si el usuario vuelve a activar
  /// la huella más adelante.
  void resetAttempts() {
    _failedAttempts = 0;
    _attemptsExhausted = false;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
