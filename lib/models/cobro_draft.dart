import 'metodo_pago.dart';

class CobroDraft {
  final int idVenta;
  final MetodoPago metodo;
  final int monto;
  final DateTime timestampCobro;

  const CobroDraft({
    required this.idVenta,
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
