import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/comprobante_visita.dart';
import 'network_exception.dart';

class ComprobanteRepositoryException implements Exception {
  final String message;
  ComprobanteRepositoryException(this.message);

  @override
  String toString() => message;
}

class ComprobanteRepository {
  final http.Client _client;

  ComprobanteRepository([http.Client? client]) : _client = client ?? http.Client();

  Future<ComprobanteVisita> obtener(int idVisita) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.visitasPath}/$idVisita/resumen');

    http.Response response;
    try {
      response = await _client
          .get(uri, headers: const {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 20));
    } catch (_) {
      throw NetworkException();
    }

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw ComprobanteRepositoryException('Respuesta inesperada del servidor.');
      }
      return ComprobanteVisita.fromResumenJson(decoded);
    }

    if (response.statusCode == 404) {
      throw ComprobanteRepositoryException('No se encontró la visita en el servidor.');
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw ComprobanteRepositoryException('Tu sesión no tiene permisos para ver este comprobante.');
    }

    throw ComprobanteRepositoryException(
      'Error del servidor (${response.statusCode}) al obtener el comprobante.',
    );
  }
}
