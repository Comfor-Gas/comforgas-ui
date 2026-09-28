int? kgDesdeTexto(String? texto) {
  if (texto == null || texto.isEmpty) return null;
  final match = RegExp(r'\d+').firstMatch(texto);
  if (match == null) return null;
  return int.tryParse(match.group(0)!);
}

bool _mismoCodigo(String a, String b) =>
    a.isNotEmpty && b.isNotEmpty && a.trim().toUpperCase() == b.trim().toUpperCase();

T? buscarGarrafa<T>(
  Iterable<T> items, {
  required String idProducto,
  required String sku,
  int? kg,
  required String Function(T item) idDe,
  required String Function(T item) skuDe,
  required int? Function(T item) kgDe,
}) {
  for (final item in items) {
    if (_mismoCodigo(idDe(item), idProducto) || _mismoCodigo(skuDe(item), idProducto)) {
      return item;
    }
  }
  for (final item in items) {
    if (_mismoCodigo(idDe(item), sku) || _mismoCodigo(skuDe(item), sku)) {
      return item;
    }
  }
  if (kg != null && kg > 0) {
    for (final item in items) {
      if (kgDe(item) == kg) return item;
    }
  }
  return null;
}
