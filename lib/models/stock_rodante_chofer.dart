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
    final llenosSalida =
        parseInt(json['llenosSalida']) ?? parseInt(json['llenos_salida']) ?? 0;
    final vaciosSalida =
        parseInt(json['vaciosSalida']) ?? parseInt(json['vacios_salida']) ?? 0;
    final recargasLlenos = parseInt(json['recargaLlenos']) ??
        parseInt(json['recargasLlenos']) ??
        parseInt(json['recarga_llenos']) ??
        0;
    final llenosActualesRaw =
        parseInt(json['llenosActuales']) ?? parseInt(json['llenos_actuales']);
    final vaciosActualesRaw =
        parseInt(json['vaciosActuales']) ?? parseInt(json['vacios_actuales']);
    final averiadosRaw = parseInt(json['averiadosActuales']) ??
        parseInt(json['averiadosEntrada']) ??
        parseInt(json['averiados_entrada']);
    return StockRodanteProducto(
      idProducto: (json['idProducto'] ?? json['id_producto'] ?? '').toString(),
      sku: (json['sku'] ?? '').toString(),
      llenosSalida: llenosSalida,
      vaciosSalida: vaciosSalida,
      recargasLlenos: recargasLlenos,
      llenosActuales: llenosActualesRaw ?? (llenosSalida + recargasLlenos),
      vaciosActuales: vaciosActualesRaw ?? vaciosSalida,
      averiadosActuales: averiadosRaw ?? 0,
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
    final rawProductos = json['detalles'] ?? json['productos'];
    return StockRodanteChofer(
      nombreChofer: (json['nombreChofer'] ?? json['nombre_chofer'])?.toString(),
      dominioVehiculo:
          (json['dominioVehiculo'] ?? json['dominio_vehiculo'])?.toString(),
      productos: rawProductos is List
          ? rawProductos
              .whereType<Map<String, dynamic>>()
              .map(StockRodanteProducto.fromJson)
              .toList()
          : const [],
    );
  }
}
