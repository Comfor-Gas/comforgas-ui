import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/arqueo_caja.dart';
import '../models/cuenta_corriente_resumen.dart';
import '../utils/json_parsing.dart';
import 'network_exception.dart';

class CobranzaRepositoryException implements Exception {
  final String message;
  final int? statusCode;

  CobranzaRepositoryException(this.message, {this.statusCode});

  bool get endpointNoDisponible => statusCode == 404 || statusCode == 501;

  @override
  String toString() => message;
}

class CobranzaRepository {
  final http.Client _client;

  CobranzaRepository([http.Client? client]) : _client = client ?? http.Client();

  static const Map<String, String> _jsonHeaders = {
    'Content-Type': 'application/json',
  };

  Future<ArqueoCaja> getArqueo({
    required String idUsuario,
    required DateTime fecha,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/admin/cobranzas/arqueo/$idUsuario/${_fechaIso(fecha)}',
    );
    final response = await _get(uri);
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw CobranzaRepositoryException('Respuesta inesperada del servidor.');
    }
    return ArqueoCaja.fromJson(decoded);
  }

  Future<ReporteCuentasCorrientes> getReporteCuentasCorrientes({
    bool soloMorosos = false,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/admin/clientes/cuentas-corrientes')
        .replace(queryParameters: {'soloMorosos': '$soloMorosos'});
    final response = await _get(uri);
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw CobranzaRepositoryException('Respuesta inesperada del servidor.');
    }
    return ReporteCuentasCorrientes.fromJson(decoded);
  }

  Future<void> cerrarArqueo({
    required String idUsuario,
    required DateTime fecha,
    required int efectivoDeclarado,
    required int chequeDeclarado,
    required int transferenciaDeclarada,
    String? observacion,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/admin/cobranzas/arqueo/$idUsuario/${_fechaIso(fecha)}/cerrar',
    );
    final obs = observacion?.trim();
    http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: _jsonHeaders,
            body: jsonEncode({
              'efectivoDeclarado': efectivoDeclarado,
              'chequeDeclarado': chequeDeclarado,
              'transferenciaDeclarada': transferenciaDeclarada,
              if (obs != null && obs.isNotEmpty) 'observacion': obs,
            }),
          )
          .timeout(const Duration(seconds: 20));
    } catch (_) {
      throw NetworkException();
    }
    _validar(response);
  }

  Future<void> reabrirArqueo({
    required String idUsuario,
    required DateTime fecha,
    required String motivo,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/admin/cobranzas/arqueo/$idUsuario/${_fechaIso(fecha)}/reabrir',
    );
    http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: _jsonHeaders,
            body: jsonEncode({'motivo': motivo.trim()}),
          )
          .timeout(const Duration(seconds: 20));
    } catch (_) {
      throw NetworkException();
    }
    _validar(response);
  }

  Future<http.Response> _get(Uri uri) async {
    http.Response response;
    try {
      response = await _client
          .get(uri, headers: _jsonHeaders)
          .timeout(const Duration(seconds: 20));
    } catch (_) {
      throw NetworkException();
    }
    _validar(response);
    return response;
  }

  void _validar(http.Response response) {
    final code = response.statusCode;
    if (code >= 200 && code < 300) return;
    if (code == 401 || code == 403) {
      throw CobranzaRepositoryException(
        _mensajeError(response.body) ?? 'No tenés permisos para la consola de cobranzas.',
        statusCode: code,
      );
    }
    throw CobranzaRepositoryException(
      _mensajeError(response.body) ?? 'Error del servidor ($code). Intentá más tarde.',
      statusCode: code,
    );
  }

  String _fechaIso(DateTime fecha) => formatDateOnly(fecha);

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
