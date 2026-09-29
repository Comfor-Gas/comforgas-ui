import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/cuadre_rendicion.dart';
import '../utils/json_parsing.dart';
import 'network_exception.dart';

class RendicionAdminRepositoryException implements Exception {
  final String message;
  final bool endpointNoDisponible;

  RendicionAdminRepositoryException(this.message, {this.endpointNoDisponible = false});

  @override
  String toString() => message;
}

class RendicionAdminRepository {
  final http.Client _client;

  RendicionAdminRepository([http.Client? client]) : _client = client ?? http.Client();

  Future<CuadreRendicion> getCuadre({
    required String idUsuario,
    required DateTime fecha,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.adminConciliacionChoferPath}'
      '/$idUsuario/${formatDateOnly(fecha)}',
    );

    http.Response response;
    try {
      response = await _client.get(uri).timeout(const Duration(seconds: 20));
    } catch (_) {
      throw NetworkException();
    }

    if (response.statusCode == 200 && response.body.isNotEmpty) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return CuadreRendicion.fromConciliacion(decoded);
      }
      throw RendicionAdminRepositoryException('Respuesta inesperada del servidor.');
    }

    if (response.statusCode == 404) {
      return CuadreRendicion.vacio(idUsuario: idUsuario, fecha: fecha);
    }

    throw RendicionAdminRepositoryException(
      _extractErrorMessage(response.body) ??
          'Error del servidor (${response.statusCode}) al cargar el cuadre.',
    );
  }

  Future<void> aprobarConciliacion({
    required int idRendicion,
    String? observacion,
    bool aceptarDiferencias = false,
  }) async {
    final obs = observacion?.trim();
    await _post('${ApiConfig.adminConciliacionPath}/$idRendicion/aprobar', {
      if (obs != null && obs.isNotEmpty) 'observacionesAdmin': obs,
      'aceptarDiferencias': aceptarDiferencias,
    });
  }

  Future<void> ajustarConciliacion({
    required int idRendicion,
    required ConceptoAjuste concepto,
    required TipoAjuste tipo,
    required int valor,
    required String observacion,
  }) async {
    await _post('${ApiConfig.adminConciliacionPath}/$idRendicion/ajustar', {
      'ajustes': [
        {
          'concepto': concepto.codigo,
          'tipo': tipo.codigo,
          if (concepto.esDinero) 'importe': valor else 'cantidad': valor,
          'observacion': observacion.trim(),
        },
      ],
    });
  }

  Future<void> _post(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    http.Response response;
    try {
      response = await _client
          .post(uri, headers: const {'Content-Type': 'application/json'}, body: jsonEncode(body))
          .timeout(const Duration(seconds: 20));
    } catch (_) {
      throw NetworkException();
    }

    if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204) {
      return;
    }
    if (_noDisponible(response.statusCode)) {
      throw RendicionAdminRepositoryException(
        'El endpoint de conciliación todavía no está disponible en el backend.',
        endpointNoDisponible: true,
      );
    }
    throw RendicionAdminRepositoryException(
      _extractErrorMessage(response.body) ??
          'Error del servidor (${response.statusCode}). Intentá más tarde.',
    );
  }

  bool _noDisponible(int status) => status == 404 || status == 405 || status == 501;

  String? _extractErrorMessage(String body) {
    if (body.isEmpty) return null;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic> && decoded['error'] is Map<String, dynamic>) {
        final message = (decoded['error'] as Map<String, dynamic>)['message'];
        if (message is String && message.isNotEmpty && message.length <= 300) {
          return message;
        }
      }
    } catch (_) {}
    return null;
  }
}
