import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/deposito_camion.dart';
import '../utils/json_parsing.dart';
import 'network_exception.dart';

class FlotaRepositoryException implements Exception {
  final String message;
  final int? statusCode;

  FlotaRepositoryException(this.message, {this.statusCode});

  bool get endpointNoDisponible => statusCode == 404 || statusCode == 501;

  @override
  String toString() => message;
}

class FlotaRepository {
  final http.Client _client;

  FlotaRepository([http.Client? client]) : _client = client ?? http.Client();

  static const Map<String, String> _jsonHeaders = {
    'Content-Type': 'application/json',
  };

  Future<List<DepositoCamion>> getResumenFlota({DateTime? fecha}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.adminFlotaCamionesPath}').replace(
      queryParameters: fecha != null ? {'fecha': formatDateOnly(fecha)} : null,
    );
    final response = await _get(uri);
    if (response.body.isEmpty) return const [];
    final decoded = jsonDecode(response.body);
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(DepositoCamion.fromFlotaJson)
        .toList();
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
      throw FlotaRepositoryException(
        _extractErrorMessage(response.body) ??
            'No tenés permisos para gestionar la flota.',
        statusCode: code,
      );
    }

    throw FlotaRepositoryException(
      _extractErrorMessage(response.body) ??
          'Error del servidor ($code). Intentá más tarde.',
      statusCode: code,
    );
  }

  String? _extractErrorMessage(String body) {
    if (body.isEmpty) return null;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic> &&
          decoded['error'] is Map<String, dynamic>) {
        final error = decoded['error'] as Map<String, dynamic>;
        final message = error['message'];
        if (message is String && message.isNotEmpty && message.length <= 300) {
          return message;
        }
      }
    } catch (_) {}
    return null;
  }
}
