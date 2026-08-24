import '../utils/json_parsing.dart';

enum EstadoVentaMonitoreo { efectuada, pendiente, cancelada, desconocido }

extension EstadoVentaMonitoreoX on EstadoVentaMonitoreo {
  String get label {
    switch (this) {
      case EstadoVentaMonitoreo.efectuada:
        return 'Efectuada';
      case EstadoVentaMonitoreo.pendiente:
        return 'Pendiente';
      case EstadoVentaMonitoreo.cancelada:
        return 'Cancelada';
      case EstadoVentaMonitoreo.desconocido:
        return 'Desconocido';
    }
  }
}

class EstadoVentaMonitoreoMapper {
  const EstadoVentaMonitoreoMapper._();

  static EstadoVentaMonitoreo fromBackend(dynamic value) {
    switch ((value ?? '').toString().toUpperCase()) {
      case 'COMPLETADA':
      case 'EFECTUADA':
        return EstadoVentaMonitoreo.efectuada;
      case 'PENDIENTE':
        return EstadoVentaMonitoreo.pendiente;
      case 'CANCELADO':
      case 'CANCELADA':
        return EstadoVentaMonitoreo.cancelada;
      default:
        return EstadoVentaMonitoreo.desconocido;
    }
  }

  static const List<EstadoVentaMonitoreo> filtrables = [
    EstadoVentaMonitoreo.efectuada,
    EstadoVentaMonitoreo.pendiente,
    EstadoVentaMonitoreo.cancelada,
  ];
}

class DetalleVentaMonitoreo {
  final String idProducto;
  final String sku;
  final String descripcion;
  final int kg;
  final String tipoVenta;
  final int cantidadEntregada;
  final int cantidadRecibida;
  final int precioUnitario;

  const DetalleVentaMonitoreo({
    required this.idProducto,
    required this.sku,
    required this.descripcion,
    required this.kg,
    required this.tipoVenta,
    required this.cantidadEntregada,
    required this.cantidadRecibida,
    required this.precioUnitario,
  });

  int get subtotal => precioUnitario * cantidadEntregada;

  bool get usaRecibidos => tipoVenta.toUpperCase() != 'PRESTAMO';

  String get etiquetaEnvase => kg > 0 ? '${kg}kg' : sku;

  String get tipoLabel {
    switch (tipoVenta.toUpperCase()) {
      case 'VACIO_X_LLENO':
        return 'Vacío x Lleno';
      case 'PRESTAMO':
        return 'Préstamo';
      case 'ENVASE':
        return 'Envase';
      case 'SOCIAL':
        return 'Social';
      default:
        return tipoVenta;
    }
  }

  bool get consistente {
    switch (tipoVenta.toUpperCase()) {
      case 'VACIO_X_LLENO':
        return cantidadEntregada == cantidadRecibida;
      case 'PRESTAMO':
        return cantidadRecibida == 0;
      default:
        return true;
    }
  }

  factory DetalleVentaMonitoreo.fromJson(Map<String, dynamic> json) {
    final snapshot = json['productoSnapshot'];
    final snapshotMap =
        snapshot is Map ? snapshot.cast<String, dynamic>() : const <String, dynamic>{};

    final skuRaw = (json['sku'] ??
            snapshotMap['sku'] ??
            json['idProducto'] ??
            '')
        .toString();
    final descripcion = (snapshotMap['descripcion'] ?? json['descripcion'] ?? skuRaw)
        .toString();

    return DetalleVentaMonitoreo(
      idProducto: (json['idProducto'] ?? skuRaw).toString(),
      sku: skuRaw,
      descripcion: descripcion,
      kg: _extraerKg('$skuRaw $descripcion'),
      tipoVenta: (json['tipoVenta'] ?? '').toString(),
      cantidadEntregada: parseInt(json['cantidadEntregada']) ?? 0,
      cantidadRecibida: parseInt(json['cantidadRecibida']) ?? 0,
      precioUnitario: parseInt(json['precioUnitario']) ??
          (parseDouble(json['precioUnitario'])?.round() ?? 0),
    );
  }

  static int _extraerKg(String texto) {
    final match = RegExp(r'(\d+)\s*kg', caseSensitive: false).firstMatch(texto);
    if (match != null) return int.tryParse(match.group(1) ?? '') ?? 0;
    return 0;
  }
}

class VentaMonitoreo {
  final int idVenta;
  final int? idVisita;
  final DateTime? timestamp;
  final String choferNombre;
  final String clienteNombre;
  final EstadoVentaMonitoreo estado;
  final int montoTotal;
  final List<DetalleVentaMonitoreo> detalles;

  const VentaMonitoreo({
    required this.idVenta,
    required this.idVisita,
    required this.timestamp,
    required this.choferNombre,
    required this.clienteNombre,
    required this.estado,
    required this.montoTotal,
    required this.detalles,
  });

  int get totalEntregados =>
      detalles.fold(0, (acc, d) => acc + d.cantidadEntregada);

  int get totalRecibidos =>
      detalles.fold(0, (acc, d) => acc + d.cantidadRecibida);

  bool get consistente =>
      detalles.isNotEmpty && detalles.every((d) => d.consistente);

  factory VentaMonitoreo.fromJson(Map<String, dynamic> json) {
    final chofer = json['chofer'];
    final choferMap =
        chofer is Map ? chofer.cast<String, dynamic>() : const <String, dynamic>{};
    final cliente = json['cliente'];
    final clienteMap =
        cliente is Map ? cliente.cast<String, dynamic>() : const <String, dynamic>{};

    final detallesRaw = json['detalles'];
    final detalles = detallesRaw is List
        ? detallesRaw
            .whereType<Map>()
            .map((e) => DetalleVentaMonitoreo.fromJson(e.cast<String, dynamic>()))
            .toList()
        : <DetalleVentaMonitoreo>[];

    final monto = parseInt(json['montoTotal']) ??
        (parseDouble(json['montoTotal'])?.round() ??
            detalles.fold<int>(0, (acc, d) => acc + d.subtotal));

    return VentaMonitoreo(
      idVenta: parseInt(json['idVenta']) ?? 0,
      idVisita: parseInt(json['idVisita']),
      timestamp: parseDate(json['timestampVenta'] ?? json['fechaHora'] ?? json['hora']),
      choferNombre: (choferMap['nombre'] ??
              json['nombreChofer'] ??
              json['choferNombre'] ??
              json['chofer'] ??
              'Sin chofer')
          .toString(),
      clienteNombre: (clienteMap['nombre'] ??
              json['nombreCliente'] ??
              json['clienteNombre'] ??
              json['cliente'] ??
              'Sin cliente')
          .toString(),
      estado: EstadoVentaMonitoreoMapper.fromBackend(json['estadoVenta'] ?? json['estado']),
      montoTotal: monto,
      detalles: detalles,
    );
  }
}

class VentasMonitoreoDia {
  final DateTime fecha;
  final int montoTotal;
  final List<VentaMonitoreo> ventas;

  const VentasMonitoreoDia({
    required this.fecha,
    required this.montoTotal,
    required this.ventas,
  });

  factory VentasMonitoreoDia.fromJson(Map<String, dynamic> json) {
    final ventasRaw = json['ventas'];
    final ventas = ventasRaw is List
        ? ventasRaw
            .whereType<Map>()
            .map((e) => VentaMonitoreo.fromJson(e.cast<String, dynamic>()))
            .toList()
        : <VentaMonitoreo>[];

    final monto = parseInt(json['montoTotal']) ??
        (parseDouble(json['montoTotal'])?.round() ??
            ventas.fold<int>(0, (acc, v) => acc + v.montoTotal));

    return VentasMonitoreoDia(
      fecha: parseDate(json['fecha']) ?? DateTime.now(),
      montoTotal: monto,
      ventas: ventas,
    );
  }
}
