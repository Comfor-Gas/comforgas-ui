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
}
