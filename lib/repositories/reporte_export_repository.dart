import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/dashboard/dashboard_filtros.dart';
import '../utils/json_parsing.dart';
import 'network_exception.dart';

enum TipoReporteExport { rendimientoComercialRuta, cumplimientoComodato }

extension TipoReporteExportInfo on TipoReporteExport {
  String get codigo {
    switch (this) {
      case TipoReporteExport.rendimientoComercialRuta:
        return 'RENDIMIENTO_COMERCIAL_RUTA';
      case TipoReporteExport.cumplimientoComodato:
        return 'CUMPLIMIENTO_COMODATO';
    }
  }

  String get etiqueta {
    switch (this) {
      case TipoReporteExport.rendimientoComercialRuta:
        return 'Rendimiento comercial por ruta';
      case TipoReporteExport.cumplimientoComodato:
        return 'Cumplimiento de comodatos';
    }
  }
}

enum FormatoReporte { xlsx, pdf }

extension FormatoReporteInfo on FormatoReporte {
  String get codigo => this == FormatoReporte.xlsx ? 'XLSX' : 'PDF';

  String get mimeType => this == FormatoReporte.xlsx
      ? 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
      : 'application/pdf';

  String get extension => this == FormatoReporte.xlsx ? 'xlsx' : 'pdf';
}

class ReporteExportException implements Exception {
  final String message;
  ReporteExportException(this.message);

  @override
  String toString() => message;
}

class ArchivoReporte {
  final Uint8List bytes;
  final String nombre;
  final String mimeType;
  final int? filas;

  const ArchivoReporte({
    required this.bytes,
    required this.nombre,
    required this.mimeType,
    this.filas,
  });
}

class _EstadoJob {
  final String id;
  final String estado;
  final String? nombreArchivo;
  final int? filas;
  final String? mensajeError;

  const _EstadoJob({
    required this.id,
    required this.estado,
    this.nombreArchivo,
    this.filas,
    this.mensajeError,
  });

  factory _EstadoJob.fromJson(Map<String, dynamic> j) => _EstadoJob(
        id: (j['idReporte'] ?? '').toString(),
        estado: (j['estado'] ?? '').toString().toUpperCase(),
        nombreArchivo: j['nombreArchivo']?.toString(),
        filas: parseInt(j['cantidadFilas']),
        mensajeError: j['mensajeError']?.toString(),
      );
}

class ReporteExportRepository {
  final http.Client _client;

  ReporteExportRepository(this._client);

  static const Duration _intervaloConsulta = Duration(seconds: 2);
  static const Duration _esperaMaxima = Duration(minutes: 2);

  Future<ArchivoReporte> exportar({
    required TipoReporteExport tipo,
    required FormatoReporte formato,
    required DashboardFiltros filtros,
  }) async {
    final body = {
      'tipoReporte': tipo.codigo,
      'formato': formato.codigo,
      'filtros': {
        'fechaDesde': formatDateOnly(filtros.desde),
        'fechaHasta': formatDateOnly(filtros.hasta),
        if (filtros.idSucursal != null) 'idSucursal': filtros.idSucursal,
        if (filtros.idChofer != null) 'idChofer': filtros.idChofer,
        if (filtros.idRuta != null) 'idRuta': filtros.idRuta,
      },
    };

    final solicitud = await _enviar(
      () => _client.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.adminReportesPath}/exportar'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ),
    );
    if (solicitud.statusCode != 200 && solicitud.statusCode != 202) {
      throw ReporteExportException(
        _mensajeError(solicitud.body) ?? 'No se pudo solicitar el reporte (${solicitud.statusCode}).',
      );
    }

    var job = _EstadoJob.fromJson(_decodificar(solicitud.body));
    if (job.id.isEmpty) {
      throw ReporteExportException('El servidor no devolvió el identificador del reporte.');
    }

    final limite = DateTime.now().add(_esperaMaxima);
    while (job.estado == 'PENDIENTE' || job.estado == 'PROCESANDO') {
      if (DateTime.now().isAfter(limite)) {
        throw ReporteExportException(
          'El reporte está tardando más de lo esperado. Probá de nuevo en unos minutos.',
        );
      }
      await Future<void>.delayed(_intervaloConsulta);
      final estado = await _enviar(
        () => _client.get(Uri.parse('${ApiConfig.baseUrl}${ApiConfig.adminReportesPath}/${job.id}')),
      );
      if (estado.statusCode != 200) {
        throw ReporteExportException(
          _mensajeError(estado.body) ?? 'No se pudo consultar el estado del reporte.',
        );
      }
      job = _EstadoJob.fromJson(_decodificar(estado.body));
    }

    if (job.estado == 'FALLIDO') {
      throw ReporteExportException(job.mensajeError ?? 'El servidor no pudo generar el reporte.');
    }
    if (job.estado == 'EXPIRADO') {
      throw ReporteExportException('El reporte expiró. Generalo de nuevo.');
    }

    final descarga = await _enviar(
      () => _client.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.adminReportesPath}/${job.id}/descargar'),
      ),
    );
    if (descarga.statusCode != 200) {
      throw ReporteExportException(
        _mensajeError(descarga.body) ?? 'No se pudo descargar el reporte.',
      );
    }

    final nombre = _nombreDesdeCabecera(descarga.headers['content-disposition']) ??
        job.nombreArchivo ??
        '${tipo.codigo.toLowerCase()}_${formatDateOnly(filtros.desde)}_${formatDateOnly(filtros.hasta)}.${formato.extension}';

    return ArchivoReporte(
      bytes: descarga.bodyBytes,
      nombre: nombre,
      mimeType: formato.mimeType,
      filas: job.filas,
    );
  }

  Future<http.Response> _enviar(Future<http.Response> Function() request) async {
    try {
      return await request().timeout(const Duration(seconds: 60));
    } catch (_) {
      throw NetworkException();
    }
  }

  Map<String, dynamic> _decodificar(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return const {};
  }

  String? _nombreDesdeCabecera(String? cabecera) {
    if (cabecera == null) return null;
    final utf = RegExp(r"filename\*=UTF-8''([^;]+)", caseSensitive: false).firstMatch(cabecera);
    if (utf != null) return Uri.decodeComponent(utf.group(1)!.trim());
    final simple = RegExp(r'filename="?([^";]+)"?', caseSensitive: false).firstMatch(cabecera);
    return simple?.group(1)?.trim();
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
