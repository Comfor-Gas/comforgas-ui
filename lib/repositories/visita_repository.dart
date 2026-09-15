import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/agenda_item_model.dart';
import '../models/import_agenda_result.dart';
import '../models/venta_social.dart';
import '../models/visita_model.dart';
import '../utils/json_parsing.dart';
import 'network_exception.dart';

class VisitaRepositoryException implements Exception {
  final String message;
  VisitaRepositoryException(this.message);

  @override
  String toString() => message;
}


class VisitaRepository {
  final http.Client _client;

  VisitaRepository([http.Client? client]) : _client = client ?? http.Client();

  /// Agenda del chofer autenticado para una fecha. El backend devuelve
  /// `AgendaItemResponse` (no `VisitaResponse`): cada ítem trae `idAgendaItem`
  /// siempre presente, e `idVisita`/`estadoEjecucion` nulos hasta que el
  /// chofer hace el primer check-in.
  Future<List<AgendaItemModel>> getVisitasPorUsuarioYFecha({
    required String idUsuario,
    required DateTime fecha,
  }) async {
    final fechaStr = formatDateOnly(fecha);
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.visitasPath}/$idUsuario/$fechaStr',
    );

    http.Response response;
    try {
      response = await _client
          .get(uri, headers: const {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 20));
    } catch (_) {
      throw NetworkException();
    }

    if (response.statusCode == 200) {
      return _parseAgendaItemsList(response.body)
          .map((item) => item.fecha == null ? item.copyWith(fecha: fecha) : item)
          .toList();
    }

    if (response.statusCode == 403) {
      throw VisitaRepositoryException(
        _extractErrorMessage(response.body) ??
            'No tenés permisos para ver la agenda de este usuario.',
      );
    }

    if (response.statusCode == 401) {
      throw VisitaRepositoryException(
        _extractErrorMessage(response.body) ?? 'Tu sesión expiró.',
      );
    }

    throw VisitaRepositoryException(
      _extractErrorMessage(response.body) ??
          'Error del servidor (${response.statusCode}). Intenta más tarde.',
    );
  }


  Future<VisitaModel> crearVisita(VisitaModel visita) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.adminVisitasPath}');

    http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(visita.toJson()),
          )
          .timeout(const Duration(seconds: 20));
    } catch (_) {
      throw VisitaRepositoryException(
        'No se pudo conectar con el servidor. Revisa tu conexión.',
      );
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw VisitaRepositoryException('Respuesta inesperada del servidor.');
      }
      return VisitaModel.fromJson(decoded);
    }

    if (response.statusCode == 400) {
      throw VisitaRepositoryException(
        _extractErrorMessage(response.body) ?? 'Datos de la visita inválidos.',
      );
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw VisitaRepositoryException(
        _extractErrorMessage(response.body) ??
            'Tu sesión no tiene permisos para registrar visitas.',
      );
    }

    throw VisitaRepositoryException(
      _extractErrorMessage(response.body) ??
          'Error del servidor (${response.statusCode}). Intenta más tarde.',
    );
  }

  static const int _pageSize = 200;

  static const int _maxPaginas = 100;
  Future<List<VisitaModel>> listarTodas() async {
    final acumulado = <VisitaModel>[];

    for (var page = 0; page < _maxPaginas; page++) {
      final pagina = await _listarPagina(page: page, size: _pageSize);
      acumulado.addAll(pagina);
      if (pagina.length < _pageSize) break;
    }

    return acumulado;
  }

  Future<List<VisitaModel>> _listarPagina({
    required int page,
    required int size,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.visitasPath}')
        .replace(queryParameters: {'page': '$page', 'size': '$size'});

    http.Response response;
    try {
      response = await _client
          .get(uri, headers: const {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 20));
    } catch (_) {
      throw VisitaRepositoryException(
        'No se pudo conectar con el servidor. Revisa tu conexión.',
      );
    }

    if (response.statusCode == 200) {
      return _parseVisitasList(response.body);
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw VisitaRepositoryException(
        _extractErrorMessage(response.body) ??
            'No tenés permisos para ver el listado de visitas.',
      );
    }

    throw VisitaRepositoryException(
      _extractErrorMessage(response.body) ??
          'Error del servidor (${response.statusCode}). Intenta más tarde.',
    );
  }

  Future<ImportAgendaResult> importarAgenda(List<VisitaModel> visitas) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.adminVisitasImportPath}');

    http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'visitas': visitas.map((v) => v.toJson()).toList(),
            }),
          )
          .timeout(const Duration(seconds: 20));
    } catch (_) {
      throw VisitaRepositoryException(
        'No se pudo conectar con el servidor. Revisa tu conexión.',
      );
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw VisitaRepositoryException('Respuesta inesperada del servidor.');
      }
      return ImportAgendaResult.fromJson(decoded);
    }

    if (response.statusCode == 400) {
      throw VisitaRepositoryException(
        _extractErrorMessage(response.body) ??
            'Datos de la agenda inválidos.',
      );
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw VisitaRepositoryException(
        _extractErrorMessage(response.body) ??
            'Tu sesión no tiene permisos para publicar visitas.',
      );
    }

    throw VisitaRepositoryException(
      _extractErrorMessage(response.body) ??
          'Error del servidor (${response.statusCode}). Intenta más tarde.',
    );
  }

  /// Sincroniza la agenda completa de un chofer para una fecha,
  /// trayendo las visitas planificadas desde la fuente externa
  /// configurada en el backend (mock o API real) e importándolas.
  Future<ImportAgendaResult> sincronizarAgenda({
    required String choferId,
    required DateTime fecha,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.adminAgendaSyncPath}');

    http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'choferId': choferId,
              'fecha': formatDateOnly(fecha),
            }),
          )
          .timeout(const Duration(seconds: 30));
    } catch (_) {
      throw VisitaRepositoryException(
        'No se pudo conectar con el servidor. Revisa tu conexión.',
      );
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw VisitaRepositoryException('Respuesta inesperada del servidor.');
      }
      return _syncResultToImport(decoded);
    }

    if (response.statusCode == 400) {
      throw VisitaRepositoryException(
        _extractErrorMessage(response.body) ??
            'No se pudo sincronizar la agenda. Verificá el chofer y la fecha.',
      );
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw VisitaRepositoryException(
        _extractErrorMessage(response.body) ??
            'Tu sesión no tiene permisos para sincronizar la agenda.',
      );
    }

    throw VisitaRepositoryException(
      _extractErrorMessage(response.body) ??
          'Error del servidor (${response.statusCode}). Intenta más tarde.',
    );
  }

  Future<ImportAgendaResult> sincronizarAgendaTodos({
    required DateTime fecha,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.adminAgendaSyncAllPath}');

    http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'fecha': formatDateOnly(fecha)}),
          )
          .timeout(const Duration(seconds: 60));
    } catch (_) {
      throw VisitaRepositoryException(
        'No se pudo conectar con el servidor. Revisa tu conexión.',
      );
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return _syncResultToImport(decoded);
      }
      if (decoded is! List) {
        throw VisitaRepositoryException('Respuesta inesperada del servidor.');
      }
      int insertadas = 0;
      int omitidas = 0;
      final errores = <String>[];
      for (final item in decoded.whereType<Map<String, dynamic>>()) {
        final r = _syncResultToImport(item);
        insertadas += r.insertadas;
        omitidas += r.omitidas;
        errores.addAll(r.errores);
      }
      return ImportAgendaResult(
        totalRecibidas: insertadas + omitidas,
        insertadas: insertadas,
        omitidas: omitidas,
        errores: errores,
      );
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw VisitaRepositoryException(
        _extractErrorMessage(response.body) ??
            'Tu sesión no tiene permisos para sincronizar la agenda.',
      );
    }

    throw VisitaRepositoryException(
      _extractErrorMessage(response.body) ??
          'Error del servidor (${response.statusCode}). Intenta más tarde.',
    );
  }

  ImportAgendaResult _syncResultToImport(Map<String, dynamic> json) {
    final insertadas =
        parseInt(json['itemsInsertados']) ?? parseInt(json['insertadas']) ?? 0;
    final actualizadas = parseInt(json['itemsActualizados']) ?? 0;
    final sinCambio =
        parseInt(json['sinCambio']) ?? parseInt(json['omitidas']) ?? 0;
    final omitidas = actualizadas + sinCambio;
    final errores =
        (json['errores'] as List?)?.whereType<String>().toList() ?? const [];
    return ImportAgendaResult(
      totalRecibidas: parseInt(json['totalRecibidas']) ?? insertadas + omitidas,
      insertadas: insertadas,
      omitidas: omitidas,
      errores: errores,
    );
  }

  Future<VisitaModel> actualizarParcial(
    int idVisita, {
    DateTime? fecha,
    int? ordenVisita,
    Map<String, dynamic>? sucursalSnapshot,
    Map<String, dynamic>? rutaSnapshot,
    String? observaciones,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.visitasPath}/$idVisita/parcial',
    );

    http.Response response;
    try {
      response = await _client
          .put(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              if (fecha != null) 'fecha': formatDateOnly(fecha),
              if (ordenVisita != null) 'ordenVisita': ordenVisita,
              if (sucursalSnapshot != null) 'sucursalSnapshot': sucursalSnapshot,
              if (rutaSnapshot != null) 'rutaSnapshot': rutaSnapshot,
              if (observaciones != null) 'observaciones': observaciones,
            }),
          )
          .timeout(const Duration(seconds: 20));
    } catch (_) {
      throw VisitaRepositoryException(
        'No se pudo conectar con el servidor. Revisa tu conexión.',
      );
    }

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw VisitaRepositoryException('Respuesta inesperada del servidor.');
      }
      return VisitaModel.fromJson(decoded);
    }

    if (response.statusCode == 400 || response.statusCode == 409) {
      throw VisitaRepositoryException(
        _extractErrorMessage(response.body) ??
            'No se pudo modificar la visita.',
      );
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw VisitaRepositoryException(
        _extractErrorMessage(response.body) ??
            'Tu sesión no tiene permisos para modificar visitas.',
      );
    }

    throw VisitaRepositoryException(
      _extractErrorMessage(response.body) ??
          'Error del servidor (${response.statusCode}). Intenta más tarde.',
    );
  }


  Future<VisitaModel> iniciarVisita(
    int idVisita, {
    required double latitud,
    required double longitud,
    DateTime? timestampDispositivo,
    double? precisionMetros,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.visitasPath}/$idVisita${ApiConfig.visitaCheckInSuffix}',
    );

    http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'latitud': latitud,
              'longitud': longitud,
              if (timestampDispositivo != null)
                'timestampDispositivo': timestampDispositivo.toUtc().toIso8601String(),
              if (precisionMetros != null) 'precisionMetros': precisionMetros,
            }),
          )
          .timeout(const Duration(seconds: 20));
    } catch (_) {
      throw NetworkException();
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw VisitaRepositoryException('Respuesta inesperada del servidor.');
      }
      return VisitaModel.fromJson(decoded);
    }

    if (response.statusCode == 400 || response.statusCode == 409) {
      throw VisitaRepositoryException(
        _extractErrorMessage(response.body) ??
            'No se pudo iniciar la visita. Verificá el orden de la ruta.',
      );
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw VisitaRepositoryException(
        _extractErrorMessage(response.body) ??
            'Tu sesión no tiene permisos para iniciar visitas.',
      );
    }

    throw VisitaRepositoryException(
      _extractErrorMessage(response.body) ??
          'Error del servidor (${response.statusCode}). Intenta más tarde.',
    );
  }

  Future<PausaSocialResult> pausarSocial(
    int idVisita,
    PausaSocialDraft draft,
  ) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.visitasPath}/$idVisita${ApiConfig.visitaPausarSocialSuffix}',
    );
    final decoded = await _patchSocial(uri, draft.toRequestJson());
    return PausaSocialResult.fromJson(decoded);
  }

  Future<ReanudarSocialResult> reanudarSocial(
    int idVisita,
    ReanudarSocialDraft draft,
  ) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.visitasPath}/$idVisita${ApiConfig.visitaReanudarSocialSuffix}',
    );
    final decoded = await _patchSocial(uri, draft.toRequestJson());
    return ReanudarSocialResult.fromJson(decoded);
  }

  Future<Map<String, dynamic>> _patchSocial(Uri uri, Map<String, dynamic> body) async {
    http.Response response;
    try {
      final request = http.Request('PATCH', uri)
        ..headers.addAll(const {'Content-Type': 'application/json'})
        ..body = jsonEncode(body);
      final streamed = await _client.send(request).timeout(const Duration(seconds: 20));
      response = await http.Response.fromStream(streamed);
    } catch (_) {
      throw NetworkException();
    }

    final code = response.statusCode;
    if (code == 200 || code == 201) {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw VisitaRepositoryException('Respuesta inesperada del servidor.');
      }
      return decoded;
    }

    if (code == 400 || code == 409) {
      throw VisitaRepositoryException(
        _extractErrorMessage(response.body) ??
            'No se pudo procesar la venta social. Verificá los datos.',
      );
    }

    if (code == 401 || code == 403) {
      throw VisitaRepositoryException(
        _extractErrorMessage(response.body) ??
            'Tu sesión no tiene permisos para esta operación.',
      );
    }

    throw VisitaRepositoryException(
      _extractErrorMessage(response.body) ??
          'Error del servidor ($code). Intentá más tarde.',
    );
  }

  Future<VisitaModel> finalizarVisita(
    int idVisita, {
    String? observaciones,
    DateTime? timestampFin,
    double? latitudFin,
    double? longitudFin,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.visitasPath}/$idVisita${ApiConfig.visitaCheckOutSuffix}',
    );

    http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              if (observaciones != null && observaciones.trim().isNotEmpty)
                'observaciones': observaciones.trim(),
              'timestampFin': (timestampFin ?? DateTime.now()).toUtc().toIso8601String(),
              if (latitudFin != null) 'latitudFin': latitudFin,
              if (longitudFin != null) 'longitudFin': longitudFin,
            }),
          )
          .timeout(const Duration(seconds: 20));
    } catch (_) {
      throw NetworkException();
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw VisitaRepositoryException('Respuesta inesperada del servidor.');
      }
      return VisitaModel.fromJson(decoded);
    }

    if (response.statusCode == 400 || response.statusCode == 409) {
      throw VisitaRepositoryException(
        _extractErrorMessage(response.body) ??
            'No se pudo finalizar la visita. Verificá que hayas cargado la evidencia fotográfica.',
      );
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw VisitaRepositoryException(
        _extractErrorMessage(response.body) ??
            'Tu sesión no tiene permisos para finalizar visitas.',
      );
    }

    throw VisitaRepositoryException(
      _extractErrorMessage(response.body) ??
          'Error del servidor (${response.statusCode}). Intenta más tarde.',
    );
  }

  Future<void> cancelar(int idVisita) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.visitasPath}/$idVisita',
    );

    http.Response response;
    try {
      response = await _client
          .delete(uri, headers: const {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 20));
    } catch (_) {
      throw VisitaRepositoryException(
        'No se pudo conectar con el servidor. Revisa tu conexión.',
      );
    }

    if (response.statusCode == 204 || response.statusCode == 200) {
      return;
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw VisitaRepositoryException(
        _extractErrorMessage(response.body) ??
            'Tu sesión no tiene permisos para cancelar visitas.',
      );
    }

    throw VisitaRepositoryException(
      _extractErrorMessage(response.body) ??
          'Error del servidor (${response.statusCode}). Intenta más tarde.',
    );
  }

  Future<VisitaModel> cerrarVisitaConEstado(
    int idVisita,
    String estadoFinal, {
    String? observaciones,
    double? latitudFin,
    double? longitudFin,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.repartidorVisitasPath}/$idVisita${ApiConfig.visitaResultadoSuffix}',
    );

    http.Response response;
    try {
      response = await _client
          .patch(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'estadoFinal': estadoFinal,
              if (observaciones != null && observaciones.trim().isNotEmpty)
                'observaciones': observaciones.trim(),
              'timestampFin': DateTime.now().toUtc().toIso8601String(),
              if (latitudFin != null) 'latitudFin': latitudFin,
              if (longitudFin != null) 'longitudFin': longitudFin,
            }),
          )
          .timeout(const Duration(seconds: 20));
    } catch (_) {
      throw NetworkException();
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw VisitaRepositoryException('Respuesta inesperada del servidor.');
      }
      return VisitaModel.fromJson(decoded);
    }

    if (response.statusCode == 400 || response.statusCode == 409) {
      throw VisitaRepositoryException(
        _extractErrorMessage(response.body) ??
            'No se pudo cancelar la visita.',
      );
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw VisitaRepositoryException(
        _extractErrorMessage(response.body) ??
            'Tu sesión no tiene permisos para cancelar visitas.',
      );
    }

    throw VisitaRepositoryException(
      _extractErrorMessage(response.body) ??
          'Error del servidor (${response.statusCode}). Intenta más tarde.',
    );
  }

  List<VisitaModel> _parseVisitasList(String body) {
    if (body.isEmpty) return const [];
    final decoded = jsonDecode(body);
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(VisitaModel.fromJson)
        .toList();
  }

  List<AgendaItemModel> _parseAgendaItemsList(String body) {
    if (body.isEmpty) return const [];
    final decoded = jsonDecode(body);
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(AgendaItemModel.fromJson)
        .toList();
  }


  String? _extractErrorMessage(String body) {
    if (body.isEmpty) return null;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic> &&
          decoded['error'] is Map<String, dynamic>) {
        final error = decoded['error'] as Map<String, dynamic>;
        final code = error['code'] as String?;
        final message = error['message'];
        if (message is String && message.isNotEmpty) {
          return _sanitizeMessage(message, code);
        }
      }
    } catch (_) {
    }
    return null;
  }


  String? _sanitizeMessage(String raw, String? code) {
    if (code == 'EXTERNAL_AGENDA_UNAVAILABLE') {
      return 'El servicio de sincronización de agenda no está disponible '
          'en este momento (la fuente externa no responde). '
          'Probá de nuevo más tarde o contactá al administrador.';
    }

    final looksLikeHtmlOrJunk = raw.contains('<!DOCTYPE') ||
        raw.contains('<html') ||
        raw.contains('font-face') ||
        raw.contains('base64,') ||
        raw.length > 300;

    if (!looksLikeHtmlOrJunk) return raw;

    return 'Ocurrió un error inesperado en el servidor. Intentá de nuevo '
        'más tarde; si el problema persiste, contactá al administrador.';
  }
}
