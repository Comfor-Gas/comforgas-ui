import '../models/movimiento_stock.dart';
import '../models/nota_control_stock.dart';
import '../models/nota_stock_movimiento.dart';
import '../models/producto_catalogo.dart';
import '../models/stock_rodante_chofer.dart';
import '../utils/garrafa_match.dart';

class NotaRodanteMapper {
  const NotaRodanteMapper();

  StockRodanteProducto? lineaDe(StockRodanteChofer? nota, ProductoCatalogo producto) {
    if (nota == null) return null;
    return nota.buscarProducto(
      idProducto: producto.idProducto,
      sku: producto.sku,
      kg: producto.kgEntero ?? kgDesdeTexto(producto.sku),
    );
  }

  Map<String, String> codigosPara(StockRodanteChofer? nota, ProductoCatalogo producto) {
    final linea = lineaDe(nota, producto);
    if (linea != null) {
      return {
        'idProducto': linea.idProducto.isNotEmpty ? linea.idProducto : linea.sku,
        'sku': linea.sku.isNotEmpty ? linea.sku : linea.idProducto,
      };
    }
    return {
      'idProducto': producto.idProducto,
      'sku': producto.sku.isNotEmpty ? producto.sku : producto.idProducto,
    };
  }

  ResumenCierreCamion resumenCierre(StockRodanteChofer? nota, List<ProductoCatalogo> productos) {
    if (nota == null) return const ResumenCierreCamion();
    final vendidas = <String, int>{};
    final llenos = <String, int>{};
    for (final producto in productos) {
      final linea = lineaDe(nota, producto);
      if (linea == null) continue;
      vendidas[producto.idProducto] = linea.totalVendidoLlenos;
      llenos[producto.idProducto] = linea.disponiblesParaVenta;
    }
    return ResumenCierreCamion(vendidasHoy: vendidas, stockLlenoActual: llenos);
  }

  List<Map<String, dynamic>> itemsRecarga(
    StockRodanteChofer? nota,
    List<ProductoCatalogo> productos,
    Map<String, int> cantidadPorProducto,
  ) {
    final items = <Map<String, dynamic>>[];
    for (final producto in productos) {
      final cantidad = cantidadPorProducto[producto.idProducto] ?? 0;
      if (cantidad <= 0) continue;
      items.add({...codigosPara(nota, producto), 'cantidad': cantidad});
    }
    return items;
  }

  List<Map<String, dynamic>> itemsCierre(StockRodanteChofer? nota, List<LineaStock> lineas) {
    final items = <Map<String, dynamic>>[];
    for (final l in lineas) {
      if (l.llenos <= 0 && l.vacios <= 0 && l.averiados <= 0) continue;
      items.add({
        ...codigosPara(nota, l.producto),
        'llenosEntrada': l.llenos,
        'vaciosEntrada': l.vacios,
        'averiadosEntrada': l.averiados,
      });
    }
    return items;
  }

  List<MovimientoStock> historialDesdeEventos(
    StockRodanteChofer nota,
    List<NotaStockMovimiento> eventos,
  ) {
    final movimientos = <MovimientoStock>[];
    var id = 0;
    for (final evento in eventos) {
      if (!evento.esCargaInicial && !evento.esRecarga) continue;
      final clave = evento.esCargaInicial ? 'llenosSalida' : 'recargaLlenos';
      final tipoTexto = evento.esCargaInicial ? 'Carga inicial de salida' : 'Recarga en ruta';
      for (final item in evento.items) {
        final cantidad = item[clave];
        if (cantidad is! num || cantidad <= 0) continue;
        final idProducto = (item['idProducto'] ?? '').toString();
        final sku = (item['sku'] ?? idProducto).toString();
        final linea = nota.buscarProducto(idProducto: idProducto, sku: sku);
        final kg = linea?.kg ?? kgDesdeTexto(sku);
        final etiqueta = kg != null ? 'Garrafa $kg kg' : sku;
        movimientos.add(MovimientoStock(
          id: ++id,
          tipoMovimiento: 'CARGA_CAMION',
          productoId: idProducto,
          productoSku: sku,
          productoDescripcion: etiqueta,
          cantidad: cantidad.toInt(),
          usuario: evento.nombreOperador ?? '',
          repartidorNombre: nota.nombreChofer,
          fecha: evento.fechaHora,
          folio: nota.numeroNota,
          observaciones: evento.observaciones != null
              ? '$tipoTexto · ${evento.observaciones}'
              : tipoTexto,
        ));
      }
    }
    return movimientos;
  }

  List<MovimientoStock> historialCargas(StockRodanteChofer nota) {
    final movimientos = <MovimientoStock>[];
    var id = 0;
    for (final linea in nota.ordenados) {
      final etiqueta = linea.kg != null ? 'Garrafa ${linea.kg} kg' : linea.sku;
      if (linea.llenosSalida > 0) {
        movimientos.add(MovimientoStock(
          id: ++id,
          tipoMovimiento: 'CARGA_CAMION',
          productoId: linea.idProducto,
          productoSku: linea.sku,
          productoDescripcion: etiqueta,
          cantidad: linea.llenosSalida,
          usuario: '',
          repartidorNombre: nota.nombreChofer,
          fecha: nota.createdAt,
          folio: nota.numeroNota,
          observaciones: 'Carga inicial de salida · $etiqueta',
        ));
      }
      if (linea.recargasLlenos > 0) {
        movimientos.add(MovimientoStock(
          id: ++id,
          tipoMovimiento: 'CARGA_CAMION',
          productoId: linea.idProducto,
          productoSku: linea.sku,
          productoDescripcion: etiqueta,
          cantidad: linea.recargasLlenos,
          usuario: '',
          repartidorNombre: nota.nombreChofer,
          fecha: nota.updatedAt ?? nota.createdAt,
          folio: nota.numeroNota,
          observaciones: 'Recargas en ruta (acumulado del día) · $etiqueta',
        ));
      }
    }
    return movimientos;
  }
}
