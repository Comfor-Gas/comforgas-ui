import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/stock_rodante_chofer.dart';
import '../utils/json_parsing.dart';
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
  final StockRodanteChofer? nota;

  const EstadoRutaChofer({
    required this.habilitado,
    this.mensaje,
    this.nota,
  });

  bool get tieneNota => nota != null;

  bool get jornadaCerrada => nota?.jornadaCerrada ?? false;

  factory EstadoRutaChofer.fromJson(Map<String, dynamic> json) {
    final nota = json['nota'];
    return EstadoRutaChofer(
      habilitado: json['habilitado'] == true,
      mensaje: json['mensaje']?.toString(),
      nota: nota is Map<String, dynamic> ? StockRodanteChofer.fromJson(nota) : null,
    );
  }
}

class StockRodanteRepository {
  final http.Client _client;

  StockRodanteRepository([http.Client? client]) : _client = client ?? http.Client();

  static const _headers = {'Content-Type': 'application/json'};

  Uri _uri(String path, DateTime? fecha) => Uri.parse('${ApiConfig.baseUrl}$path')
      .replace(queryParameters: {'fecha': formatDateOnly(fecha ?? DateTime.now())});

  Future<http.Response> _get(Uri uri) async {
    try {
      return await _client.get(uri, headers: _headers).timeout(const Duration(seconds: 20));
    } catch (_) {
      throw NetworkException();
    }
  }

  Future<EstadoRutaChofer?> estadoRuta({DateTime? fecha}) async {
    final response = await _get(_uri(ApiConfig.repartidorRutaEstadoPath, fecha));
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
    final response = await _get(_uri(ApiConfig.repartidorMiCargaPath, fecha));

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
