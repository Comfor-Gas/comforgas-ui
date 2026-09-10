import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/deposito_camion.dart';
import '../models/estado_garrafa.dart';
import '../models/movimiento_stock.dart';
import '../models/producto_catalogo.dart';
import '../models/stock_camion.dart';
import 'network_exception.dart';

class FlotaRepositoryException implements Exception {
  final String message;
  final int? statusCode;

  FlotaRepositoryException(this.message, {this.statusCode});

  bool get endpointNoDisponible => statusCode == 404 || statusCode == 501;

  @override
  String toString() => message;
}

class ResumenFlota {
  final List<DepositoCamion> camiones;
  final int vaciasRetornadasHoy;

  const ResumenFlota({required this.camiones, this.vaciasRetornadasHoy = 0});
}

class FlotaRepository {
  final http.Client _client;

  FlotaRepository([http.Client? client]) : _client = client ?? http.Client();

  static const Map<String, String> _jsonHeaders = {
    'Content-Type': 'application/json',
  };

  Future<ResumenFlota> getResumenFlota({DateTime? fecha}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/stock/flota/resumen').replace(
      queryParameters: fecha != null ? {'fecha': _fechaIso(fecha)} : null,
    );
    final response = await _get(uri);
    final decoded = jsonDecode(response.body);
    if (decoded is! List) return const ResumenFlota(camiones: []);
    final filas = decoded.whereType<Map<String, dynamic>>().toList();
    final camiones = filas.map(DepositoCamion.fromResumenJson).toList();
    final vacias = filas.isNotEmpty
        ? (int.tryParse('${filas.first['vaciasRetornadasHoy'] ?? 0}') ?? 0)
        : 0;
    return ResumenFlota(camiones: camiones, vaciasRetornadasHoy: vacias);
  }

  Future<List<DepositoCamion>> listarCamiones() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/stock/depositos').replace(
      queryParameters: {'tipo': 'CAMION', 'activo': 'true'},
    );
    final response = await _get(uri);
    return _parseList(response.body, DepositoCamion.fromJson);
  }

  String _fechaIso(DateTime fecha) {
    final y = fecha.year.toString().padLeft(4, '0');
    final m = fecha.month.toString().padLeft(2, '0');
    final d = fecha.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<List<DepositoCamion>> listarDepositosCentrales() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/stock/depositos').replace(
      queryParameters: {'tipo': 'DEPOSITO_CENTRAL', 'activo': 'true'},
    );
    final response = await _get(uri);
    return _parseList(response.body, DepositoCamion.fromJson);
  }

  Future<StockCamion> getStockCamion(int idCamion) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/stock/camion/$idCamion');
    final response = await _get(uri);
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw FlotaRepositoryException('Respuesta inesperada del servidor.');
    }
    return StockCamion.fromJson(decoded);
  }

  Future<List<ProductoCatalogo>> listarProductos() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/productos');
    final response = await _get(uri);
    return _parseList(response.body, ProductoCatalogo.fromJson);
  }

  Future<List<EstadoGarrafa>> listarEstadosGarrafa() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/stock/estados-garrafa');
    final response = await _get(uri);
    return _parseList(response.body, EstadoGarrafa.fromJson);
  }

  Future<List<MovimientoStock>> historialRecargas(int idCamion) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/stock/movimientos').replace(
      queryParameters: {
        'depositoId': '$idCamion',
        'tipoMovimiento': 'CARGA_CAMION',
        'size': '100',
      },
    );
    final response = await _get(uri);
    final decoded = jsonDecode(response.body);
    final contenido = decoded is Map<String, dynamic> ? decoded['content'] : decoded;
    if (contenido is! List) return const [];
    return contenido
        .whereType<Map<String, dynamic>>()
        .map(MovimientoStock.fromJson)
        .toList();
  }

  Future<DepositoCamion> asignarChofer(
    DepositoCamion camion, {
    required String repartidorId,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/stock/depositos/${camion.id}');
    final body = jsonEncode({
      'nombre': camion.nombre,
      'tipo': 'CAMION',
      'descripcion': camion.descripcion,
      'vehiculoPatente': camion.patente,
      'numeroMovil': camion.numeroMovil,
      'repartidorId': repartidorId,
    });
    final response = await _send('PUT', uri, body);
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw FlotaRepositoryException('Respuesta inesperada del servidor.');
    }
    return DepositoCamion.fromJson(decoded);
  }

  Future<List<MovimientoStock>> recargarCamion(
    int idCamion, {
    int? depositoCentralId,
    required List<Map<String, dynamic>> items,
    String? observaciones,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/stock/camiones/$idCamion/carga');
    final body = jsonEncode({
      'depositoCentralId': depositoCentralId,
      'items': items,
      'observaciones': observaciones,
    });
    final response = await _send('POST', uri, body);
    final decoded = jsonDecode(response.body);
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(MovimientoStock.fromJson)
        .toList();
  }

  Future<List<MovimientoStock>> descargarCamion(
    int idCamion, {
    required int depositoCentralId,
    required List<Map<String, dynamic>> items,
    String? observaciones,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/stock/camiones/$idCamion/descarga');
    final body = jsonEncode({
      'depositoCentralId': depositoCentralId,
      'items': items,
      'observaciones': observaciones,
    });
    final response = await _send('POST', uri, body);
    final decoded = jsonDecode(response.body);
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(MovimientoStock.fromJson)
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

  Future<http.Response> _send(String metodo, Uri uri, String body) async {
    http.Response response;
    try {
      final request = http.Request(metodo, uri)
        ..headers.addAll(_jsonHeaders)
        ..body = body;
      final streamed = await _client.send(request).timeout(
            const Duration(seconds: 20),
          );
      response = await http.Response.fromStream(streamed);
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

  List<T> _parseList<T>(String body, T Function(Map<String, dynamic>) fromJson) {
    if (body.isEmpty) return const [];
    final decoded = jsonDecode(body);
    if (decoded is! List) return const [];
    return decoded.whereType<Map<String, dynamic>>().map(fromJson).toList();
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
