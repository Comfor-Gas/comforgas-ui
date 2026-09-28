import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'network_exception.dart';

class MetasChoferRepositoryException implements Exception {
  final String message;
  MetasChoferRepositoryException(this.message);

  @override
  String toString() => message;
}

class MetasChoferRepository {
  final http.Client _client;

  MetasChoferRepository(this._client);

  Future<Map<String, dynamic>> obtenerMetasDia(String idUsuario) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.choferMetasDiaPath(idUsuario)}');
    http.Response response;
    try {
      response = await _client.get(uri).timeout(const Duration(seconds: 15));
    } catch (_) {
      throw NetworkException();
    }
    if (response.statusCode == 200) {
      try {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is Map<String, dynamic>) return decoded;
      } catch (_) {}
      throw MetasChoferRepositoryException('La respuesta de métricas no tiene el formato esperado.');
    }
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw MetasChoferRepositoryException('Tu sesión no tiene permisos para ver tus métricas.');
    }
    throw MetasChoferRepositoryException(
      'No se pudieron cargar tus métricas (${response.statusCode}).',
    );
  }
}
