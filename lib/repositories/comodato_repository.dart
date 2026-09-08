import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/control_comodato.dart';
import 'network_exception.dart';

class ComodatoRepositoryException implements Exception {
  final String message;
  ComodatoRepositoryException(this.message);

  @override
  String toString() => message;
}

class ComodatoRepository {
  final http.Client _client;

  ComodatoRepository(this._client);

  static const Map<String, String> _jsonHeaders = {
    'Content-Type': 'application/json',
  };

  Future<ContratoComodato?> getContratoCliente(int idClienteExt) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.comodatoClientePath}/$idClienteExt',
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
      if (response.body.isEmpty) return null;
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw ComodatoRepositoryException('Respuesta inesperada del servidor.');
      }
      return ContratoComodato.fromJson(decoded);
    }

    if (response.statusCode == 404) {
      return null;
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw ComodatoRepositoryException(
        _mensajeError(response.body) ??
            'Tu sesión no tiene permisos para ver el comodato del cliente.',
      );
    }

    throw ComodatoRepositoryException(
      _mensajeError(response.body) ??
          'Error del servidor (${response.statusCode}) al consultar el comodato.',
    );
  }

  Future<ControlComodato?> getControlDeVisita(int idVisita) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.visitasPath}/$idVisita${ApiConfig.visitaComodatoSuffix}',
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
      if (response.body.isEmpty) return null;
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw ComodatoRepositoryException('Respuesta inesperada del servidor.');
      }
      return ControlComodato.fromJson(decoded);
    }

    if (response.statusCode == 404) {
      return null;
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw ComodatoRepositoryException(
        _mensajeError(response.body) ??
            'Tu sesión no tiene permisos para ver el control de comodato.',
      );
    }

    throw ComodatoRepositoryException(
      _mensajeError(response.body) ??
          'Error del servidor (${response.statusCode}) al consultar el control.',
    );
  }

  Future<ControlComodato> registrarControl(
    int idVisita,
    ControlComodatoDraft draft,
  ) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.visitasPath}/$idVisita${ApiConfig.visitaComodatoSuffix}',
    );

    http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: _jsonHeaders,
            body: jsonEncode(draft.toRequestJson()),
          )
          .timeout(const Duration(seconds: 20));
    } catch (_) {
      throw NetworkException();
    }

    final code = response.statusCode;
    if (code == 200 || code == 201) {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw ComodatoRepositoryException('Respuesta inesperada del servidor.');
      }
      return ControlComodato.fromJson(decoded);
    }

    if (code == 400 || code == 409) {
      throw ComodatoRepositoryException(
        _mensajeError(response.body) ??
            'No se pudo registrar el control de comodato. Verificá los datos.',
      );
    }

    if (code == 401 || code == 403) {
      throw ComodatoRepositoryException(
        _mensajeError(response.body) ??
            'Tu sesión no tiene permisos para registrar controles de comodato.',
      );
    }

    if (code == 404) {
      throw ComodatoRepositoryException(
        _mensajeError(response.body) ??
            'No se encontró la visita o el contrato de comodato vigente.',
      );
    }

    throw ComodatoRepositoryException(
      _mensajeError(response.body) ??
          'Error del servidor ($code) al registrar el control.',
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
