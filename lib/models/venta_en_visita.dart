import '../utils/json_parsing.dart';
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
    return VentaEnVisita(
      key: 'srv-${idVenta ?? json['idVenta']}',
      idVenta: idVenta,
      monto: parseInt(json['montoTotal']) ?? 0,
      cantidadLineas: detalles.length,
      esSocial: esSocial,
      cobrado: json['cobrosAprobados'] == true,
    );
  }
}
