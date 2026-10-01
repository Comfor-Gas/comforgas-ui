import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/chofer_cuenta.dart';
import '../models/chofer_externo.dart';
import 'network_exception.dart';

class GestionChoferesException implements Exception {
  final String message;
  final int? statusCode;

  GestionChoferesException(this.message, {this.statusCode});

  bool get endpointNoDisponible => statusCode == 404 || statusCode == 405 || statusCode == 501;

  @override
  String toString() => message;
}

class GestionChoferesRepository {
  final http.Client _client;

  GestionChoferesRepository(this._client);

  static const Map<String, String> _headers = {'Content-Type': 'application/json'};

  Uri _uri(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

  Future<List<ChoferCuenta>> listarCuentas() async {
    try {
      final response = await _enviar(() => _client.get(_uri(ApiConfig.adminChoferesPath), headers: _headers));
      return _lista(response.body).map(ChoferCuenta.fromJson).toList();
    } on GestionChoferesException catch (e) {
      if (!e.endpointNoDisponible) rethrow;
      final uri = _uri(ApiConfig.usuariosPath).replace(queryParameters: {'rol': 'CHOFER'});
      final response = await _enviar(() => _client.get(uri, headers: _headers));
      return _lista(response.body).map(ChoferCuenta.fromJson).toList();
    }
  }

  Future<List<ChoferExterno>> listarExternos() async {
    final response = await _enviar(() => _client.get(_uri(ApiConfig.adminChoferesExternosPath), headers: _headers));
    return _lista(response.body).map(ChoferExterno.fromJson).where((c) => c.nombre.isNotEmpty).toList();
  }

  Future<ChoferCuenta?> crear({
    required String email,
    required String password,
    required ChoferExterno chofer,
  }) async {
    final response = await _enviar(() => _client.post(
          _uri(ApiConfig.adminChoferesPath),
          headers: _headers,
          body: jsonEncode({
            'email': email.trim(),
            'password': password,
            'idChoferExterno': chofer.idChoferExterno,
            'nombre': chofer.nombre,
            if (chofer.documento != null) 'documento': chofer.documento,
          }),
        ));
    return _cuenta(response.body);
  }

  Future<ChoferCuenta?> editar({
    required String idUsuario,
    String? email,
    String? password,
  }) async {
    final response = await _enviar(() => _client.patch(
          _uri(ApiConfig.adminChoferPath(idUsuario)),
          headers: _headers,
          body: jsonEncode({
            if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
            if (password != null && password.isNotEmpty) 'password': password,
          }),
        ));
    return _cuenta(response.body);
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
    if (code == 401 || code == 403) {
      throw GestionChoferesException(
        _mensaje(response.body) ?? 'No tenés permisos para gestionar choferes.',
        statusCode: code,
      );
    }
    if (code == 409) {
      throw GestionChoferesException(
        _mensaje(response.body) ?? 'Ese correo o ese chofer ya tienen una cuenta.',
        statusCode: code,
      );
    }
    throw GestionChoferesException(
      _mensaje(response.body) ?? 'Error del servidor ($code). Intentá más tarde.',
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

  ChoferCuenta? _cuenta(String body) {
    if (body.isEmpty) return null;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return ChoferCuenta.fromJson(decoded);
    } catch (_) {}
    return null;
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
