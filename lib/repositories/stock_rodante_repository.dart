import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/stock_rodante_chofer.dart';
import 'network_exception.dart';

class StockRodanteRepositoryException implements Exception {
  final String message;
  StockRodanteRepositoryException(this.message);

  @override
  String toString() => message;
}

class EstadoRutaChofer {
  final bool habilitado;
  final String? mensaje;
  final bool tieneNota;

  const EstadoRutaChofer({
    required this.habilitado,
    this.mensaje,
    this.tieneNota = false,
  });

  factory EstadoRutaChofer.fromJson(Map<String, dynamic> json) {
    return EstadoRutaChofer(
      habilitado: json['habilitado'] == true,
      mensaje: json['mensaje']?.toString(),
      tieneNota: json['nota'] != null,
    );
  }
}

class StockRodanteRepository {
  final http.Client _client;

  StockRodanteRepository([http.Client? client]) : _client = client ?? http.Client();

  Future<EstadoRutaChofer?> estadoRuta({DateTime? fecha}) async {
    final dia = fecha ?? DateTime.now();
    final fechaIso = '${dia.year.toString().padLeft(4, '0')}-'
        '${dia.month.toString().padLeft(2, '0')}-'
        '${dia.day.toString().padLeft(2, '0')}';
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/repartidor/ruta/estado',
    ).replace(queryParameters: {'fecha': fechaIso});

    http.Response response;
    try {
      response = await _client
          .get(uri, headers: const {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 20));
    } catch (_) {
      throw NetworkException();
    }

    if (response.statusCode == 200 && response.body.isNotEmpty) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return EstadoRutaChofer.fromJson(decoded);
      }
    }
    return null;
  }

  Future<StockRodanteChofer?> getMiStock({
    required String idUsuario,
    DateTime? fecha,
  }) async {
    final dia = fecha ?? DateTime.now();
    final fechaIso = '${dia.year.toString().padLeft(4, '0')}-'
        '${dia.month.toString().padLeft(2, '0')}-'
        '${dia.day.toString().padLeft(2, '0')}';
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/stock-rodante/chofer/$idUsuario/$fechaIso',
    );

    http.Response response;
    try {
      response = await _client
          .get(uri, headers: const {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 20));
    } catch (_) {
      throw NetworkException();
    }

    if (response.statusCode == 200) {
      if (response.body.isEmpty) return null;
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw StockRodanteRepositoryException('Respuesta inesperada del servidor.');
      }
      return StockRodanteChofer.fromJson(decoded);
    }

    if (response.statusCode == 404) {
      return null;
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw StockRodanteRepositoryException(
        'Tu sesión no tiene permisos para ver el stock del camión.',
      );
    }

    throw StockRodanteRepositoryException(
      'Error del servidor (${response.statusCode}) al consultar tu stock.',
    );
  }
}
