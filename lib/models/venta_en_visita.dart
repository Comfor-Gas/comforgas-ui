import '../utils/garrafa_match.dart';
import '../utils/json_parsing.dart';
import 'detalle_venta_draft.dart';
import 'producto_sku.dart';
import 'tipo_operacion_venta.dart';
import 'venta_draft.dart';

class VentaEnVisita {
  final String key;
  int? idVenta;
  String? uuidOffline;
  final int monto;
  final int cantidadLineas;
  final bool esSocial;
  final VentaDraft? draft;
  bool pendienteSync;
  bool cobrado;

  VentaEnVisita({
    required this.key,
    this.idVenta,
    this.uuidOffline,
    this.monto = 0,
    this.cantidadLineas = 0,
    this.esSocial = false,
    this.draft,
    this.pendienteSync = false,
    this.cobrado = false,
  });

  bool get referenciable =>
      idVenta != null || (uuidOffline != null && uuidOffline!.isNotEmpty);

  String get etiqueta => esSocial ? 'Venta Social' : 'Venta';

  factory VentaEnVisita.fromResponseJson(Map<String, dynamic> json) {
    final detalles = (json['detalles'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();
    final esSocial = detalles
        .any((d) => (d['tipoVenta'] ?? '').toString().toUpperCase() == 'SOCIAL');
    final idVenta = parseInt(json['idVenta']);
    final lineas = detalles.map(_lineaDesdeDetalle).whereType<DetalleVentaDraft>().toList();
    return VentaEnVisita(
      key: 'srv-${idVenta ?? json['idVenta']}',
      idVenta: idVenta,
      monto: parseInt(json['montoTotal']) ?? 0,
      cantidadLineas: detalles.length,
      esSocial: esSocial,
      draft: lineas.isEmpty ? null : VentaDraft(lineas: lineas),
      cobrado: json['cobrosAprobados'] == true,
    );
  }

  static DetalleVentaDraft? _lineaDesdeDetalle(Map<String, dynamic> detalle) {
    final tipo = tipoOperacionDesdeBackend(detalle['tipoVenta']?.toString());
    if (tipo == null) return null;
    final snapshot = detalle['productoSnapshot'] is Map<String, dynamic>
        ? detalle['productoSnapshot'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final idProducto = (detalle['idProducto'] ?? '').toString();
    final sku = (snapshot['sku'] ?? idProducto).toString();
    final descripcion = (snapshot['descripcion'] ?? '').toString();
    final kg = kgDesdeTexto(descripcion) ?? kgDesdeTexto(sku) ?? 0;
    return DetalleVentaDraft(
      producto: ProductoSku(
        idProducto: idProducto,
        sku: sku,
        descripcion: descripcion.isNotEmpty ? descripcion : (kg > 0 ? 'Garrafa $kg kg' : sku),
        kg: kg,
        precioUnitario: parseInt(detalle['precioUnitario']) ?? 0,
        tipoProducto: (snapshot['tipo_producto'] ?? 'GARRAFA').toString(),
      ),
      tipoOperacion: tipo,
      cantidadEntregada: parseInt(detalle['cantidadEntregada']) ?? 0,
      cantidadRecibida: parseInt(detalle['cantidadRecibida']) ?? 0,
    );
  }
}
