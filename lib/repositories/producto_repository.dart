import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/producto_catalogo.dart';
import 'network_exception.dart';

class ProductoRepositoryException implements Exception {
  final String message;
  final int? statusCode;

  ProductoRepositoryException(this.message, {this.statusCode});

  bool get endpointNoDisponible =>
      statusCode == 404 || statusCode == 405 || statusCode == 501;

  @override
  String toString() => message;
}

class ProductoRepository {
  final http.Client _client;

  ProductoRepository([http.Client? client]) : _client = client ?? http.Client();

  Future<List<ProductoCatalogo>> listar({int? idAgendaItem, int? clienteIdExt}) async {
    final params = <String, String>{};
    if (idAgendaItem != null) params['idAgendaItem'] = '$idAgendaItem';
    if (clienteIdExt != null) params['clienteIdExt'] = '$clienteIdExt';

    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.productosPath}')
        .replace(queryParameters: params.isEmpty ? null : params);

    http.Response response;
    try {
      response = await _client
          .get(uri, headers: const {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 20));
    } catch (_) {
      throw NetworkException();
    }

    final code = response.statusCode;
    if (code >= 200 && code < 300) {
      final body = response.body;
      if (body.isEmpty) return const [];
      final decoded = jsonDecode(body);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(ProductoCatalogo.fromJson)
          .where((p) => p.activo)
          .toList();
    }

    throw ProductoRepositoryException(
      'No se pudo cargar el catálogo de productos ($code).',
      statusCode: code,
    );
  }
}
