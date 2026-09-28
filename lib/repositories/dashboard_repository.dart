import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/dashboard/dashboard_filtros.dart';
import '../models/dashboard/dashboard_kpis.dart';
import '../models/dashboard/tendencia_punto.dart';
import 'network_exception.dart';

class DashboardRepositoryException implements Exception {
  final String message;
  DashboardRepositoryException(this.message);

  @override
  String toString() => message;
}

class DashboardResultado {
  final DashboardKpis kpis;
  final List<TendenciaPunto>? serieBackend;

  const DashboardResultado({required this.kpis, this.serieBackend});
}

class DashboardRepository {
  final http.Client _client;

  DashboardRepository(this._client);

  static const int maxPuntosTendencia = 14;
  static const int _concurrencia = 4;

  Future<DashboardResultado> obtener(DashboardFiltros filtros) async {
    final json = await _getMatriz(filtros.queryParams());
    final serie = json['serieTemporal'];
    List<TendenciaPunto>? puntos;
    if (serie is List && serie.isNotEmpty) {
      puntos = serie
          .whereType<Map<String, dynamic>>()
          .map(TendenciaPunto.fromSerieJson)
          .toList()
        ..sort((a, b) => a.desde.compareTo(b.desde));
    }
    return DashboardResultado(kpis: DashboardKpis.fromJson(json), serieBackend: puntos);
  }

  Future<List<TendenciaPunto>> tendencia(DashboardFiltros filtros) async {
    final tramos = tramosTendencia(filtros.desde, filtros.hasta);
    final resultado = List<TendenciaPunto?>.filled(tramos.length, null);
    var siguiente = 0;

    Future<void> trabajador() async {
      while (siguiente < tramos.length) {
        final i = siguiente++;
        final tramo = tramos[i];
        final json = await _getMatriz(
          filtros.queryParams(desdeOverride: tramo.$1, hastaOverride: tramo.$2),
        );
        final kpis = DashboardKpis.fromJson(json);
        resultado[i] = TendenciaPunto(
          desde: tramo.$1,
          hasta: tramo.$2,
          montoTotal: kpis.ventas.montoTotal,
          volumenEntregado: kpis.ventas.volumenEntregado,
          programadas: kpis.agenda.programadas,
          realizadas: kpis.agenda.realizadas,
          porcentajeCumplimiento: kpis.agenda.porcentajeCumplimiento,
        );
      }
    }

    final trabajadores = tramos.length < _concurrencia ? tramos.length : _concurrencia;
    await Future.wait(List.generate(trabajadores, (_) => trabajador()));
    return resultado.whereType<TendenciaPunto>().toList();
  }

  static List<(DateTime, DateTime)> tramosTendencia(DateTime desde, DateTime hasta) {
    final inicio = DateTime(desde.year, desde.month, desde.day);
    final fin = DateTime(hasta.year, hasta.month, hasta.day);
    final dias = fin.difference(inicio).inDays + 1;
    if (dias <= 0) return const [];
    final tamanio = (dias / maxPuntosTendencia).ceil();
    final tramos = <(DateTime, DateTime)>[];
    var cursor = inicio;
    while (!cursor.isAfter(fin)) {
      var cierre = DateTime(cursor.year, cursor.month, cursor.day + tamanio - 1);
      if (cierre.isAfter(fin)) cierre = fin;
      tramos.add((cursor, cierre));
      cursor = DateTime(cierre.year, cierre.month, cierre.day + 1);
    }
    return tramos;
  }

  Future<Map<String, dynamic>> _getMatriz(Map<String, String> params) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.adminDashboardKpisPath}')
        .replace(queryParameters: params);
    http.Response response;
    try {
      response = await _client
          .get(uri, headers: const {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 40));
    } catch (_) {
      throw NetworkException();
    }

    if (response.statusCode == 200) {
      try {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is Map<String, dynamic>) return decoded;
      } catch (_) {}
      throw DashboardRepositoryException('La respuesta de indicadores no tiene el formato esperado.');
    }

    final mensaje = _mensajeError(response.body);
    switch (response.statusCode) {
      case 400:
        throw DashboardRepositoryException(mensaje ?? 'Los filtros elegidos no son válidos.');
      case 401:
      case 403:
        throw DashboardRepositoryException(mensaje ?? 'Tu usuario no tiene permisos para ver el dashboard.');
      default:
        throw DashboardRepositoryException(
          mensaje ?? 'Error del servidor (${response.statusCode}) al cargar los indicadores.',
        );
    }
  }

  String? _mensajeError(String body) {
    if (body.isEmpty) return null;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final error = decoded['error'];
        final message = error is Map<String, dynamic> ? error['message'] : decoded['message'];
        if (message is String && message.isNotEmpty && message.length < 300) return message;
      }
    } catch (_) {}
    return null;
  }
}
