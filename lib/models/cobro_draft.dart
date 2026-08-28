import 'metodo_pago.dart';

class CobroDraft {
  /// PK de la venta cuando ya fue confirmada por el servidor.
  final int? idVenta;

  /// UUID offline de la venta cuando todavía no sincronizó. Exactamente uno
  /// entre [idVenta] y [uuidVentaOffline] debe estar presente.
  final String? uuidVentaOffline;
  final MetodoPago metodo;
  final int monto;
  final DateTime timestampCobro;

  const CobroDraft({
    this.idVenta,
    this.uuidVentaOffline,
    required this.metodo,
    required this.monto,
    required this.timestampCobro,
  });
}

class CobroResultado {
  final CobroDraft cobro;
  final bool pendienteSync;

  const CobroResultado({required this.cobro, required this.pendienteSync});
}
