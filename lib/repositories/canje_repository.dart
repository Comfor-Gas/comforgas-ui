import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../data/mock_canje_data.dart';
import '../models/canje_garrafa.dart';
import 'network_exception.dart';

class CanjeRepositoryException implements Exception {
  final String message;
  CanjeRepositoryException(this.message);

  @override
  String toString() => message;
}

class CanjeRepository {
  final http.Client _client;

  CanjeRepository(this._client);

  static const Map<String, String> _jsonHeaders = {
    'Content-Type': 'application/json',
  };

  Future<CanjeGarrafa> registrarCanje(int idVisita, CanjeGarrafaDraft draft) async {
    if (kCanjeMock) {
      await Future.delayed(const Duration(milliseconds: 400));
      return mockCanjeDesdeDraft(draft);
    }

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.visitasPath}/$idVisita${ApiConfig.visitaCanjesSuffix}',
    );

    http.Response response;
    try {
      response = await _client
          .post(uri, headers: _jsonHeaders, body: jsonEncode(draft.toRequestJson()))
          .timeout(const Duration(seconds: 20));
    } catch (_) {
      throw NetworkException();
    }

    final code = response.statusCode;
    if (code == 200 || code == 201) {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw CanjeRepositoryException('Respuesta inesperada del servidor.');
      }
      return CanjeGarrafa.fromJson(decoded);
    }

    if (code == 400 || code == 409) {
      throw CanjeRepositoryException(
        _mensajeError(response.body) ??
            'No se pudo registrar el canje. Verificá los datos.',
      );
    }

    if (code == 401 || code == 403) {
      throw CanjeRepositoryException(
        _mensajeError(response.body) ??
            'Tu sesión no tiene permisos para registrar canjes.',
      );
    }

    throw CanjeRepositoryException(
      _mensajeError(response.body) ??
          'Error del servidor ($code) al registrar el canje.',
    );
  }

  Future<List<CanjeGarrafa>> getCanjesDeVisita(int idVisita) async {
    if (kCanjeMock) {
      return mockCanjesDeVisita(idVisita);
    }

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.visitasPath}/$idVisita${ApiConfig.visitaCanjesSuffix}',
    );

    http.Response response;
    try {
      response = await _client
          .get(uri, headers: _jsonHeaders)
          .timeout(const Duration(seconds: 20));
    } catch (_) {
      throw NetworkException();
    }

    if (response.statusCode == 200) {
      if (response.body.isEmpty) return const [];
      final decoded = jsonDecode(response.body);
      final List<dynamic> lista =
          decoded is List ? decoded : (decoded is Map<String, dynamic> ? (decoded['content'] as List? ?? const []) : const []);
      return lista
          .whereType<Map<String, dynamic>>()
          .map(CanjeGarrafa.fromJson)
          .toList();
    }

    if (response.statusCode == 404) {
      return const [];
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw CanjeRepositoryException(
        _mensajeError(response.body) ??
            'Tu sesión no tiene permisos para ver los canjes.',
      );
    }

    throw CanjeRepositoryException(
      _mensajeError(response.body) ??
          'Error del servidor (${response.statusCode}) al consultar los canjes.',
    );
  }

  String? _mensajeError(String body) {
    if (body.isEmpty) return null;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic> &&
          decoded['error'] is Map<String, dynamic>) {
        final message = (decoded['error'] as Map<String, dynamic>)['message'];
        if (message is String && message.isNotEmpty && message.length <= 300) {
          return message;
        }
      }
    } catch (_) {}
    return null;
  }
}
