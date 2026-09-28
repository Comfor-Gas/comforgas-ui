class VentaPreviaResumen {
  final String etiqueta;
  final int monto;
  final String? detalle;

  const VentaPreviaResumen({
    required this.etiqueta,
    required this.monto,
    this.detalle,
  });
}
