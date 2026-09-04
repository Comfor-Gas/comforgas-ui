import 'detalle_venta_draft.dart';
import 'tipo_operacion_venta.dart';

class VentaDraft {
  final List<DetalleVentaDraft> lineas;

  VentaDraft({List<DetalleVentaDraft>? lineas}) : lineas = lineas ?? [];

  int get montoTotal =>
      lineas.fold(0, (total, linea) => total + linea.subtotal);

  bool get vacio => lineas.isEmpty;

  bool get hayInconsistencias => lineas.any((linea) => !linea.esValido);

  bool get puedeGuardar => !vacio && !hayInconsistencias;

  bool contieneProducto(String idProducto) =>
      lineas.any((linea) => linea.producto.idProducto == idProducto);

  int _indexDe(String idProducto, TipoOperacionVenta tipo) =>
      lineas.indexWhere((linea) =>
          linea.producto.idProducto == idProducto &&
          linea.tipoOperacion == tipo);

  DetalleVentaDraft? buscar(String idProducto, TipoOperacionVenta tipo) {
    final index = _indexDe(idProducto, tipo);
    return index >= 0 ? lineas[index] : null;
  }

  void guardarLinea(DetalleVentaDraft linea) {
    final index = _indexDe(linea.producto.idProducto, linea.tipoOperacion);
    if (index >= 0) {
      lineas[index] = linea;
    } else {
      lineas.add(linea);
    }
  }

  void eliminarLinea(DetalleVentaDraft linea) {
    final index = _indexDe(linea.producto.idProducto, linea.tipoOperacion);
    if (index >= 0) lineas.removeAt(index);
  }

  Map<String, dynamic> toRequestJson(int idVisita) {
    return {
      'idVisita': idVisita,
      'items': lineas.map((linea) => linea.toRequestJson()).toList(),
    };
  }
}
