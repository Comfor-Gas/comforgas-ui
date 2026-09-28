import '../models/producto_catalogo.dart';
import '../models/producto_sku.dart';
import '../models/stock_rodante_chofer.dart';
import '../models/visita_model.dart';
import '../utils/garrafa_match.dart';

class CatalogoGarrafasService {
  const CatalogoGarrafasService();

  ProductoCatalogo? _productoDeCatalogo(
    List<ProductoCatalogo> productos,
    StockRodanteProducto linea,
  ) {
    return buscarGarrafa<ProductoCatalogo>(
      productos,
      idProducto: linea.idProducto,
      sku: linea.sku,
      kg: linea.kg,
      idDe: (p) => p.idProducto,
      skuDe: (p) => p.sku,
      kgDe: (p) => p.kgEntero ?? kgDesdeTexto(p.sku),
    );
  }

  String _descripcion(ProductoCatalogo? prod, int kg, String codigo) {
    final desc = prod?.descripcion.trim() ?? '';
    if (desc.isNotEmpty) return desc;
    return kg > 0 ? 'Garrafa $kg kg' : codigo;
  }

  List<ProductoSku> desdeStockRodanteParaCanje(StockRodanteChofer stock) {
    final catalogo = <ProductoSku>[];
    for (final p in stock.ordenados) {
      final kg = p.kg ?? 0;
      catalogo.add(
        ProductoSku(
          idProducto: p.idProducto,
          sku: p.sku,
          descripcion: _descripcion(null, kg, p.sku),
          kg: kg,
          precioUnitario: 0,
          tipoProducto: 'GARRAFA',
          stockDisponible: p.disponiblesParaVenta,
        ),
      );
    }
    return catalogo;
  }

  List<ProductoSku> paraVentaDesdeNota(
    VisitaModel visita,
    StockRodanteChofer nota,
    List<ProductoCatalogo> productos,
  ) {
    final preciosAgenda = ProductoSku.precioPorKg(visita);
    final catalogo = <ProductoSku>[];
    for (final linea in nota.ordenados) {
      if (linea.llenosCargados <= 0 && linea.disponiblesParaVenta <= 0) continue;
      final prod = _productoDeCatalogo(productos, linea);
      final kg = prod?.kgEntero ?? linea.kg ?? 0;
      var precio = prod?.precioUnitario ?? 0;
      if (precio <= 0) precio = preciosAgenda[kg] ?? 0;
      if (precio <= 0) continue;
      final codigo = linea.idProducto.isNotEmpty ? linea.idProducto : linea.sku;
      catalogo.add(
        ProductoSku(
          idProducto: codigo,
          sku: linea.sku.isNotEmpty ? linea.sku : codigo,
          descripcion: _descripcion(prod, kg, codigo),
          kg: kg,
          precioUnitario: precio,
          tipoProducto: (prod?.tipoProducto.isNotEmpty ?? false) ? prod!.tipoProducto : 'GARRAFA',
          stockDisponible: linea.disponiblesParaVenta,
        ),
      );
    }
    return catalogo;
  }

  List<ProductoSku> sinControlDeStock(
    VisitaModel visita,
    List<ProductoCatalogo> productos,
  ) {
    if (productos.isEmpty) return ProductoSku.desdeVisita(visita);
    final preciosAgenda = ProductoSku.precioPorKg(visita);
    final catalogo = <ProductoSku>[];
    for (final prod in productos) {
      final kg = prod.kgEntero;
      if (kg == null) continue;
      var precio = prod.precioUnitario;
      if (precio <= 0) precio = preciosAgenda[kg] ?? 0;
      if (precio <= 0) continue;
      catalogo.add(
        ProductoSku(
          idProducto: prod.idProducto,
          sku: prod.sku.isNotEmpty ? prod.sku : prod.idProducto,
          descripcion: _descripcion(prod, kg, prod.idProducto),
          kg: kg,
          precioUnitario: precio,
          tipoProducto: prod.tipoProducto.isNotEmpty ? prod.tipoProducto : 'GARRAFA',
        ),
      );
    }
    catalogo.sort((a, b) => a.kg.compareTo(b.kg));
    return catalogo.isEmpty ? ProductoSku.desdeVisita(visita) : catalogo;
  }
}
