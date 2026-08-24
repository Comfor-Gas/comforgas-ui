import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/venta_draft.dart';
import 'network_exception.dart';

class VentaRepositoryException implements Exception {
  final String message;
  VentaRepositoryException(this.message);

  @override
  String toString() => message;
}

class VentaRepository {
  final http.Client _client;

  VentaRepository([http.Client? client]) : _client = client ?? http.Client();

  Future<void> registrarVenta({
    required int idVisita,
    required VentaDraft venta,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.ventasPath}');

    http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'idVisita': idVisita,
              'items': venta.lineas.map((l) => l.toRequestJson()).toList(),
            }),
          )
          .timeout(const Duration(seconds: 20));
    } catch (_) {
      throw NetworkException();
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      return;
    }

    if (response.statusCode == 400 || response.statusCode == 409) {
      throw VentaRepositoryException(
        _extractErrorMessage(response.body) ??
            'La venta tiene datos inconsistentes y no se pudo registrar.',
      );
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw VentaRepositoryException(
        _extractErrorMessage(response.body) ??
            'Tu sesión no tiene permisos para registrar ventas.',
      );
    }

    if (response.statusCode == 404) {
      throw VentaRepositoryException(
        _extractErrorMessage(response.body) ??
            'La visita asociada a la venta no existe.',
      );
    }

    throw VentaRepositoryException(
      _extractErrorMessage(response.body) ??
          'Error del servidor (${response.statusCode}). Intenta más tarde.',
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
        if (message is String && message.isNotEmpty) {
          return _sanitizeMessage(message);
        }
      }
    } catch (_) {}
    return null;
  }

  String? _sanitizeMessage(String raw) {
    final looksLikeHtmlOrJunk = raw.contains('<!DOCTYPE') ||
        raw.contains('<html') ||
        raw.contains('font-face') ||
        raw.contains('base64,') ||
        raw.length > 300;

    if (!looksLikeHtmlOrJunk) return raw;

    return 'Ocurrió un error inesperado en el servidor. Intentá de nuevo '
        'más tarde; si el problema persiste, contactá al administrador.';
  }
}
