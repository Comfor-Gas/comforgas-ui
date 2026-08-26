import 'visita_model.dart';
import '../utils/json_parsing.dart';

class ProductoSku {
  final String idProducto;
  final String sku;
  final String descripcion;
  final int kg;
  final int precioUnitario;
  final String tipoProducto;
  final int? stockDisponible;

  const ProductoSku({
    required this.idProducto,
    required this.sku,
    required this.descripcion,
    required this.kg,
    required this.precioUnitario,
    this.tipoProducto = 'GARRAFA',
    this.stockDisponible,
  });

  bool get controlaStock => stockDisponible != null;

  Map<String, dynamic> toSnapshot() {
    return {
      'sku': sku,
      'descripcion': descripcion,
      'precio': precioUnitario,
      'tipo_producto': tipoProducto,
    };
  }

  static List<ProductoSku> desdeVisita(VisitaModel visita) {
    final skus = <ProductoSku>[];
    precioPorKg(visita).forEach((kg, precio) {
      if (precio > 0) {
        skus.add(
          ProductoSku(
            idProducto: 'GARRAFA-$kg',
            sku: 'GARRAFA-$kg',
            descripcion: 'Garrafa $kg kg',
            kg: kg,
            precioUnitario: precio,
          ),
        );
      }
    });
    return skus;
  }

  static Map<int, int> precioPorKg(VisitaModel visita) {
    final snapshot = visita.sucursalSnapshot;
    final crudos = <int, int?>{
      10: parseInt(snapshot['precio10']),
      15: parseInt(snapshot['precio15']),
      30: parseInt(snapshot['precio30']),
      45: parseInt(snapshot['precio45']),
    };
    final precios = <int, int>{};
    crudos.forEach((kg, precio) {
      if (precio != null) precios[kg] = precio;
    });
    return precios;
  }
}
