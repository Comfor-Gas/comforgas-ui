import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/auth_result.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}

class AuthApi {
  final http.Client _client;

  AuthApi([http.Client? client]) : _client = client ?? http.Client();

  Future<AuthResult> login({
    required String email,
    required String password,
  }) {
    return _iniciarSesion(
      path: ApiConfig.loginPath,
      body: {'email': email.trim().toLowerCase(), 'password': password},
      credencialesInvalidas: 'Correo o contraseña incorrectos.',
    );
  }

  Future<AuthResult> loginChofer({
    required String usuario,
    required String password,
  }) {
    return _iniciarSesion(
      path: ApiConfig.choferLoginPath,
      body: {'username': usuario.trim(), 'password': password},
      credencialesInvalidas: 'Usuario o contraseña incorrectos.',
    );
  }

  Future<AuthResult> _iniciarSesion({
    required String path,
    required Map<String, String> body,
    required String credencialesInvalidas,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');

    http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 25));
    } catch (_) {
      throw AuthException('No se pudo conectar con el servidor. Revisa tu conexión.');
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw AuthException('Respuesta inesperada del servidor.');
      }
      return AuthResult.fromJson(decoded);
    }

    final codigo = _codigoError(response.body);
    if (codigo == 'EXTERNAL_AGENDA_UNAVAILABLE' || response.statusCode == 502 || response.statusCode == 503) {
      throw AuthException(
        'El servicio externo de autenticación no responde. Intentá nuevamente en unos minutos.',
      );
    }
    if (codigo == 'CONSTRAINT_VIOLATION' || response.statusCode == 400) {
      throw AuthException('Por favor completá todos los campos.');
    }
    if (codigo == 'INVALID_CREDENTIALS' || response.statusCode == 401) {
      throw AuthException(credencialesInvalidas);
    }
    if (response.statusCode == 403) {
      throw AuthException(
        path == ApiConfig.choferLoginPath
            ? 'Tu usuario se encuentra inactivo. Comunicate con la administración.'
            : 'Tu cuenta no tiene acceso o no está verificada.',
      );
    }

    throw AuthException('Error del servidor (${response.statusCode}). Intentá más tarde.');
  }

  String? _codigoError(String body) {
    if (body.isEmpty) return null;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic> && decoded['error'] is Map<String, dynamic>) {
        final code = (decoded['error'] as Map<String, dynamic>)['code'];
        if (code is String && code.isNotEmpty) return code.toUpperCase();
      }
    } catch (_) {}
    return null;
  }

  Future<AuthResult> refresh({required String refreshToken}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.refreshPath}');

    http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'refreshToken': refreshToken}),
          )
          .timeout(const Duration(seconds: 20));
    } catch (_) {
      throw AuthException('No se pudo conectar con el servidor. Revisa tu conexión.');
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw AuthException('Respuesta inesperada del servidor.');
      }
      return AuthResult.fromJson(decoded);
    }

    throw AuthException('Sesión expirada. Inicia sesión de nuevo.');
  }

  Future<void> logout({
    required String refreshToken,
    String? accessToken,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.logoutPath}');

    final headers = <String, String>{'Content-Type': 'application/json'};
    if (accessToken != null && accessToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $accessToken';
    }

    try {
      await _client
          .post(uri, headers: headers, body: jsonEncode({'refreshToken': refreshToken}))
          .timeout(const Duration(seconds: 10));
    } catch (_) {
    }
  }


  Future<void> register({
    required String accessToken,
    required String email,
    required String password,
    required String fullName,
    required String rol,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.registerPath}');

    http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $accessToken',
            },
            body: jsonEncode({
              'email': email,
              'password': password,
              'fullName': fullName,
              'rol': rol,
            }),
          )
          .timeout(const Duration(seconds: 20));
    } catch (_) {
      throw AuthException('No se pudo conectar con el servidor. Revisa tu conexión.');
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      return;
    }

    if (response.statusCode == 400) {
      throw AuthException('Datos inválidos. Revisa los campos.');
    }
    if (response.statusCode == 401) {
      throw AuthException('Sesión expirada. Inicia sesión de nuevo.');
    }
    if (response.statusCode == 403) {
      throw AuthException('No tenés permisos para registrar usuarios.');
    }
    if (response.statusCode == 409) {
      throw AuthException('Ya existe un usuario con ese correo.');
    }

    throw AuthException('Error del servidor (${response.statusCode}). Intenta más tarde.');
  }
}
