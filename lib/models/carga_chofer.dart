class CargaChoferLinea {
  final String etiqueta;
  final int cantidad;

  const CargaChoferLinea({required this.etiqueta, required this.cantidad});
}

class CargaChofer {
  final DateTime? fecha;
  final String? folio;
  final bool inicial;
  final List<CargaChoferLinea> lineas;

  const CargaChofer({
    this.fecha,
    this.folio,
    this.inicial = false,
    this.lineas = const [],
  });

  int get total => lineas.fold(0, (a, l) => a + l.cantidad);
}
