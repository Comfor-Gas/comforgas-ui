import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/venta_draft.dart';
import '../models/venta_en_visita.dart';
import '../utils/json_parsing.dart';
import 'network_exception.dart';

class VentaRepositoryException implements Exception {
  final String message;
  final String? codigo;
  final int? statusCode;

  VentaRepositoryException(this.message, {this.codigo, this.statusCode});

  bool get esStockInsuficiente {
    if (codigo == 'STOCK_INSUFICIENTE') return true;
    final low = message.toLowerCase();
    return low.contains('stock insuficiente') || low.contains('stock_insuficiente');
  }

  bool get esSinNotaAsignada =>
      message.toLowerCase().contains('nota de control de stock asignada');

  bool get esJornadaCerrada {
    final low = message.toLowerCase();
    return low.contains('entrada_completa') ||
        low.contains('jornada ha finalizado') ||
        (low.contains('jornada') && (low.contains('cerrad') || low.contains('congelad')));
  }

  @override
  String toString() => message;
}

class _ErrorBackend {
  final String? codigo;
  final String? mensaje;
  const _ErrorBackend(this.codigo, this.mensaje);
}

class VentaRepository {
  final http.Client _client;

  VentaRepository([http.Client? client]) : _client = client ?? http.Client();

  Future<int?> registrarVenta({
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
            body: jsonEncode(venta.toRequestJson(idVisita)),
          )
          .timeout(const Duration(seconds: 20));
    } catch (_) {
      throw NetworkException();
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) return parseInt(decoded['idVenta']);
      } catch (_) {}
      return null;
    }

    final error = _extraerError(response.body);
    String mensajePorDefecto;
    switch (response.statusCode) {
      case 400:
      case 409:
        mensajePorDefecto = 'La venta tiene datos inconsistentes y no se pudo registrar.';
        break;
      case 401:
      case 403:
        mensajePorDefecto = 'Tu sesión no tiene permisos para registrar ventas.';
        break;
      case 404:
        mensajePorDefecto = 'La visita asociada a la venta no existe.';
        break;
      default:
        mensajePorDefecto = 'Error del servidor (${response.statusCode}). Intenta más tarde.';
    }
    throw VentaRepositoryException(
      error.mensaje ?? mensajePorDefecto,
      codigo: error.codigo,
      statusCode: response.statusCode,
    );
  }

  Future<List<VentaEnVisita>> getVentasDeVisita(int idVisita) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.visitasPath}/$idVisita/resumen');

    http.Response response;
    try {
      response = await _client.get(uri).timeout(const Duration(seconds: 20));
    } catch (_) {
      throw NetworkException();
    }

    if (response.statusCode == 200) {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          final bloque = decoded['ventas'];
          final lista = bloque is Map<String, dynamic> ? bloque['ventas'] : bloque;
          if (lista is List) {
            return lista
                .whereType<Map<String, dynamic>>()
                .where((v) => (v['estadoVenta'] ?? '').toString().toUpperCase() != 'CANCELADO')
                .map(VentaEnVisita.fromResponseJson)
                .toList();
          }
        }
      } catch (_) {}
      return const [];
    }

    if (response.statusCode == 404) {
      return const [];
    }

    final error = _extraerError(response.body);
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw VentaRepositoryException(
        error.mensaje ?? 'Tu sesión no tiene permisos para consultar las ventas.',
        codigo: error.codigo,
        statusCode: response.statusCode,
      );
    }

    throw VentaRepositoryException(
      error.mensaje ?? 'Error del servidor (${response.statusCode}). Intenta más tarde.',
      codigo: error.codigo,
      statusCode: response.statusCode,
    );
  }

  _ErrorBackend _extraerError(String body) {
    if (body.isEmpty) return const _ErrorBackend(null, null);
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic> && decoded['error'] is Map<String, dynamic>) {
        final error = decoded['error'] as Map<String, dynamic>;
        final codigo = error['code']?.toString();
        final message = error['message'];
        return _ErrorBackend(
          codigo,
          message is String && message.isNotEmpty ? _sanitizeMessage(message) : null,
        );
      }
    } catch (_) {}
    return const _ErrorBackend(null, null);
  }

  String _sanitizeMessage(String raw) {
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
