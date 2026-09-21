import 'producto_sku.dart';
import 'tipo_operacion_venta.dart';

class DetalleVentaDraft {
  final ProductoSku producto;
  TipoOperacionVenta tipoOperacion;
  int cantidadEntregada;
  int cantidadRecibida;

  DetalleVentaDraft({
    required this.producto,
    required this.tipoOperacion,
    this.cantidadEntregada = 0,
    this.cantidadRecibida = 0,
  });

  DetalleVentaDraft copy() {
    return DetalleVentaDraft(
      producto: producto,
      tipoOperacion: tipoOperacion,
      cantidadEntregada: cantidadEntregada,
      cantidadRecibida: cantidadRecibida,
    );
  }

  int get subtotal => producto.precioUnitario * cantidadEntregada;

  bool get concordanciaValida =>
      tipoOperacion.concordanciaValida(cantidadEntregada, cantidadRecibida);

  bool get tieneMovimiento => cantidadEntregada > 0 || cantidadRecibida > 0;

  bool get esValido => concordanciaValida && tieneMovimiento;

  String? get mensajeError {
    if (!tieneMovimiento) {
      return 'Ingresá al menos una unidad para registrar el movimiento.';
    }
    return tipoOperacion.mensajeInconsistencia(
      cantidadEntregada,
      cantidadRecibida,
    );
  }

  Map<String, dynamic> toRequestJson() {
    return {
      'idProducto': producto.idProducto,
      'productoSnapshot': producto.toSnapshot(),
      'tipoVenta': tipoOperacion.backendValue,
      'cantidadEntregada': cantidadEntregada,
      'cantidadRecibida': tipoOperacion.usaRecibidos ? cantidadRecibida : 0,
      'precioUnitario': producto.precioUnitario,
      'inconsistente': !concordanciaValida,
    };
  }
}
