import '../utils/json_parsing.dart';

class CanjeGarrafa {
  final int? idCanje;
  final int? idVisita;
  final String? productoId;
  final String? sku;
  final String descripcion;
  final int kg;
  final String descripcionDanio;
  final DateTime? timestamp;
  final String? uuidOffline;

  const CanjeGarrafa({
    this.idCanje,
    this.idVisita,
    this.productoId,
    this.sku,
    this.descripcion = '',
    required this.kg,
    required this.descripcionDanio,
    this.timestamp,
    this.uuidOffline,
  });

  factory CanjeGarrafa.fromJson(Map<String, dynamic> json) {
    return CanjeGarrafa(
      idCanje: parseInt(json['id_canje']) ?? parseInt(json['idCanje']),
      idVisita: parseInt(json['id_visita']) ?? parseInt(json['idVisita']),
      productoId: (json['producto_id'] ??
              json['productoId'] ??
              json['id_producto'] ??
              json['idProducto'])
          ?.toString(),
      sku: (json['sku'] ?? json['producto_codigo'] ?? json['productoCodigo'])
          ?.toString(),
      descripcion: (json['producto_descripcion'] ??
              json['productoDescripcion'] ??
              json['descripcion_producto'] ??
              '')
          .toString(),
      kg: parseInt(json['kg']) ??
          parseInt(json['kilos']) ??
          parseInt(json['tamanio']) ??
          0,
      descripcionDanio: (json['descripcion_danio'] ??
              json['descripcionDanio'] ??
              json['descripcion'] ??
              '')
          .toString(),
      timestamp: parseDate(json['timestamp']) ?? parseDate(json['fecha']),
      uuidOffline: (json['uuid_offline'] ?? json['uuidOffline'])?.toString(),
    );
  }
}

class CanjeGarrafaDraft {
  final int? idVisita;
  final int? idAgendaItem;
  final String idUsuario;
  final DateTime? fecha;
  final int? idClienteExt;
  final String uuidOffline;
  final String productoId;
  final String sku;
  final String descripcion;
  final int kg;
  final String descripcionDanio;
  final DateTime timestamp;

  const CanjeGarrafaDraft({
    this.idVisita,
    this.idAgendaItem,
    required this.idUsuario,
    this.fecha,
    this.idClienteExt,
    required this.uuidOffline,
    required this.productoId,
    required this.sku,
    required this.descripcion,
    required this.kg,
    required this.descripcionDanio,
    required this.timestamp,
  });

  String get etiquetaSku => descripcion.isNotEmpty ? descripcion : '$kg kg';

  Map<String, dynamic> toRequestJson() {
    return {
      'productoId': productoId,
      'sku': sku,
      'kg': kg,
      'descripcionDanio': descripcionDanio.trim(),
      'timestamp': timestamp.toUtc().toIso8601String(),
      'uuidOffline': uuidOffline,
    };
  }
}
