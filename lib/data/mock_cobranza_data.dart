import '../models/arqueo_caja.dart';
import '../models/cuenta_corriente_resumen.dart';

ArqueoCaja arqueoDeEjemplo({
  required String idUsuario,
  required String nombre,
  required DateTime fecha,
}) {
  final base = DateTime(fecha.year, fecha.month, fecha.day, 14, 30);
  return ArqueoCaja(
    idUsuario: idUsuario,
    nombreUsuario: nombre.isNotEmpty ? nombre : 'chofer0',
    fecha: fecha,
    totalGeneral: 336000,
    totalRendicion: 336000,
    totalCuentaCorriente: 0,
    cantidadCobros: 2,
    totalesPorMetodo: const [
      ArqueoMetodoTotal(metodoPago: 'EFECTIVO', total: 240000, cantidad: 1),
      ArqueoMetodoTotal(metodoPago: 'CHEQUE', total: 96000, cantidad: 1),
      ArqueoMetodoTotal(metodoPago: 'TRANSFERENCIA', total: 0, cantidad: 0),
    ],
    movimientos: [
      ArqueoMovimiento(
        idCobro: 1,
        idVenta: 1234,
        nombreCliente: 'García, Juan',
        metodoPago: 'EFECTIVO',
        monto: 240000,
        estadoCobro: 'PAGO_APROBADO',
        horaFisica: base.add(const Duration(minutes: 0, seconds: 15)),
        horaSincro: base.add(const Duration(minutes: 15, seconds: 2)),
        origen: 'SINCRONIZADO_DIFERIDO',
      ),
      ArqueoMovimiento(
        idCobro: 2,
        idVenta: 1235,
        nombreCliente: 'García, Juan',
        metodoPago: 'CHEQUE',
        monto: 96000,
        estadoCobro: 'PAGO_PENDIENTE',
        horaFisica: base.add(const Duration(minutes: 40, seconds: 10)),
        horaSincro: base.add(const Duration(minutes: 40, seconds: 20)),
        origen: 'ONLINE',
      ),
    ],
  );
}

ReporteCuentasCorrientes reporteCuentasDeEjemplo() {
  return const ReporteCuentasCorrientes(
    totalDeuda: 620000,
    clientesMorosos: 2,
    totalClientes: 3,
    clientes: [
      CuentaCorrienteResumen(
        idCliente: 101,
        nombreCliente: 'García, Juan',
        moroso: true,
        limiteCredito: 240000,
        saldoUsado: 260000,
        montoVencido: 20000,
      ),
      CuentaCorrienteResumen(
        idCliente: 102,
        nombreCliente: 'Pérez, Ana',
        moroso: true,
        limiteCredito: 150000,
        saldoUsado: 180000,
        montoVencido: 30000,
      ),
      CuentaCorrienteResumen(
        idCliente: 103,
        nombreCliente: 'Distribuidora Sur',
        moroso: false,
        limiteCredito: 500000,
        saldoUsado: 180000,
        montoVencido: 0,
      ),
    ],
  );
}
