import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/rendicion_ruta.dart';
import '../utils/json_parsing.dart';
import 'network_exception.dart';

class RendicionRepositoryException implements Exception {
  final String message;
  final bool endpointNoDisponible;

  RendicionRepositoryException(this.message, {this.endpointNoDisponible = false});

  bool get yaRegistrada => message.toLowerCase().contains('ya existe una rendici');

  @override
  String toString() => message;
}

class RendicionRepository {
  final http.Client _client;

  RendicionRepository([http.Client? client]) : _client = client ?? http.Client();

  Future<void> enviar(RendicionDraft draft) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.repartidorRendicionPath}');

    http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(draft.toRequestJson()),
          )
          .timeout(const Duration(seconds: 25));
    } catch (_) {
      throw NetworkException();
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      return;
    }

    if (response.statusCode == 404 || response.statusCode == 405 || response.statusCode == 501) {
      throw RendicionRepositoryException(
        'El endpoint de rendición todavía no está disponible en el backend.',
        endpointNoDisponible: true,
      );
    }

    if (response.statusCode == 400 || response.statusCode == 409) {
      throw RendicionRepositoryException(
        _extractErrorMessage(response.body) ??
            'La rendición tiene datos inconsistentes y no se pudo enviar.',
      );
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw RendicionRepositoryException(
        _extractErrorMessage(response.body) ??
            'Tu sesión no tiene permisos para enviar la rendición.',
      );
    }

    throw RendicionRepositoryException(
      _extractErrorMessage(response.body) ??
          'Error del servidor (${response.statusCode}). Intentá más tarde.',
    );
  }

  Future<RendicionRegistrada?> obtenerMia(DateTime fecha) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.choferMiRendicionPath}/${formatDateOnly(fecha)}',
    );
    http.Response response;
    try {
      response = await _client.get(uri).timeout(const Duration(seconds: 15));
    } catch (_) {
      throw NetworkException();
    }
    if (response.statusCode == 404) return null;
    if (response.statusCode != 200 || response.body.isEmpty) {
      throw RendicionRepositoryException(
        _extractErrorMessage(response.body) ?? 'No se pudo consultar la rendición enviada.',
      );
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) return null;
    return RendicionRegistrada.fromJson(decoded);
  }

  String? _extractErrorMessage(String body) {
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

class RendicionRegistrada {
  final int efectivo;
  final int cheques;
  final int transferencias;
  final int vacios;
  final int llenos;
  final int danados;
  final String observaciones;
  final String estado;
  final bool conciliada;

  const RendicionRegistrada({
    required this.efectivo,
    required this.cheques,
    required this.transferencias,
    required this.vacios,
    required this.llenos,
    required this.danados,
    required this.observaciones,
    required this.estado,
    required this.conciliada,
  });

  factory RendicionRegistrada.fromJson(Map<String, dynamic> json) {
    int monto(String k) => (parseDouble(json[k]) ?? 0).round();
    return RendicionRegistrada(
      efectivo: monto('montoEfectivoRendido'),
      cheques: monto('montoChequesRendido'),
      transferencias: monto('montoTransferenciasRendido'),
      vacios: parseInt(json['cantidadVaciosRendidos']) ?? 0,
      llenos: parseInt(json['cantidadLlenosDevueltos']) ?? 0,
      danados: parseInt(json['cantidadDanadosRendidos']) ?? 0,
      observaciones: (json['observacionesChofer'] ?? '').toString(),
      estado: (json['estadoRendicion'] ?? '').toString(),
      conciliada: json['conciliadoAt'] != null,
    );
  }
}
