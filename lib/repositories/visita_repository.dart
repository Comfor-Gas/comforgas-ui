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
        final message = (decoded['error'] as Map<String, dynamic>)['message'];
        if (message is String && message.isNotEmpty) return message;
      }
    } catch (_) {
    }
    return null;
  }
}
