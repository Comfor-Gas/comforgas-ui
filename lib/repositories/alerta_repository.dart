import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/alerta_model.dart';
import '../utils/json_parsing.dart';

class AlertaRepositoryException implements Exception {
  final String message;
  AlertaRepositoryException(this.message);

  @override
  String toString() => message;
}

class AlertaRepository {
  final http.Client _client;

  AlertaRepository([http.Client? client]) : _client = client ?? http.Client();

  Future<List<AlertaModel>> listarAbiertas({DateTime? fecha}) async {
    final params = <String, String>{
      'estado': 'ABIERTA',
      'size': '200',
      if (fecha != null) 'fecha': formatDateOnly(fecha),
    };
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.adminAlertasPath}')
        .replace(queryParameters: params);

    http.Response response;
    try {
      response = await _client
          .get(uri, headers: const {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 20));
    } catch (_) {
      throw AlertaRepositoryException(
        'No se pudo conectar con el servidor. Revisa tu conexión.',
      );
    }

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic> || decoded['content'] is! List) {
        return const [];
      }
      return (decoded['content'] as List)
          .whereType<Map<String, dynamic>>()
          .map(AlertaModel.fromJson)
          .toList();
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw AlertaRepositoryException(
        'No tenés permisos para ver las alertas de monitoreo.',
      );
    }

    throw AlertaRepositoryException(
      'Error del servidor (${response.statusCode}). Intenta más tarde.',
    );
  }
}
