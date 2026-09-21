import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../local/cobro_pendiente.dart';
import 'network_exception.dart';

class CobroRepositoryException implements Exception {
  final String message;
  CobroRepositoryException(this.message);

  @override
  String toString() => message;
}

class CobroSyncResultado {
  final Set<String> resueltos;
  final Map<String, String> errores;

  const CobroSyncResultado({required this.resueltos, required this.errores});
}

class CobroRepository {
  final http.Client _client;

  CobroRepository(this._client);

  static const Map<String, String> _jsonHeaders = {
    'Content-Type': 'application/json',
  };

  Future<void> registrar({
    required int idVenta,
    required String metodoPago,
    required int monto,
    required DateTime timestampCobro,
    required String uuidOffline,
    String? uuidCobroGrupo,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.cobrosPath}');
    http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: _jsonHeaders,
            body: jsonEncode({
              'idVenta': idVenta,
              'metodoPago': metodoPago,
              'montoCobrado': monto,
              'timestampCobro': timestampCobro.toUtc().toIso8601String(),
              'uuidTransaccionOffline': uuidOffline,
              if (uuidCobroGrupo != null) 'uuidCobroGrupo': uuidCobroGrupo,
            }),
          )
          .timeout(const Duration(seconds: 20));
    } catch (_) {
      throw NetworkException();
    }

    final code = response.statusCode;
    if (code == 200 || code == 201) return;
    if (code == 401 || code == 403) {
      throw CobroRepositoryException('Tu sesión no tiene permisos para registrar cobros.');
    }
    throw CobroRepositoryException(
      _mensajeError(response.body) ?? 'Error del servidor ($code) al registrar el cobro.',
    );
  }

  Future<CobroSyncResultado> sincronizarLote(List<CobroPendiente> cobros) async {
    if (cobros.isEmpty) {
      return const CobroSyncResultado(resueltos: {}, errores: {});
    }
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.cobrosSyncOfflinePath}');
    http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: _jsonHeaders,
            body: jsonEncode({'items': cobros.map(_itemToJson).toList()}),
          )
          .timeout(const Duration(seconds: 60));
    } catch (_) {
      throw NetworkException();
    }

    if (response.statusCode != 200) {
      throw CobroRepositoryException(
        'Error del servidor (${response.statusCode}) al sincronizar cobros.',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw CobroRepositoryException('Respuesta inesperada del servidor.');
    }

    final resueltos = <String>{};
    for (final p in (decoded['procesados'] as List? ?? const [])) {
      if (p is Map && p['uuidTransaccionOffline'] != null) {
        resueltos.add(p['uuidTransaccionOffline'].toString());
      }
    }
    for (final d in (decoded['duplicados'] as List? ?? const [])) {
      resueltos.add(d.toString());
    }

    final errores = <String, String>{};
    for (final e in (decoded['errores'] as List? ?? const [])) {
      if (e is Map && e['uuidTransaccionOffline'] != null) {
        errores[e['uuidTransaccionOffline'].toString()] =
            (e['motivo'] ?? 'Error al sincronizar.').toString();
      }
    }

    return CobroSyncResultado(resueltos: resueltos, errores: errores);
  }

  Map<String, dynamic> _itemToJson(CobroPendiente c) {
    final json = <String, dynamic>{
      'metodoPago': c.metodoPago,
      'montoCobrado': c.monto,
      'timestampCobro': c.timestampCobro.toUtc().toIso8601String(),
      'uuidTransaccionOffline': c.uuidOffline,
    };
    // El backend exige exactamente uno entre idVenta y uuidVentaOffline.
    if (c.uuidVentaOffline != null) {
      json['uuidVentaOffline'] = c.uuidVentaOffline;
    } else {
      json['idVenta'] = c.idVenta;
    }
    return json;
  }

  String? _mensajeError(String body) {
    if (body.isEmpty) return null;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic> && decoded['error'] is Map<String, dynamic>) {
        final message = (decoded['error'] as Map<String, dynamic>)['message'];
        if (message is String && message.isNotEmpty && message.length <= 300) {
          return message;
        }
      }
    } catch (_) {}
    return null;
  }
}
