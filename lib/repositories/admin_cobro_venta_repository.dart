import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'network_exception.dart';

class AdminCobroVentaException implements Exception {
  final String message;
  final bool endpointNoDisponible;

  AdminCobroVentaException(this.message, {this.endpointNoDisponible = false});

  @override
  String toString() => message;
}

class AdminCobroVentaRepository {
  final http.Client _client;

  AdminCobroVentaRepository([http.Client? client]) : _client = client ?? http.Client();

  Future<void> registrarCobro({
    required int idVenta,
    required String metodoPago,
    required int monto,
    String? observacion,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.adminVentasPath}/$idVenta/cobros',
    );

    http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'metodoPago': metodoPago,
              'montoCobrado': monto,
              if (observacion != null && observacion.trim().isNotEmpty)
                'observacion': observacion.trim(),
            }),
          )
          .timeout(const Duration(seconds: 20));
    } catch (_) {
      throw NetworkException();
    }

    if (response.statusCode == 200 ||
        response.statusCode == 201 ||
        response.statusCode == 204) {
      return;
    }

    if (response.statusCode == 404 ||
        response.statusCode == 405 ||
        response.statusCode == 501) {
      throw AdminCobroVentaException(
        'El endpoint de cobro para administración todavía no está disponible en el backend.',
        endpointNoDisponible: true,
      );
    }

    if (response.statusCode == 400 || response.statusCode == 409) {
      throw AdminCobroVentaException(
        _extractErrorMessage(response.body) ??
            'No se pudo registrar el cobro (datos inválidos o venta ya cobrada).',
      );
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw AdminCobroVentaException(
        _extractErrorMessage(response.body) ??
            'Tu sesión no tiene permisos para registrar cobros.',
      );
    }

    if (response.statusCode == 422) {
      throw AdminCobroVentaException(
        _extractErrorMessage(response.body) ??
            'No se pudo registrar el cobro: el cliente no tiene crédito disponible en su cuenta corriente.',
      );
    }

    throw AdminCobroVentaException(
      _extractErrorMessage(response.body) ??
          'Error del servidor (${response.statusCode}) al registrar el cobro.',
    );
  }

  String? _extractErrorMessage(String body) {
    if (body.isEmpty) return null;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final error = decoded['error'];
        if (error is Map<String, dynamic>) {
          final message = error['message'];
          if (message is String && message.isNotEmpty && message.length <= 300) {
            return message;
          }
        }
        final message = decoded['message'];
        if (message is String && message.isNotEmpty && message.length <= 300) {
          return message;
        }
      }
    } catch (_) {}
    return null;
  }
}
