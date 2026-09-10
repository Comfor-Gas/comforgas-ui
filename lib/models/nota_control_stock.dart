import 'producto_catalogo.dart';

class LineaStock {
  final ProductoCatalogo producto;
  final int llenos;
  final int vacios;
  final int averiados;

  const LineaStock({
    required this.producto,
    this.llenos = 0,
    this.vacios = 0,
    this.averiados = 0,
  });

  int get totalLinea => llenos + vacios + averiados;

  LineaStock copyWith({int? llenos, int? vacios, int? averiados}) {
    return LineaStock(
      producto: producto,
      llenos: llenos ?? this.llenos,
      vacios: vacios ?? this.vacios,
      averiados: averiados ?? this.averiados,
    );
  }
}

class NotaControlStockDraft {
  final int camionId;
  final String choferNombre;
  final String patente;
  final String? folio;
  final DateTime fecha;
  final List<LineaStock> lineas;
  final String? observaciones;

  const NotaControlStockDraft({
    required this.camionId,
    required this.choferNombre,
    required this.patente,
    this.folio,
    required this.fecha,
    required this.lineas,
    this.observaciones,
  });

  int get totalLlenos => lineas.fold(0, (a, l) => a + l.llenos);
  int get totalVacios => lineas.fold(0, (a, l) => a + l.vacios);
  int get totalGeneral => totalLlenos + totalVacios;

  List<Map<String, dynamic>> cargaItems({int? llenaId, int? vaciaId}) {
    final items = <Map<String, dynamic>>[];
    for (final l in lineas) {
      if (l.llenos > 0) {
        items.add({
          'productoId': l.producto.idProducto,
          'cantidad': l.llenos,
          if (llenaId != null) 'estadoGarrafaId': llenaId,
        });
      }
      if (l.vacios > 0 && vaciaId != null) {
        items.add({
          'productoId': l.producto.idProducto,
          'cantidad': l.vacios,
          'estadoGarrafaId': vaciaId,
        });
      }
    }
    return items;
  }
}

class EntradaMovilDraft {
  final int camionId;
  final String choferNombre;
  final String patente;
  final DateTime fecha;
  final List<LineaStock> lineas;
  final String? observaciones;

  const EntradaMovilDraft({
    required this.camionId,
    required this.choferNombre,
    required this.patente,
    required this.fecha,
    required this.lineas,
    this.observaciones,
  });

  int get totalLlenos => lineas.fold(0, (a, l) => a + l.llenos);
  int get totalVacios => lineas.fold(0, (a, l) => a + l.vacios);
  int get totalAveriados => lineas.fold(0, (a, l) => a + l.averiados);
  int get totalGeneral => totalLlenos + totalVacios + totalAveriados;

  List<Map<String, dynamic>> descargaItems({
    required int? estadoLlenaId,
    required int? estadoVaciaId,
    required int? estadoAveriadoId,
  }) {
    final items = <Map<String, dynamic>>[];
    for (final l in lineas) {
      if (l.llenos > 0 && estadoLlenaId != null) {
        items.add({
          'productoId': l.producto.idProducto,
          'estadoGarrafaId': estadoLlenaId,
          'cantidad': l.llenos,
        });
      }
      if (l.vacios > 0 && estadoVaciaId != null) {
        items.add({
          'productoId': l.producto.idProducto,
          'estadoGarrafaId': estadoVaciaId,
          'cantidad': l.vacios,
        });
      }
      if (l.averiados > 0 && estadoAveriadoId != null) {
        items.add({
          'productoId': l.producto.idProducto,
          'estadoGarrafaId': estadoAveriadoId,
          'cantidad': l.averiados,
        });
      }
    }
    return items;
  }
}
