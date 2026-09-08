import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

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
}
