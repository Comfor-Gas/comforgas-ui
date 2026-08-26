import '../utils/json_parsing.dart';

class StockCamionItem {
  final String productoId;
  final String sku;
  final String descripcion;
  final String estadoCodigo;
  final int cantidad;

  const StockCamionItem({
    required this.productoId,
    required this.sku,
    required this.descripcion,
    required this.estadoCodigo,
    required this.cantidad,
  });

  bool get esLlena => estadoCodigo.toUpperCase() == 'LLENA';

  factory StockCamionItem.fromJson(Map<String, dynamic> json) {
    return StockCamionItem(
      productoId: (json['productoId'] ?? '').toString(),
      sku: (json['productoCodigo'] ?? json['sku'] ?? '').toString(),
      descripcion: (json['productoDescripcion'] ?? json['descripcion'] ?? '').toString(),
      estadoCodigo: (json['estadoCodigo'] ?? '').toString(),
      cantidad: parseInt(json['cantidad']) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productoId': productoId,
      'productoCodigo': sku,
      'productoDescripcion': descripcion,
      'estadoCodigo': estadoCodigo,
      'cantidad': cantidad,
    };
  }
}

class StockCamion {
  final int? depositoId;
  final String? depositoNombre;
  final List<StockCamionItem> items;

  const StockCamion({
    this.depositoId,
    this.depositoNombre,
    this.items = const [],
  });

  int disponibleLleno(String productoId) {
    return items
        .where((i) => i.productoId == productoId && i.esLlena)
        .fold(0, (total, i) => total + i.cantidad);
  }

  List<StockCamionItem> get llenasDisponibles =>
      items.where((i) => i.esLlena && i.cantidad > 0).toList();

  factory StockCamion.fromJson(Map<String, dynamic> json) {
    final deposito = json['deposito'];
    final rawItems = json['stock'] ?? json['items'];
    return StockCamion(
      depositoId: deposito is Map<String, dynamic> ? parseInt(deposito['id']) : null,
      depositoNombre:
          deposito is Map<String, dynamic> ? deposito['nombre']?.toString() : null,
      items: rawItems is List
          ? rawItems
              .whereType<Map<String, dynamic>>()
              .map(StockCamionItem.fromJson)
              .toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deposito': {'id': depositoId, 'nombre': depositoNombre},
      'stock': items.map((i) => i.toJson()).toList(),
    };
  }
}
