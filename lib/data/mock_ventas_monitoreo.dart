import '../models/venta_monitoreo.dart';

DetalleVentaMonitoreo _detalle({
  required int kg,
  required int entregada,
  required int recibida,
  required int precio,
  String tipo = 'VACIO_X_LLENO',
}) {
  return DetalleVentaMonitoreo(
    idProducto: 'GLP-${kg}KG',
    sku: '${kg}kg GLP',
    descripcion: '${kg}kg Gas GLP',
    kg: kg,
    tipoVenta: tipo,
    cantidadEntregada: entregada,
    cantidadRecibida: recibida,
    precioUnitario: precio,
  );
}

VentasMonitoreoDia ventasMonitoreoDeEjemplo(DateTime fecha) {
  final base = DateTime(fecha.year, fecha.month, fecha.day);

  final ventas = <VentaMonitoreo>[
    VentaMonitoreo(
      idVenta: 12333,
      idVisita: 1,
      timestamp: base.add(const Duration(hours: 14, minutes: 30)),
      choferNombre: 'chofer0',
      clienteNombre: 'García, Juan',
      estado: EstadoVentaMonitoreo.efectuada,
      montoTotal: 240000,
      detalles: [
        _detalle(kg: 10, entregada: 5, recibida: 5, precio: 48000),
      ],
    ),
    VentaMonitoreo(
      idVenta: 12331,
      idVisita: 2,
      timestamp: base.add(const Duration(hours: 11, minutes: 5)),
      choferNombre: 'chofer0',
      clienteNombre: 'García, Juan',
      estado: EstadoVentaMonitoreo.efectuada,
      montoTotal: 240000,
      detalles: [
        _detalle(kg: 10, entregada: 5, recibida: 5, precio: 24000),
        _detalle(kg: 10, entregada: 5, recibida: 5, precio: 24000),
      ],
    ),
    VentaMonitoreo(
      idVenta: 12332,
      idVisita: 3,
      timestamp: base.add(const Duration(hours: 9, minutes: 45)),
      choferNombre: 'chofer1',
      clienteNombre: 'Sosa, Marta',
      estado: EstadoVentaMonitoreo.pendiente,
      montoTotal: 120000,
      detalles: [
        _detalle(kg: 10, entregada: 5, recibida: 4, precio: 24000),
      ],
    ),
    VentaMonitoreo(
      idVenta: 12363,
      idVisita: 4,
      timestamp: base.add(const Duration(hours: 16, minutes: 20)),
      choferNombre: 'chofer1',
      clienteNombre: 'Benítez, Raúl',
      estado: EstadoVentaMonitoreo.efectuada,
      montoTotal: 90000,
      detalles: [
        _detalle(kg: 15, entregada: 3, recibida: 3, precio: 30000),
      ],
    ),
    VentaMonitoreo(
      idVenta: 12354,
      idVisita: 5,
      timestamp: base.add(const Duration(hours: 10, minutes: 15)),
      choferNombre: 'chofer2',
      clienteNombre: 'Ojeda, Lucía',
      estado: EstadoVentaMonitoreo.efectuada,
      montoTotal: 200000,
      detalles: [
        _detalle(kg: 10, entregada: 4, recibida: 0, precio: 25000, tipo: 'PRESTAMO'),
        _detalle(kg: 10, entregada: 4, recibida: 4, precio: 25000),
      ],
    ),
    VentaMonitoreo(
      idVenta: 12325,
      idVisita: 6,
      timestamp: base.add(const Duration(hours: 12, minutes: 40)),
      choferNombre: 'chofer2',
      clienteNombre: 'Ramírez, Diego',
      estado: EstadoVentaMonitoreo.cancelada,
      montoTotal: 48000,
      detalles: [
        _detalle(kg: 10, entregada: 1, recibida: 1, precio: 48000),
      ],
    ),
    VentaMonitoreo(
      idVenta: 12339,
      idVisita: 7,
      timestamp: base.add(const Duration(hours: 8, minutes: 55)),
      choferNombre: 'chofer0',
      clienteNombre: 'García, Juan',
      estado: EstadoVentaMonitoreo.efectuada,
      montoTotal: 144000,
      detalles: [
        _detalle(kg: 10, entregada: 3, recibida: 3, precio: 48000),
      ],
    ),
    VentaMonitoreo(
      idVenta: 12330,
      idVisita: 8,
      timestamp: base.add(const Duration(hours: 13, minutes: 10)),
      choferNombre: 'chofer3',
      clienteNombre: 'Cabrera, Ana',
      estado: EstadoVentaMonitoreo.pendiente,
      montoTotal: 180000,
      detalles: [
        _detalle(kg: 45, entregada: 2, recibida: 2, precio: 90000),
      ],
    ),
  ];

  final total = ventas
      .where((v) => v.estado != EstadoVentaMonitoreo.cancelada)
      .fold(0, (acc, v) => acc + v.montoTotal);

  return VentasMonitoreoDia(fecha: base, montoTotal: total, ventas: ventas);
}
