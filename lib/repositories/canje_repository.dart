import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/canje_garrafa.dart';
import 'network_exception.dart';

class CanjeRepositoryException implements Exception {
  final String message;
  CanjeRepositoryException(this.message);

  @override
  String toString() => message;
}

class CanjeSyncLoteResultado {
  final Set<String> procesados;
  final Set<String> duplicados;
  final Map<String, String> errores;

  const CanjeSyncLoteResultado({
    required this.procesados,
    required this.duplicados,
    required this.errores,
  });
}

class CanjeRepository {
  final http.Client _client;

  CanjeRepository(this._client);

  static const Map<String, String> _jsonHeaders = {
    'Content-Type': 'application/json',
  };

  Future<CanjeGarrafa> registrarCanje(int idVisita, CanjeGarrafaDraft draft) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.canjesPath}');

    http.Response response;
    try {
      response = await _client
          .post(uri, headers: _jsonHeaders, body: jsonEncode(draft.toRequestJson(idVisita)))
          .timeout(const Duration(seconds: 20));
    } catch (_) {
      throw NetworkException();
    }

    final code = response.statusCode;
    if (code == 200 || code == 201) {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw CanjeRepositoryException('Respuesta inesperada del servidor.');
      }
      return CanjeGarrafa.fromJson(decoded);
    }

    if (code == 400 || code == 409) {
      throw CanjeRepositoryException(
        _mensajeError(response.body) ??
            'No se pudo registrar el canje. Verificá los datos.',
      );
    }

    if (code == 401 || code == 403) {
      throw CanjeRepositoryException(
        _mensajeError(response.body) ??
            'Tu sesión no tiene permisos para registrar canjes.',
      );
    }

    throw CanjeRepositoryException(
      _mensajeError(response.body) ??
          'Error del servidor ($code) al registrar el canje.',
    );
  }

  Future<CanjeSyncLoteResultado> sincronizarLote(List<CanjeGarrafaDraft> drafts) async {
    final items = <Map<String, dynamic>>[];
    for (final d in drafts) {
      final idVisita = d.idVisita;
      if (idVisita == null) continue;
      items.add(d.toSyncItemJson(idVisita));
    }
    if (items.isEmpty) {
      return const CanjeSyncLoteResultado(procesados: {}, duplicados: {}, errores: {});
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.canjesSyncLotePath}');

    http.Response response;
    try {
      response = await _client
          .post(uri, headers: _jsonHeaders, body: jsonEncode({'items': items}))
          .timeout(const Duration(seconds: 30));
    } catch (_) {
      throw NetworkException();
    }

    final code = response.statusCode;
    if (code == 200 || code == 201) {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw CanjeRepositoryException('Respuesta inesperada del servidor.');
      }
      final procesados = <String>{};
      for (final p in (decoded['procesados'] as List? ?? const [])) {
        if (p is Map<String, dynamic>) {
          final uuid = (p['uuid_offline'] ?? p['uuidOffline'])?.toString();
          if (uuid != null && uuid.isNotEmpty) procesados.add(uuid);
        }
      }
      final duplicados = <String>{};
      for (final d in (decoded['duplicados'] as List? ?? const [])) {
        final uuid = d?.toString();
        if (uuid != null && uuid.isNotEmpty) duplicados.add(uuid);
      }
      final errores = <String, String>{};
      for (final e in (decoded['errores'] as List? ?? const [])) {
        if (e is Map<String, dynamic>) {
          final uuid = (e['uuid_offline'] ?? e['uuidOffline'])?.toString();
          final msg = (e['error'] ?? e['mensaje'])?.toString() ??
              'Error al sincronizar el canje.';
          if (uuid != null && uuid.isNotEmpty) errores[uuid] = msg;
        }
      }
      return CanjeSyncLoteResultado(
        procesados: procesados,
        duplicados: duplicados,
        errores: errores,
      );
    }

    if (code == 401 || code == 403) {
      throw CanjeRepositoryException(
        _mensajeError(response.body) ??
            'Tu sesión no tiene permisos para sincronizar canjes.',
      );
    }

    throw CanjeRepositoryException(
      _mensajeError(response.body) ??
          'Error del servidor ($code) al sincronizar los canjes.',
    );
  }

  Future<List<CanjeGarrafa>> getCanjesDeVisita(int idVisita) async {
    return const [];
  }

  String? _mensajeError(String body) {
    if (body.isEmpty) return null;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic> &&
          decoded['error'] is Map<String, dynamic>) {
        final message = (decoded['error'] as Map<String, dynamic>)['message'];
        if (message is String && message.isNotEmpty && message.length <= 300) {
          return message;
        }
      }
    } catch (_) {}
    return null;
  }
}
