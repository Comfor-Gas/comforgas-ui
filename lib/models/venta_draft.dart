import 'detalle_venta_draft.dart';

class VentaDraft {
  final List<DetalleVentaDraft> lineas;

  VentaDraft({List<DetalleVentaDraft>? lineas}) : lineas = lineas ?? [];

  int get montoTotal =>
      lineas.fold(0, (total, linea) => total + linea.subtotal);

  bool get vacio => lineas.isEmpty;

  bool get hayInconsistencias => lineas.any((linea) => !linea.esValido);

  bool get puedeGuardar => !vacio && !hayInconsistencias;

  int indexDe(String idProducto) =>
      lineas.indexWhere((linea) => linea.producto.idProducto == idProducto);

  void guardarLinea(DetalleVentaDraft linea) {
    final index = indexDe(linea.producto.idProducto);
    if (index >= 0) {
      lineas[index] = linea;
    } else {
      lineas.add(linea);
    }
  }

  void eliminar(String idProducto) {
    lineas.removeWhere((linea) => linea.producto.idProducto == idProducto);
  }

  Map<String, dynamic> toRequestJson(int idVisita) {
    return {
      'idVisita': idVisita,
      'items': lineas.map((linea) => linea.toRequestJson()).toList(),
    };
  }
}
