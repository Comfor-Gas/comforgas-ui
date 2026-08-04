import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

class ApiConfig {
  static String get baseUrl {
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
  static const String visitasPath = '/api/visitas';
  static const String adminVisitasPath = '/api/admin/visitas';
  static const String adminVisitasImportPath = '/api/admin/visitas/import';
  static const String evidenciasFotograficasPath = '/api/evidenciasfotograficas';
}
