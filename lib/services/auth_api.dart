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
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.loginPath}');

    http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
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

    if (response.statusCode == 400 || response.statusCode == 401) {
      throw AuthException('Correo o contraseña incorrectos.');
    }

    if (response.statusCode == 403) {
      throw AuthException('Tu cuenta no tiene acceso o no está verificada.');
    }

    throw AuthException('Error del servidor (${response.statusCode}). Intenta más tarde.');
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
