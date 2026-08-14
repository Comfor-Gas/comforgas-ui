import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../local/offline_evento.dart';
import 'network_exception.dart';

class SincronizacionRepositoryException implements Exception {
  final String message;
  SincronizacionRepositoryException(this.message);

  @override
  String toString() => message;
}

/// Resultado de un evento individual dentro de la respuesta del lote.
class ItemSincronizacionResultado {
  static const String procesado = 'PROCESADO';
  static const String omitido = 'OMITIDO';
  static const String error = 'ERROR';

  final String uuidOffline;
  final String estado;
  final String? mensaje;

  const ItemSincronizacionResultado({
    required this.uuidOffline,
    required this.estado,
    this.mensaje,
  });

  factory ItemSincronizacionResultado.fromJson(Map<String, dynamic> json) {
    return ItemSincronizacionResultado(
      uuidOffline: json['uuidOffline'] as String? ?? '',
      estado: json['estado'] as String? ?? '',
      mensaje: json['mensaje'] as String?,
    );
  }

  /// PROCESADO o OMITIDO: en ambos casos el evento ya quedó reflejado en
  /// el backend (o ya lo estaba de antes) y hay que sacarlo de la cola
  /// local. Solo ERROR debe conservarse para reintentar.
  bool get resueltoEnBackend => estado == procesado || estado == omitido;
}

class SincronizacionLoteResultado {
  final int totalRecibidos;
  final int procesados;
  final int omitidos;
  final int errores;
  final List<ItemSincronizacionResultado> resultados;

  const SincronizacionLoteResultado({
    required this.totalRecibidos,
    required this.procesados,
    required this.omitidos,
    required this.errores,
    required this.resultados,
  });

  factory SincronizacionLoteResultado.fromJson(Map<String, dynamic> json) {
    final lista = (json['resultados'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(ItemSincronizacionResultado.fromJson)
        .toList();
    return SincronizacionLoteResultado(
      totalRecibidos: json['totalRecibidos'] as int? ?? 0,
      procesados: json['procesados'] as int? ?? 0,
      omitidos: json['omitidos'] as int? ?? 0,
      errores: json['errores'] as int? ?? 0,
      resultados: lista,
    );
  }
}

/// Envía en un solo lote los eventos offline (check-in, check-out,
/// evidencias) acumulados en el dispositivo hacia
/// `POST /api/visitas/sync-lote`.
class SincronizacionRepository {
  final http.Client _client;

  SincronizacionRepository(this._client);

  Future<SincronizacionLoteResultado> sincronizarLote(List<OfflineEvento> eventos) async {
    if (eventos.isEmpty) {
      return const SincronizacionLoteResultado(
        totalRecibidos: 0,
        procesados: 0,
        omitidos: 0,
        errores: 0,
        resultados: [],
      );
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.visitasSyncLotePath}');

    http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'eventos': eventos.map(_eventoToJson).toList()}),
          )
          // El lote puede incluir varias fotos en base64: le damos más
          // margen que a una request individual.
          .timeout(const Duration(seconds: 90));
    } catch (_) {
      throw NetworkException();
    }

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw SincronizacionRepositoryException('Respuesta inesperada del servidor.');
      }
      return SincronizacionLoteResultado.fromJson(decoded);
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw SincronizacionRepositoryException(
        'Tu sesión no tiene permisos para sincronizar, o expiró.',
      );
    }

    throw SincronizacionRepositoryException(
      'Error del servidor (${response.statusCode}) al sincronizar. Se reintentará más tarde.',
    );
  }

  Map<String, dynamic> _eventoToJson(OfflineEvento e) {
    return {
      'uuidOffline': e.uuidOffline,
      'tipoEvento': e.tipoEvento,
      'idAgendaItem': e.idAgendaItem,
      'timestampOrigen': e.timestampOrigen.toUtc().toIso8601String(),
      if (e.latitud != null) 'latitud': e.latitud,
      if (e.longitud != null) 'longitud': e.longitud,
      if (e.observaciones != null) 'observaciones': e.observaciones,
      if (e.timestampFin != null) 'timestampFin': e.timestampFin!.toUtc().toIso8601String(),
      if (e.latitudFin != null) 'latitudFin': e.latitudFin,
      if (e.longitudFin != null) 'longitudFin': e.longitudFin,
      if (e.archivoBytes != null) 'archivoBase64': base64Encode(e.archivoBytes!),
      if (e.tipoEvidencia != null) 'tipoEvidencia': e.tipoEvidencia,
      if (e.mimeType != null) 'mimeType': e.mimeType,
    };
  }
}
