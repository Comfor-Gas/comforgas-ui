import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/venta_monitoreo.dart';
import '../utils/json_parsing.dart';
import 'network_exception.dart';

class VentaMonitoreoRepositoryException implements Exception {
  final String message;
  final int? statusCode;

  VentaMonitoreoRepositoryException(this.message, {this.statusCode});

  bool get endpointNoDisponible => statusCode == 404 || statusCode == 501;

  @override
  String toString() => message;
}

class VentaMonitoreoRepository {
  final http.Client _client;

  VentaMonitoreoRepository([http.Client? client])
      : _client = client ?? http.Client();

  Future<VentasMonitoreoDia> obtenerMonitoreo({required DateTime fecha}) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.adminVentasMonitoreoPath}',
    ).replace(queryParameters: {'fecha': formatDateOnly(fecha)});

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
      if (decoded is Map<String, dynamic>) {
        return VentasMonitoreoDia.fromJson(decoded);
      }
      throw VentaMonitoreoRepositoryException(
        'La respuesta del servidor no tiene el formato esperado.',
        statusCode: response.statusCode,
      );
    }

    if (response.statusCode == 401) {
      throw VentaMonitoreoRepositoryException(
        _extractErrorMessage(response.body) ?? 'Tu sesión expiró.',
        statusCode: 401,
      );
    }

    if (response.statusCode == 403) {
      throw VentaMonitoreoRepositoryException(
        _extractErrorMessage(response.body) ??
            'No tenés permisos para ver el monitoreo de ventas.',
        statusCode: 403,
      );
    }

    throw VentaMonitoreoRepositoryException(
      _extractErrorMessage(response.body) ??
          'Error del servidor (${response.statusCode}). Intentá más tarde.',
      statusCode: response.statusCode,
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
