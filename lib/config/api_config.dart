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
  static const String clientesPath = '/api/clientes';
  static const String rutasPath = '/api/rutas';
  static const String visitasPath = '/api/visitas';
  static const String ventasPath = '/api/ventas';
  static const String cobrosPath = '/api/cobros';
  static const String cobrosSyncOfflinePath = '/api/cobros/sync-offline';
  static const String stockMiCamionPath = '/api/stock/mi-camion';
  static const String adminVentasMonitoreoPath = '/api/admin/ventas/monitoreo';
  static const String visitaCheckInSuffix = '/check-in';
  static const String visitaCheckOutSuffix = '/check-out';
  static const String repartidorVisitasPath = '/api/repartidor/visitas';
  static const String visitaResultadoSuffix = '/resultado';
  static const String visitasSyncLotePath = '/api/visitas/sync-lote';
  static const String visitaUbicacionPath = '/api/visitas/ubicacion';
  static const String adminUbicacionesPath = '/api/admin/visitas/ubicaciones';
  static const String adminVisitasPath = '/api/admin/visitas';
  static const String adminVisitasImportPath = '/api/admin/visitas/import';
  static const String adminAgendaSyncPath = '/api/admin/agenda/sync';
  static const String adminAgendaSyncAllPath = '/api/admin/agenda/sync/all';
  static const String evidenciasFotograficasPath = '/api/evidenciasfotograficas';
  static const String _envWsUrl = String.fromEnvironment('WS_URL', defaultValue: '');

  static String get wsBaseUrl {
    if (_envWsUrl.isNotEmpty) return _envWsUrl;
    final http = baseUrl;
    if (http.startsWith('https://')) return 'wss://${http.substring(8)}';
    if (http.startsWith('http://')) return 'ws://${http.substring(7)}';
    return http;
  }

  static const String seguimientoWsPath = '/ws/visitas';
  static const String adminAlertasPath = '/api/admin/visitas/alertas';

  static const String comodatoClientePath = '/api/comodatos/cliente';
  static const String comodatoControlPath = '/api/comodatos/control';
  static const String visitaComodatoSuffix = '/comodato';
  static const String adminComodatosAuditoriaPath = '/api/admin/comodatos/auditoria';

  static const String visitaCanjesSuffix = '/canjes';
  static const String canjesPath = '/api/canjes';
  static const String canjesSyncLotePath = '/api/canjes/sync-lote';
  static const String adminCanjesPath = '/api/admin/canjes';
  static const String adminCanjesReportePath = '/api/admin/canjes/reporte';
}