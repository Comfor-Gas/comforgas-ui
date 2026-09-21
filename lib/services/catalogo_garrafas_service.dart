import '../models/producto_catalogo.dart';
import '../models/producto_sku.dart';
import '../models/stock_camion.dart';
import '../models/visita_model.dart';

class CatalogoGarrafasService {
  const CatalogoGarrafasService();

  List<ProductoSku> desdeStockYCatalogo(
    VisitaModel visita,
    StockCamion stock,
    List<ProductoCatalogo> productos,
  ) {
    final preciosSnapshot = ProductoSku.precioPorKg(visita);
    final porId = <String, ProductoCatalogo>{
      for (final p in productos) p.idProducto: p,
    };
    final porSku = <String, ProductoCatalogo>{
      for (final p in productos)
        if (p.sku.isNotEmpty) p.sku: p,
    };

    final catalogo = <ProductoSku>[];
    for (final item in stock.llenasDisponibles) {
      final prod = porId[item.productoId] ?? porSku[item.sku];
      final kg = _kgDe(item) ?? prod?.kgEntero;

      int precio = 0;
      if (prod != null && prod.precioUnitario > 0) {
        precio = prod.precioUnitario;
      } else if (kg != null && (preciosSnapshot[kg] ?? 0) > 0) {
        precio = preciosSnapshot[kg]!;
      }
      if (precio <= 0) continue;

      catalogo.add(
        ProductoSku(
          idProducto: item.productoId,
          sku: item.sku,
          descripcion: item.descripcion.isNotEmpty
              ? item.descripcion
              : (prod?.etiquetaKg ?? (kg != null ? 'Garrafa $kg kg' : item.sku)),
          kg: kg ?? 0,
          precioUnitario: precio,
          tipoProducto: 'GARRAFA',
          stockDisponible: item.cantidad,
        ),
      );
    }

    catalogo.sort((a, b) => a.kg.compareTo(b.kg));
    return catalogo;
  }

  List<ProductoSku> desdeStock(VisitaModel visita, StockCamion stock) {
    final precios = ProductoSku.precioPorKg(visita);
    final catalogo = <ProductoSku>[];

    for (final item in stock.llenasDisponibles) {
      final kg = _kgDe(item);
      if (kg == null) continue;
      final precio = precios[kg];
      if (precio == null || precio <= 0) continue;

      catalogo.add(
        ProductoSku(
          idProducto: item.productoId,
          sku: item.sku,
          descripcion: item.descripcion.isNotEmpty
              ? item.descripcion
              : 'Garrafa $kg kg',
          kg: kg,
          precioUnitario: precio,
          tipoProducto: 'GARRAFA',
          stockDisponible: item.cantidad,
        ),
      );
    }

    catalogo.sort((a, b) => a.kg.compareTo(b.kg));
    return catalogo;
  }

  List<ProductoSku> desdeStockParaCanje(StockCamion stock) {
    final catalogo = <ProductoSku>[];

    for (final item in stock.llenasDisponibles) {
      final kg = _kgDe(item) ?? 0;
      catalogo.add(
        ProductoSku(
          idProducto: item.productoId,
          sku: item.sku,
          descripcion: item.descripcion.isNotEmpty
              ? item.descripcion
              : (kg > 0 ? 'Garrafa $kg kg' : item.sku),
          kg: kg,
          precioUnitario: 0,
          tipoProducto: 'GARRAFA',
          stockDisponible: item.cantidad,
        ),
      );
    }

    catalogo.sort((a, b) => a.kg.compareTo(b.kg));
    return catalogo;
  }

  int? _kgDe(StockCamionItem item) {
    return _primerEntero(item.productoId) ??
        _primerEntero(item.sku) ??
        _primerEntero(item.descripcion);
  }

  int? _primerEntero(String texto) {
    final match = RegExp(r'\d+').firstMatch(texto);
    if (match == null) return null;
    return int.tryParse(match.group(0)!);
  }
}
