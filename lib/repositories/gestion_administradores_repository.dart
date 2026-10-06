import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/administrador_cuenta.dart';
import 'network_exception.dart';

class GestionAdministradoresException implements Exception {
  final String message;
  final int? statusCode;

  GestionAdministradoresException(this.message, {this.statusCode});

  bool get endpointNoDisponible => statusCode == 405 || statusCode == 501;

  @override
  String toString() => message;
}

class GestionAdministradoresRepository {
  static const String rolAdministrador = 'ADMINISTRADOR';

  final http.Client _client;

  GestionAdministradoresRepository(this._client);

  static const Map<String, String> _headers = {'Content-Type': 'application/json'};

  Uri _uri(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

  Future<List<AdministradorCuenta>> listar() async {
    final uri = _uri(ApiConfig.usuariosPath).replace(queryParameters: {'rol': rolAdministrador});
    final response = await _enviar(() => _client.get(uri, headers: _headers));
    return _lista(response.body)
        .map(AdministradorCuenta.fromJson)
        .where((c) => c.id.isNotEmpty)
        .toList();
  }

  Future<void> crear({
    required String nombre,
    required String email,
    required String password,
  }) async {
    await _enviar(() => _client.post(
          _uri(ApiConfig.usuariosPath),
          headers: _headers,
          body: jsonEncode({
            'fullName': nombre.trim(),
            'email': email.trim().toLowerCase(),
            'password': password,
            'rol': rolAdministrador,
          }),
        ));
  }

  Future<void> editar({
    required String idUsuario,
    String? nombre,
    String? email,
    String? password,
  }) async {
    final body = <String, dynamic>{
      if (nombre != null) 'fullName': nombre.trim(),
      if (email != null) 'email': email.trim().toLowerCase(),
      if (password != null && password.isNotEmpty) 'password': password,
    };
    if (body.isEmpty) return;
    await _enviar(() => _client.patch(
          _uri(ApiConfig.usuarioPath(idUsuario)),
          headers: _headers,
          body: jsonEncode(body),
        ));
  }

  Future<void> eliminar(String idUsuario) async {
    await _enviar(() => _client.delete(_uri(ApiConfig.usuarioPath(idUsuario)), headers: _headers));
  }

  Future<http.Response> _enviar(Future<http.Response> Function() llamada) async {
    http.Response response;
    try {
      response = await llamada().timeout(const Duration(seconds: 20));
    } catch (_) {
      throw NetworkException();
    }
    final code = response.statusCode;
    if (code >= 200 && code < 300) return response;
    final mensaje = _mensaje(response.body);
    if (code == 401 || code == 403) {
      throw GestionAdministradoresException(
        mensaje ?? 'No tenés permisos para gestionar administradores.',
        statusCode: code,
      );
    }
    if (code == 404) {
      throw GestionAdministradoresException(
        mensaje ?? 'El administrador ya no existe.',
        statusCode: code,
      );
    }
    if (code == 409) {
      throw GestionAdministradoresException(
        mensaje ?? 'Ya existe una cuenta con ese correo.',
        statusCode: code,
      );
    }
    throw GestionAdministradoresException(
      mensaje ?? 'Error del servidor ($code). Intentá más tarde.',
      statusCode: code,
    );
  }

  List<Map<String, dynamic>> _lista(String body) {
    if (body.isEmpty) return const [];
    final decoded = jsonDecode(body);
    final lista = decoded is Map<String, dynamic> ? decoded['data'] ?? decoded['content'] : decoded;
    if (lista is! List) return const [];
    return lista.whereType<Map<String, dynamic>>().toList();
  }

  String? _mensaje(String body) {
    if (body.isEmpty) return null;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final error = decoded['error'];
        if (error is Map<String, dynamic>) {
          final detalles = error['details'] ?? error['fieldErrors'];
          if (detalles is Map && detalles.isNotEmpty) {
            return detalles.values.map((v) => v.toString()).join(' ');
          }
          final message = error['message'];
          if (message is String && message.isNotEmpty && message.length <= 300) return message;
        }
        final message = decoded['message'];
        if (message is String && message.isNotEmpty && message.length <= 300) return message;
      }
    } catch (_) {}
    return null;
  }
}
