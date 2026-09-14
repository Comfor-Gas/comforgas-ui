import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/cuadre_rodante.dart';
import 'network_exception.dart';

class StockRodanteAdminException implements Exception {
  final String message;
  StockRodanteAdminException(this.message);

  @override
  String toString() => message;
}

class NotaRodanteResumen {
  final int idNota;
  final String? numeroNota;
  final String? idUsuario;
  final String? dominioVehiculo;
  final String estado;

  const NotaRodanteResumen({
    required this.idNota,
    this.numeroNota,
    this.idUsuario,
    this.dominioVehiculo,
    this.estado = '',
  });

  bool get cerrada => estado.toUpperCase() == 'ENTRADA_COMPLETA';

  factory NotaRodanteResumen.fromJson(Map<String, dynamic> json) {
    return NotaRodanteResumen(
      idNota: int.tryParse('${json['idNota'] ?? 0}') ?? 0,
      numeroNota: json['numeroNota']?.toString(),
      idUsuario: json['idUsuario']?.toString(),
      dominioVehiculo: json['dominioVehiculo']?.toString(),
      estado: (json['estado'] ?? '').toString(),
    );
  }
}

class StockRodanteAdminRepository {
  final http.Client _client;

  StockRodanteAdminRepository([http.Client? client]) : _client = client ?? http.Client();

  static const Map<String, String> _jsonHeaders = {'Content-Type': 'application/json'};

  static String _fechaIso(DateTime fecha) {
    return '${fecha.year.toString().padLeft(4, '0')}-'
        '${fecha.month.toString().padLeft(2, '0')}-'
        '${fecha.day.toString().padLeft(2, '0')}';
  }

  Future<NotaRodanteResumen> asignarCargaInicial({
    required String idUsuario,
    required String dominioVehiculo,
    required DateTime fecha,
    required List<Map<String, dynamic>> items,
    String? observaciones,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/admin/stock-rodante/asignar-inicial');
    final body = jsonEncode({
      'idUsuario': idUsuario,
      'dominioVehiculo': dominioVehiculo,
      'fechaRuta': _fechaIso(fecha),
      'items': items,
      'observaciones': observaciones,
    });
    final response = await _send('POST', uri, body);
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw StockRodanteAdminException('Respuesta inesperada del servidor.');
    }
    return NotaRodanteResumen.fromJson(decoded);
  }

  Future<List<NotaRodanteResumen>> notasDelDia(DateTime fecha) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/admin/stock-rodante/notas').replace(
      queryParameters: {'fecha': _fechaIso(fecha)},
    );
    final response = await _get(uri);
    if (response.body.isEmpty) return const [];
    final decoded = jsonDecode(response.body);
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(NotaRodanteResumen.fromJson)
        .toList();
  }

  Future<CuadreRodante> getCuadre(int idNota) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/admin/stock-rodante/$idNota/cuadre');
    final response = await _get(uri);
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw StockRodanteAdminException('Respuesta inesperada del servidor.');
    }
    return CuadreRodante.fromJson(decoded);
  }

  Future<Map<String, int>> asignadoLlenosPorChofer(DateTime fecha) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/admin/stock-rodante/notas').replace(
      queryParameters: {'fecha': _fechaIso(fecha)},
    );
    final response = await _get(uri);
    final mapa = <String, int>{};
    if (response.body.isEmpty) return mapa;
    final decoded = jsonDecode(response.body);
    if (decoded is! List) return mapa;
    for (final nota in decoded.whereType<Map<String, dynamic>>()) {
      final idUsuario = nota['idUsuario']?.toString();
      if (idUsuario == null || idUsuario.isEmpty) continue;
      final detalles = nota['detalles'];
      int suma = 0;
      if (detalles is List) {
        for (final d in detalles.whereType<Map<String, dynamic>>()) {
          final llenosSalida = int.tryParse('${d['llenosSalida'] ?? 0}') ?? 0;
          final recargaLlenos = int.tryParse('${d['recargaLlenos'] ?? 0}') ?? 0;
          suma += llenosSalida + recargaLlenos;
        }
      }
      mapa[idUsuario] = suma;
    }
    return mapa;
  }

  Future<int?> resolverIdNota({
    required DateTime fecha,
    String? idUsuario,
    String? dominioVehiculo,
  }) async {
    final notas = await notasDelDia(fecha);
    for (final n in notas) {
      if (idUsuario != null && idUsuario.isNotEmpty && n.idUsuario == idUsuario) {
        return n.idNota;
      }
    }
    for (final n in notas) {
      if (dominioVehiculo != null &&
          dominioVehiculo.isNotEmpty &&
          n.dominioVehiculo == dominioVehiculo) {
        return n.idNota;
      }
    }
    return null;
  }

  Future<void> registrarRecarga(
    int idNota, {
    required List<Map<String, dynamic>> items,
    String? observaciones,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/admin/stock-rodante/$idNota/recargas');
    final body = jsonEncode({'items': items, 'observaciones': observaciones});
    await _send('POST', uri, body);
  }

  Future<void> registrarEntrada(
    int idNota, {
    required List<Map<String, dynamic>> items,
    String? observaciones,
  }) async {
    final uri =
        Uri.parse('${ApiConfig.baseUrl}/api/admin/stock-rodante/$idNota/registrar-entrada');
    final body = jsonEncode({'items': items, 'observaciones': observaciones});
    await _send('PUT', uri, body);
  }

  Future<http.Response> _get(Uri uri) async {
    http.Response response;
    try {
      response = await _client.get(uri, headers: _jsonHeaders).timeout(const Duration(seconds: 20));
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
      final streamed = await _client.send(request).timeout(const Duration(seconds: 20));
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
