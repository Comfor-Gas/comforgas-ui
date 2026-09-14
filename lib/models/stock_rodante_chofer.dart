import '../utils/json_parsing.dart';

class StockRodanteProducto {
  final String idProducto;
  final String sku;
  final int llenosSalida;
  final int vaciosSalida;
  final int recargasLlenos;
  final int llenosActuales;
  final int vaciosActuales;
  final int averiadosActuales;

  const StockRodanteProducto({
    required this.idProducto,
    required this.sku,
    this.llenosSalida = 0,
    this.vaciosSalida = 0,
    this.recargasLlenos = 0,
    this.llenosActuales = 0,
    this.vaciosActuales = 0,
    this.averiadosActuales = 0,
  });

  int? get kg {
    final match = RegExp(r'\d+').firstMatch(sku) ?? RegExp(r'\d+').firstMatch(idProducto);
    return match != null ? int.tryParse(match.group(0)!) : null;
  }

  String get etiqueta => kg != null ? '$kg kg' : sku;

  factory StockRodanteProducto.fromJson(Map<String, dynamic> json) {
    return StockRodanteProducto(
      idProducto: (json['idProducto'] ?? json['id_producto'] ?? '').toString(),
      sku: (json['sku'] ?? '').toString(),
      llenosSalida: parseInt(json['llenosSalida']) ?? 0,
      vaciosSalida: parseInt(json['vaciosSalida']) ?? 0,
      recargasLlenos: parseInt(json['recargasLlenos']) ?? 0,
      llenosActuales: parseInt(json['llenosActuales']) ?? 0,
      vaciosActuales: parseInt(json['vaciosActuales']) ?? 0,
      averiadosActuales: parseInt(json['averiadosActuales']) ?? 0,
    );
  }
}

class StockRodanteChofer {
  final String? nombreChofer;
  final String? dominioVehiculo;
  final List<StockRodanteProducto> productos;

  const StockRodanteChofer({
    this.nombreChofer,
    this.dominioVehiculo,
    this.productos = const [],
  });

  int get totalLlenosActuales => productos.fold(0, (a, p) => a + p.llenosActuales);
  int get totalCargaInicial => productos.fold(0, (a, p) => a + p.llenosSalida);
  int get totalRecargas => productos.fold(0, (a, p) => a + p.recargasLlenos);

  List<StockRodanteProducto> get ordenados {
    final lista = [...productos];
    lista.sort((a, b) => (a.kg ?? 0).compareTo(b.kg ?? 0));
    return lista;
  }

  factory StockRodanteChofer.fromJson(Map<String, dynamic> json) {
    final rawProductos = json['productos'];
    return StockRodanteChofer(
      nombreChofer: json['nombreChofer']?.toString(),
      dominioVehiculo: json['dominioVehiculo']?.toString(),
      productos: rawProductos is List
          ? rawProductos
              .whereType<Map<String, dynamic>>()
              .map(StockRodanteProducto.fromJson)
              .toList()
          : const [],
    );
  }
}
