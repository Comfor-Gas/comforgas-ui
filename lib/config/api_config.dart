import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

class ApiConfig {
  // Si se pasa --dart-define=API_URL=...
  // se usa ese valor. Si no, cae en las URLs de desarrollo local.
  static const String _envUrl = String.fromEnvironment('API_URL', defaultValue: '');

  static String get baseUrl {
    if (_envUrl.isNotEmpty) return _envUrl;

    // Fallback para desarrollo local (sin definir API_URL)
    if (kIsWeb) return 'http://localhost:8080';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080';
    }
    return 'http://localhost:8080';
  }

  static const String loginPath = '/api/auth/login';
  static const String refreshPath = '/api/auth/refresh';
  static const String logoutPath = '/api/auth/logout';
  static const String mePath = '/api/auth/me';
  static const String registerPath = '/api/admin/usuarios';
  static const String usuariosPath = '/api/admin/usuarios';
  static const String sucursalesPath = '/api/sucursales';
  static const String rutasPath = '/api/rutas';
  static const String visitasPath = '/api/visitas';
  static const String visitaCheckInSuffix = '/check-in';
  static const String visitaCheckOutSuffix = '/check-out';
  static const String visitasSyncLotePath = '/api/visitas/sync-lote';
  static const String adminVisitasPath = '/api/admin/visitas';
  static const String adminVisitasImportPath = '/api/admin/visitas/import';
  static const String adminAgendaSyncPath = '/api/admin/agenda/sync';
  static const String evidenciasFotograficasPath = '/api/evidenciasfotograficas';
}