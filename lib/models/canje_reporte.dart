import '../utils/json_parsing.dart';

class CanjeReporte {
  final String? choferId;
  final String nombreChofer;
  final int? movil;
  final String? idProducto;
  final String sku;
  final String descripcionProducto;
  final String descripcionDanio;
  final int cantidad;
  final DateTime? primerCanje;
  final DateTime? ultimoCanje;

  const CanjeReporte({
    this.choferId,
    required this.nombreChofer,
    this.movil,
    this.idProducto,
    required this.sku,
    required this.descripcionProducto,
    required this.descripcionDanio,
    required this.cantidad,
    this.primerCanje,
    this.ultimoCanje,
  });

  String get etiquetaProducto {
    if (descripcionProducto.trim().isNotEmpty) return descripcionProducto.trim();
    if (sku.trim().isNotEmpty) return sku.trim();
    return 'Producto s/d';
  }

  static List<CanjeReporteGrupo> agrupar(List<CanjeReporte> filas) {
    final mapa = <String, List<CanjeReporte>>{};
    for (final f in filas) {
      final clave = '${f.choferId ?? f.nombreChofer}|${f.movil ?? ''}';
      mapa.putIfAbsent(clave, () => []).add(f);
    }
    final grupos = mapa.values.map((items) {
      final total = items.fold<int>(0, (a, e) => a + e.cantidad);
      DateTime? ultimo;
      for (final e in items) {
        final u = e.ultimoCanje;
        if (u != null && (ultimo == null || u.isAfter(ultimo!))) ultimo = u;
      }
      items.sort((a, b) => b.cantidad.compareTo(a.cantidad));
      return CanjeReporteGrupo(
        choferId: items.first.choferId,
        nombreChofer: items.first.nombreChofer,
        movil: items.first.movil,
        totalDevoluciones: total,
        ultimoCanje: ultimo,
        detalles: items,
      );
    }).toList();
    grupos.sort((a, b) => b.totalDevoluciones.compareTo(a.totalDevoluciones));
    return grupos;
  }

  factory CanjeReporte.fromJson(Map<String, dynamic> json) {
    return CanjeReporte(
      choferId: (json['chofer_id'] ?? json['choferId'])?.toString(),
      nombreChofer:
          (json['nombre_chofer'] ?? json['nombreChofer'] ?? 'Sin asignar').toString(),
      movil: parseInt(json['movil']),
      idProducto: (json['id_producto'] ?? json['idProducto'])?.toString(),
      sku: (json['sku'] ?? '').toString(),
      descripcionProducto:
          (json['descripcion_producto'] ?? json['descripcionProducto'] ?? '').toString(),
      descripcionDanio:
          (json['descripcion_danio'] ?? json['descripcionDanio'] ?? '').toString(),
      cantidad: parseInt(json['cantidad']) ?? 0,
      primerCanje: parseDate(json['primer_canje']) ?? parseDate(json['primerCanje']),
      ultimoCanje: parseDate(json['ultimo_canje']) ?? parseDate(json['ultimoCanje']),
    );
  }
}

class CanjeReporteGrupo {
  final String? choferId;
  final String nombreChofer;
  final int? movil;
  final int totalDevoluciones;
  final DateTime? ultimoCanje;
  final List<CanjeReporte> detalles;

  const CanjeReporteGrupo({
    this.choferId,
    required this.nombreChofer,
    this.movil,
    required this.totalDevoluciones,
    this.ultimoCanje,
    required this.detalles,
  });

  String get etiquetaMovil => movil != null ? 'Móvil $movil' : 'Sin móvil';
}
