import 'tipo_operacion_venta.dart';
import 'venta_draft.dart';

class NotaDebitoItem {
  final String descripcion;
  final String sku;
  final int kg;
  final int cantidad;
  final int precioUnitario;

  const NotaDebitoItem({
    required this.descripcion,
    required this.sku,
    required this.kg,
    required this.cantidad,
    required this.precioUnitario,
  });

  int get subtotal => cantidad * precioUnitario;

  String get etiqueta {
    if (descripcion.trim().isNotEmpty) return descripcion.trim();
    if (kg > 0) return 'Garrafa $kg kg';
    return sku;
  }
}

class NotaDebitoResumen {
  final List<NotaDebitoItem> items;

  const NotaDebitoResumen(this.items);

  bool get vacio => items.isEmpty;

  int get totalGarrafas => items.fold(0, (a, i) => a + i.cantidad);

  int get totalMonto => items.fold(0, (a, i) => a + i.subtotal);

  factory NotaDebitoResumen.deVenta(VentaDraft? draft) {
    if (draft == null) return const NotaDebitoResumen([]);
    final items = <NotaDebitoItem>[];
    for (final l in draft.lineas) {
      if (l.tipoOperacion == TipoOperacionVenta.prestamo && l.cantidadEntregada > 0) {
        items.add(NotaDebitoItem(
          descripcion: l.producto.descripcion,
          sku: l.producto.sku,
          kg: l.producto.kg,
          cantidad: l.cantidadEntregada,
          precioUnitario: l.producto.precioUnitario,
        ));
      }
    }
    return NotaDebitoResumen(items);
  }
}
