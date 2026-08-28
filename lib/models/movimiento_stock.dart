import '../utils/json_parsing.dart';

class MovimientoStock {
  final int id;
  final String tipoMovimiento;
  final String productoSku;
  final String productoDescripcion;
  final int cantidad;
  final String usuario;
  final String? usuarioNombre;
  final String? repartidorNombre;
  final DateTime? fecha;
  final String? observaciones;
  final String? origenNombre;
  final String? destinoNombre;

  const MovimientoStock({
    required this.id,
    required this.tipoMovimiento,
    required this.productoSku,
    required this.productoDescripcion,
    required this.cantidad,
    required this.usuario,
    this.usuarioNombre,
    this.repartidorNombre,
    this.fecha,
    this.observaciones,
    this.origenNombre,
    this.destinoNombre,
  });

  bool get esCarga => tipoMovimiento.toUpperCase() == 'CARGA_CAMION';

  String get operador =>
      (usuarioNombre != null && usuarioNombre!.isNotEmpty) ? usuarioNombre! : usuario;

  String? get chofer =>
      (repartidorNombre != null && repartidorNombre!.isNotEmpty) ? repartidorNombre : null;

  factory MovimientoStock.fromJson(Map<String, dynamic> json) {
    final producto = json['producto'];
    final origen = json['depositoOrigen'];
    final destino = json['depositoDestino'];
    return MovimientoStock(
      id: parseInt(json['id']) ?? 0,
      tipoMovimiento: (json['tipoMovimiento'] ?? '').toString(),
      productoSku: producto is Map<String, dynamic>
          ? (producto['sku'] ?? producto['id'] ?? '').toString()
          : '',
      productoDescripcion: producto is Map<String, dynamic>
          ? (producto['descripcion'] ?? '').toString()
          : '',
      cantidad: parseInt(json['cantidad']) ?? 0,
      usuario: (json['usuario'] ?? '').toString(),
      usuarioNombre: json['usuarioNombre']?.toString(),
      repartidorNombre: json['repartidorNombre']?.toString(),
      fecha: parseDate(json['fecha']),
      observaciones: json['observaciones']?.toString(),
      origenNombre:
          origen is Map<String, dynamic> ? origen['nombre']?.toString() : null,
      destinoNombre:
          destino is Map<String, dynamic> ? destino['nombre']?.toString() : null,
    );
  }
}
