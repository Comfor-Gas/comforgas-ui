import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/cuadre_rodante.dart';
import '../models/nota_stock_movimiento.dart';
import '../models/stock_rodante_chofer.dart';
import '../utils/json_parsing.dart';
import 'network_exception.dart';

class StockRodanteAdminException implements Exception {
  final String message;
  StockRodanteAdminException(this.message);

  @override
  String toString() => message;
}

class StockRodanteAdminRepository {
  final http.Client _client;

  StockRodanteAdminRepository([http.Client? client]) : _client = client ?? http.Client();

  static const Map<String, String> _jsonHeaders = {'Content-Type': 'application/json'};

  Uri _uri(String sufijo, [Map<String, String>? query]) =>
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.adminStockRodantePath}$sufijo')
          .replace(queryParameters: query);

  StockRodanteChofer _nota(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw StockRodanteAdminException('Respuesta inesperada del servidor.');
    }
    return StockRodanteChofer.fromJson(decoded);
  }

  Future<StockRodanteChofer> asignarCargaInicial({
    required String idUsuario,
    required String dominioVehiculo,
    required DateTime fecha,
    required List<Map<String, dynamic>> items,
    String? observaciones,
  }) async {
    final body = jsonEncode({
      'idUsuario': idUsuario,
      'dominioVehiculo': dominioVehiculo,
      'fechaRuta': formatDateOnly(fecha),
      'items': items,
      'observaciones': observaciones,
    });
    final response = await _send('POST', _uri('/asignar-inicial'), body);
    return _nota(response.body);
  }

  Future<List<StockRodanteChofer>> notasDelDia(DateTime fecha) async {
    final response = await _get(_uri('/notas', {'fecha': formatDateOnly(fecha)}));
    if (response.body.isEmpty) return const [];
    final decoded = jsonDecode(response.body);
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(StockRodanteChofer.fromJson)
        .toList();
  }

  Future<StockRodanteChofer> nota(int idNota) async {
    final response = await _get(_uri('/notas/$idNota'));
    return _nota(response.body);
  }

  Future<List<NotaStockMovimiento>> movimientos(int idNota) async {
    final response = await _get(_uri('/notas/$idNota/movimientos'));
    if (response.body.isEmpty) return const [];
    final decoded = jsonDecode(response.body);
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(NotaStockMovimiento.fromJson)
        .toList();
  }

  Future<CuadreRodante> getCuadre(int idNota) async {
    final response = await _get(_uri('/notas/$idNota/informe'));
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw StockRodanteAdminException('Respuesta inesperada del servidor.');
    }
    return CuadreRodante.fromInforme(decoded);
  }

  Future<void> registrarRecarga(
    int idNota, {
    required List<Map<String, dynamic>> items,
    String? observaciones,
  }) async {
    final body = jsonEncode({'items': items, 'observaciones': observaciones});
    await _send('POST', _uri('/notas/$idNota/recarga'), body);
  }

  Future<void> registrarEntrada(
    int idNota, {
    required List<Map<String, dynamic>> items,
    String? observaciones,
  }) async {
    final body = jsonEncode({'items': items, 'observaciones': observaciones});
    await _send('POST', _uri('/notas/$idNota/cierre'), body);
  }

  Future<http.Response> _get(Uri uri) async {
    http.Response response;
    try {
      response = await _client.get(uri, headers: _jsonHeaders).timeout(const Duration(seconds: 12));
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
      final streamed = await _client.send(request).timeout(const Duration(seconds: 12));
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
    throw StockRodanteAdminException(
      _extraerMensaje(response.body) ?? 'Error del servidor ($code). Intentá más tarde.',
    );
  }

  String? _extraerMensaje(String body) {
    if (body.isEmpty) return null;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final error = decoded['error'];
        if (error is Map<String, dynamic>) {
          final message = error['message'];
          if (message is String && message.isNotEmpty && message.length <= 300) return message;
        }
        final message = decoded['message'];
        if (message is String && message.isNotEmpty && message.length <= 300) return message;
      }
    } catch (_) {}
    return null;
  }
}
