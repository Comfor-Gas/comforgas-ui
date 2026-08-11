import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/import_agenda_result.dart';
import '../models/visita_model.dart';
import '../utils/json_parsing.dart';

class VisitaRepositoryException implements Exception {
  final String message;
  VisitaRepositoryException(this.message);

  @override
  String toString() => message;
}


class VisitaRepository {
  final http.Client _client;

  VisitaRepository([http.Client? client]) : _client = client ?? http.Client();

  Future<List<VisitaModel>> getVisitasPorUsuarioYFecha({
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
      throw VisitaRepositoryException(
        'No se pudo conectar con el servidor. Revisa tu conexión.',
      );
    }

    if (response.statusCode == 200) {
      final visitas = _parseVisitasList(response.body);
      return visitas.map((v) => v.copyWith(fecha: fecha)).toList();
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

  Future<List<VisitaModel>> listarTodas() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.visitasPath}');

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
      return ImportAgendaResult.fromJson(decoded);
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

  /// Marca el check-in de la visita (POST /api/visitas/{id}/check-in).
  /// El backend valida que esté en PENDIENTE, calcula
  /// `geolocalizacionValida` él mismo y pasa el estado a EN_CURSO.
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

  /// Marca el check-out de la visita (POST /api/visitas/{id}/check-out).
  /// El backend exige que exista al menos una evidencia fotográfica
  /// cargada previamente, y el estado resultante es VISITADO (no
  /// COMPLETADA; ese es un cierre administrativo posterior y opcional).
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

  List<VisitaModel> _parseVisitasList(String body) {
    if (body.isEmpty) return const [];
    final decoded = jsonDecode(body);
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(VisitaModel.fromJson)
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
