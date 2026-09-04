import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/ruta_model.dart';
import '../models/sucursal_model.dart';
import '../models/usuario_model.dart';

class CatalogoRepositoryException implements Exception {
  final String message;
  CatalogoRepositoryException(this.message);

  @override
  String toString() => message;
}


class CatalogoRepository {
  final http.Client _client;

  CatalogoRepository([http.Client? client]) : _client = client ?? http.Client();


  Future<List<UsuarioModel>> listarUsuarios({String? rol}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.usuariosPath}').replace(
      queryParameters: rol != null ? {'rol': rol} : null,
    );
    final response = await _get(uri);
    return _parseList(response.body, UsuarioModel.fromJson);
  }

  Future<List<SucursalModel>> listarClientes() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.clientesPath}');
    final response = await _get(uri);
    return _parseList(response.body, SucursalModel.fromJson);
  }

  Future<List<RutaModel>> listarRutas() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.rutasPath}');
    final response = await _get(uri);
    return _parseList(response.body, RutaModel.fromJson);
  }

  Future<http.Response> _get(Uri uri) async {
    http.Response response;
    try {
      response = await _client
          .get(uri, headers: const {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 20));
    } catch (_) {
      throw CatalogoRepositoryException(
        'No se pudo conectar con el servidor. Revisa tu conexión.',
      );
    }

    if (response.statusCode == 200) return response;

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw CatalogoRepositoryException(
        _extractErrorMessage(response.body) ??
            'No tenés permisos para ver este catálogo.',
      );
    }

    throw CatalogoRepositoryException(
      _extractErrorMessage(response.body) ??
          'Error del servidor (${response.statusCode}). Intenta más tarde.',
    );
  }

  List<T> _parseList<T>(
    String body,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (body.isEmpty) return const [];
    final decoded = jsonDecode(body);
    if (decoded is! List) return [];
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
        if (message is String && message.isNotEmpty) {
          return _sanitizeMessage(message);
        }
      }
    } catch (_) {}
    return null;
  }


  String? _sanitizeMessage(String raw) {
    final looksLikeHtmlOrJunk = raw.contains('<!DOCTYPE') ||
        raw.contains('<html') ||
        raw.contains('font-face') ||
        raw.contains('base64,') ||
        raw.length > 300;

    if (!looksLikeHtmlOrJunk) return raw;

    return 'Ocurrió un error inesperado en el servidor. Intentá de nuevo '
        'más tarde; si el problema persiste, contactá al administrador.';
  }
}
