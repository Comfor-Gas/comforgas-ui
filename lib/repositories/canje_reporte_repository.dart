import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/canje_reporte.dart';
import '../utils/json_parsing.dart';
import 'network_exception.dart';

class CanjeReporteRepositoryException implements Exception {
  final String message;
  CanjeReporteRepositoryException(this.message);

  @override
  String toString() => message;
}

class CanjeReporteRepository {
  final http.Client _client;

  CanjeReporteRepository(this._client);

  static const Map<String, String> _jsonHeaders = {
    'Content-Type': 'application/json',
  };

  Future<List<CanjeReporte>> buscarReporte({
    DateTime? desde,
    DateTime? hasta,
    String? descripcionDanio,
    String? choferId,
    int? movil,
    int page = 0,
    int size = 300,
  }) async {
    final params = <String, String>{
      'page': '$page',
      'size': '$size',
      if (desde != null) 'desde': formatDateOnly(desde),
      if (hasta != null) 'hasta': formatDateOnly(hasta),
      if (descripcionDanio != null && descripcionDanio.trim().isNotEmpty)
        'descripcionDanio': descripcionDanio.trim(),
      if (choferId != null && choferId.isNotEmpty) 'choferId': choferId,
      if (movil != null) 'movil': '$movil',
    };

    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.adminCanjesReportePath}')
        .replace(queryParameters: params);

    http.Response response;
    try {
      response = await _client
          .get(uri, headers: _jsonHeaders)
          .timeout(const Duration(seconds: 30));
    } catch (_) {
      throw NetworkException();
    }

    if (response.statusCode == 200) {
      if (response.body.isEmpty) return const [];
      final decoded = jsonDecode(response.body);
      final List<dynamic> lista;
      if (decoded is Map<String, dynamic>) {
        lista = decoded['content'] as List? ?? const [];
      } else if (decoded is List) {
        lista = decoded;
      } else {
        lista = const [];
      }
      return lista
          .whereType<Map<String, dynamic>>()
          .map(CanjeReporte.fromJson)
          .toList();
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw CanjeReporteRepositoryException(
        _mensajeError(response.body) ??
            'Tu sesión no tiene permisos para ver el reporte de devoluciones.',
      );
    }

    throw CanjeReporteRepositoryException(
      _mensajeError(response.body) ??
          'Error del servidor (${response.statusCode}) al consultar el reporte.',
    );
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
