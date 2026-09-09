import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../utils/json_parsing.dart';

class PosicionChoferData {
  final String idChofer;
  final double latitud;
  final double longitud;

  const PosicionChoferData({
    required this.idChofer,
    required this.latitud,
    required this.longitud,
  });
}

class UbicacionRepository {
  final http.Client _client;

  UbicacionRepository(this._client);

  static const Map<String, String> _jsonHeaders = {
    'Content-Type': 'application/json',
  };

  Future<void> enviar({
    required double latitud,
    required double longitud,
    double? precisionMetros,
    DateTime? timestamp,
    int? idVisita,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.visitaUbicacionPath}');
    try {
      await _client
          .post(
            uri,
            headers: _jsonHeaders,
            body: jsonEncode({
              'latitud': latitud,
              'longitud': longitud,
              if (precisionMetros != null && precisionMetros.isFinite)
                'precisionMetros': precisionMetros,
              'timestamp': (timestamp ?? DateTime.now()).toUtc().toIso8601String(),
              if (idVisita != null) 'idVisita': idVisita,
            }),
          )
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      return;
    }
  }

  Future<List<PosicionChoferData>> listarActivas() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.adminUbicacionesPath}');
    http.Response response;
    try {
      response = await _client
          .get(uri, headers: _jsonHeaders)
          .timeout(const Duration(seconds: 15));
    } catch (_) {
      return const [];
    }

    if (response.statusCode != 200 || response.body.isEmpty) return const [];

    final decoded = jsonDecode(response.body);
    if (decoded is! List) return const [];

    final resultado = <PosicionChoferData>[];
    for (final item in decoded.whereType<Map<String, dynamic>>()) {
      final idChofer = (item['idChofer'] ?? '').toString();
      final lat = parseDouble(item['latitud']);
      final lon = parseDouble(item['longitud']);
      if (idChofer.isEmpty || lat == null || lon == null) continue;
      resultado.add(PosicionChoferData(idChofer: idChofer, latitud: lat, longitud: lon));
    }
    return resultado;
  }
}
