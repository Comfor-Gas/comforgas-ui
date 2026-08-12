import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/evidencia_fotografica_model.dart';
import 'network_exception.dart';

class EvidenciaRepositoryException implements Exception {
  final String message;
  EvidenciaRepositoryException(this.message);

  @override
  String toString() => message;
}
class EvidenciaRepository {
  final http.Client _client;

  EvidenciaRepository([http.Client? client]) : _client = client ?? http.Client();

  Future<List<EvidenciaFotograficaModel>> listarPorVisita(int idVisita) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.evidenciasFotograficasPath}?idVisita=$idVisita',
    );

    http.Response response;
    try {
      response = await _client
          .get(uri, headers: const {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 20));
    } catch (_) {
      throw NetworkException();
    }

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(EvidenciaFotograficaModel.fromJson)
          .toList();
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw EvidenciaRepositoryException(
        _extractErrorMessage(response.body) ??
            'Tu sesión no tiene permisos para ver la evidencia de esta visita.',
      );
    }

    throw EvidenciaRepositoryException(
      _extractErrorMessage(response.body) ??
          'Error del servidor (${response.statusCode}). Intenta más tarde.',
    );
  }

  Future<EvidenciaFotograficaModel> subirEvidencia({
    required int idVisita,
    required String tipoEvidencia,
    required File archivo,
    String? observaciones,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.evidenciasFotograficasPath}');

    final request = http.MultipartRequest('POST', uri)
      ..fields['idVisita'] = '$idVisita'
      ..fields['tipoEvidencia'] = tipoEvidencia
      ..fields['timestampCaptura'] = DateTime.now().toUtc().toIso8601String();

    if (observaciones != null && observaciones.trim().isNotEmpty) {
      request.fields['observaciones'] = observaciones.trim();
    }

    try {
      request.files.add(await http.MultipartFile.fromPath('archivo', archivo.path));
    } catch (_) {
      throw EvidenciaRepositoryException('No se pudo leer la foto capturada.');
    }

    http.StreamedResponse streamed;
    try {
      streamed = await _client.send(request).timeout(const Duration(seconds: 30));
    } catch (_) {
      throw NetworkException();
    }

    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw EvidenciaRepositoryException('Respuesta inesperada del servidor.');
      }
      return EvidenciaFotograficaModel.fromJson(decoded);
    }

    if (response.statusCode == 400) {
      throw EvidenciaRepositoryException(
        _extractErrorMessage(response.body) ?? 'La evidencia fotográfica es inválida.',
      );
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw EvidenciaRepositoryException(
        _extractErrorMessage(response.body) ??
            'Tu sesión no tiene permisos para subir evidencia fotográfica.',
      );
    }

    throw EvidenciaRepositoryException(
      _extractErrorMessage(response.body) ??
          'Error del servidor (${response.statusCode}). Intenta más tarde.',
    );
  }

  String? _extractErrorMessage(String body) {
    if (body.isEmpty) return null;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic> && decoded['error'] is Map<String, dynamic>) {
        final error = decoded['error'] as Map<String, dynamic>;
        final message = error['message'];
        if (message is String && message.isNotEmpty) return message;
      }
    } catch (_) {
    }
    return null;
  }
}
