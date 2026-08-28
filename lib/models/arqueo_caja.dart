import '../utils/json_parsing.dart';

class ArqueoMovimiento {
  final int idCobro;
  final int? idVenta;
  final String nombreCliente;
  final String metodoPago;
  final int monto;
  final String estadoCobro;
  final DateTime? horaFisica;
  final DateTime? horaSincro;
  final String origen;

  const ArqueoMovimiento({
    required this.idCobro,
    this.idVenta,
    required this.nombreCliente,
    required this.metodoPago,
    required this.monto,
    required this.estadoCobro,
    this.horaFisica,
    this.horaSincro,
    required this.origen,
  });

  bool get esDiferido => origen.toUpperCase().contains('DIFERIDO');

  int get desfaseSegundos {
    if (horaFisica == null || horaSincro == null) return 0;
    return horaSincro!.difference(horaFisica!).inSeconds.abs();
  }

  factory ArqueoMovimiento.fromJson(Map<String, dynamic> json) {
    return ArqueoMovimiento(
      idCobro: parseInt(json['idCobro']) ?? 0,
      idVenta: parseInt(json['idVenta']),
      nombreCliente: (json['nombreCliente'] ?? '').toString(),
      metodoPago: (json['metodoPago'] ?? '').toString(),
      monto: parseInt(json['montoCobrado']) ?? 0,
      estadoCobro: (json['estadoCobro'] ?? '').toString(),
      horaFisica: parseDate(json['timestampCobro']),
      horaSincro: parseDate(json['createdAt']),
      origen: (json['origen'] ?? '').toString(),
    );
  }
}

class ArqueoMetodoTotal {
  final String metodoPago;
  final int total;
  final int cantidad;

  const ArqueoMetodoTotal({
    required this.metodoPago,
    required this.total,
    required this.cantidad,
  });

  factory ArqueoMetodoTotal.fromJson(Map<String, dynamic> json) {
    return ArqueoMetodoTotal(
      metodoPago: (json['metodoPago'] ?? '').toString(),
      total: parseInt(json['total']) ?? 0,
      cantidad: parseInt(json['cantidad']) ?? 0,
    );
  }
}

class ArqueoCaja {
  final String idUsuario;
  final String nombreUsuario;
  final DateTime? fecha;
  final int totalGeneral;
  final int totalRendicion;
  final int totalCuentaCorriente;
  final int cantidadCobros;
  final List<ArqueoMetodoTotal> totalesPorMetodo;
  final List<ArqueoMovimiento> movimientos;

  const ArqueoCaja({
    required this.idUsuario,
    required this.nombreUsuario,
    this.fecha,
    this.totalGeneral = 0,
    this.totalRendicion = 0,
    this.totalCuentaCorriente = 0,
    this.cantidadCobros = 0,
    this.totalesPorMetodo = const [],
    this.movimientos = const [],
  });

  factory ArqueoCaja.fromJson(Map<String, dynamic> json) {
    return ArqueoCaja(
      idUsuario: (json['idUsuario'] ?? '').toString(),
      nombreUsuario: (json['nombreUsuario'] ?? '').toString(),
      fecha: parseDate(json['fecha']),
      totalGeneral: parseInt(json['totalGeneral']) ?? 0,
      totalRendicion: parseInt(json['totalRendicion']) ?? 0,
      totalCuentaCorriente: parseInt(json['totalCuentaCorriente']) ?? 0,
      cantidadCobros: parseInt(json['cantidadCobros']) ?? 0,
      totalesPorMetodo: (json['totalesPorMetodo'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ArqueoMetodoTotal.fromJson)
          .toList(),
      movimientos: (json['movimientos'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ArqueoMovimiento.fromJson)
          .toList(),
    );
  }
}
