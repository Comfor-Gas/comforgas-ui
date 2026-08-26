import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/stock_camion.dart';
import 'network_exception.dart';

class StockRepositoryException implements Exception {
  final String message;
  StockRepositoryException(this.message);

  @override
  String toString() => message;
}

class StockRepository {
  final http.Client _client;

  StockRepository([http.Client? client]) : _client = client ?? http.Client();

  Future<StockCamion> getStockMiCamion() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.stockMiCamionPath}');

    http.Response response;
    try {
      response = await _client
          .get(uri, headers: const {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 20));
    } catch (_) {
      throw NetworkException();
    }

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw StockRepositoryException('Respuesta inesperada del servidor.');
      }
      return StockCamion.fromJson(decoded);
    }

    if (response.statusCode == 404) {
      throw StockRepositoryException(
        _extractErrorMessage(response.body) ??
            'No tenés un camión activo asignado para consultar el stock.',
      );
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw StockRepositoryException(
        _extractErrorMessage(response.body) ??
            'Tu sesión no tiene permisos para consultar el stock del camión.',
      );
    }

    throw StockRepositoryException(
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
        if (message is String && message.isNotEmpty) return message;
      }
    } catch (_) {}
    return null;
  }
}
