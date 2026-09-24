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

class ArqueoCategoriaTotal {
  final String categoria;
  final int total;
  final int totalOnline;
  final int totalSincronizadoDiferido;
  final int cantidad;

  const ArqueoCategoriaTotal({
    required this.categoria,
    this.total = 0,
    this.totalOnline = 0,
    this.totalSincronizadoDiferido = 0,
    this.cantidad = 0,
  });

  factory ArqueoCategoriaTotal.fromJson(Map<String, dynamic> json) {
    return ArqueoCategoriaTotal(
      categoria: (json['categoria'] ?? '').toString(),
      total: parseInt(json['total']) ?? 0,
      totalOnline: parseInt(json['totalOnline']) ?? 0,
      totalSincronizadoDiferido: parseInt(json['totalSincronizadoDiferido']) ?? 0,
      cantidad: parseInt(json['cantidadCobros']) ?? 0,
    );
  }
}

class ArqueoNotaDebito {
  final int idNotaDebito;
  final int? idVenta;
  final int? idClienteExt;
  final String? nombreCliente;
  final String idProducto;
  final String? descripcionProducto;
  final int cantidadAdeudada;
  final String estado;

  const ArqueoNotaDebito({
    required this.idNotaDebito,
    this.idVenta,
    this.idClienteExt,
    this.nombreCliente,
    required this.idProducto,
    this.descripcionProducto,
    this.cantidadAdeudada = 0,
    this.estado = '',
  });

  bool get pendiente => estado.toUpperCase() == 'PENDIENTE';

  String get clienteMostrable {
    final nombre = nombreCliente?.trim();
    if (nombre != null && nombre.isNotEmpty) return nombre;
    if (idClienteExt != null) return 'Cliente #$idClienteExt';
    return 'Sin cliente';
  }

  String get productoMostrable {
    final desc = descripcionProducto?.trim();
    if (desc != null && desc.isNotEmpty) return desc;
    return idProducto.isNotEmpty ? idProducto : 'Producto';
  }

  factory ArqueoNotaDebito.fromJson(Map<String, dynamic> json) {
    return ArqueoNotaDebito(
      idNotaDebito: parseInt(json['idNotaDebito']) ?? 0,
      idVenta: parseInt(json['idVenta']),
      idClienteExt: parseInt(json['idClienteExt']),
      nombreCliente: (json['nombreCliente'] as String?)?.trim(),
      idProducto: (json['idProducto'] ?? '').toString(),
      descripcionProducto: (json['descripcionProducto'] as String?)?.trim(),
      cantidadAdeudada: parseInt(json['cantidadAdeudada']) ?? 0,
      estado: (json['estado'] ?? '').toString(),
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
  final List<ArqueoCategoriaTotal> totalesPorCategoria;
  final List<ArqueoNotaDebito> notasDebito;

  /// Estado del cierre (viene del backend). Si [cerrado] es true, el arqueo ya
  /// fue auditado y no debe volver a cerrarse.
  final bool cerrado;
  final String? correlativo;
  final DateTime? cerradoEn;
  final int efectivoDeclarado;
  final int chequeDeclarado;
  final int transferenciaDeclarada;

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
    this.totalesPorCategoria = const [],
    this.notasDebito = const [],
    this.cerrado = false,
    this.correlativo,
    this.cerradoEn,
    this.efectivoDeclarado = 0,
    this.chequeDeclarado = 0,
    this.transferenciaDeclarada = 0,
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
      totalesPorCategoria: (json['totalesPorCategoria'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ArqueoCategoriaTotal.fromJson)
          .toList(),
      notasDebito: (json['notasDebito'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ArqueoNotaDebito.fromJson)
          .toList(),
      cerrado: json['cerrado'] == true,
      correlativo: json['correlativo']?.toString(),
      cerradoEn: parseDate(json['cerradoAt']),
      efectivoDeclarado: parseInt(json['efectivoDeclarado']) ?? 0,
      chequeDeclarado: parseInt(json['chequeDeclarado']) ?? 0,
      transferenciaDeclarada: parseInt(json['transferenciaDeclarada']) ?? 0,
    );
  }

  int _totalCategoria(String categoria) {
    for (final c in totalesPorCategoria) {
      if (c.categoria.toUpperCase() == categoria) return c.total;
    }
    return 0;
  }

  int get totalVentaSocial => _totalCategoria('SOCIAL');

  int get totalPrestamos => _totalCategoria('PRESTAMO');

  int get garrafasAdeudadas =>
      notasDebito.fold(0, (a, n) => a + n.cantidadAdeudada);

  int get notasDebitoPendientes =>
      notasDebito.where((n) => n.pendiente).length;
}
