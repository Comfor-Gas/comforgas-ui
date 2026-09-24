import '../utils/json_parsing.dart';

class StockRodanteProducto {
  final String idProducto;
  final String sku;
  final int llenosSalida;
  final int vaciosSalida;
  final int recargasLlenos;
  final int llenosActuales;
  final int llenosEntrada;
  final int vaciosActuales;
  final int vaciosEntrada;
  final int averiadosActuales;
  final int disponiblesParaVenta;
  final int vaciosEnCamion;
  final int totalVendidoLlenos;

  const StockRodanteProducto({
    required this.idProducto,
    required this.sku,
    this.llenosSalida = 0,
    this.vaciosSalida = 0,
    this.recargasLlenos = 0,
    this.llenosActuales = 0,
    this.llenosEntrada = 0,
    this.vaciosActuales = 0,
    this.vaciosEntrada = 0,
    this.averiadosActuales = 0,
    this.disponiblesParaVenta = 0,
    this.vaciosEnCamion = 0,
    this.totalVendidoLlenos = 0,
  });

  int? get kg {
    final match = RegExp(r'\d+').firstMatch(sku) ?? RegExp(r'\d+').firstMatch(idProducto);
    return match != null ? int.tryParse(match.group(0)!) : null;
  }

  String get etiqueta => kg != null ? '$kg kg' : sku;

  Map<String, dynamic> toStorageJson() => {
        'idProducto': idProducto,
        'sku': sku,
        'llenosSalida': llenosSalida,
        'vaciosSalida': vaciosSalida,
        'recargaLlenos': recargasLlenos,
        'llenosActuales': llenosActuales,
        'llenosEntrada': llenosEntrada,
        'vaciosActuales': vaciosActuales,
        'vaciosEntrada': vaciosEntrada,
        'averiadosActuales': averiadosActuales,
        'disponiblesParaVenta': disponiblesParaVenta,
        'vaciosEnCamion': vaciosEnCamion,
        'totalVendidoLlenos': totalVendidoLlenos,
      };

  StockRodanteProducto conMenosLlenos(int menos) {
    if (menos <= 0) return this;
    final nuevoDisponible = disponiblesParaVenta - menos;
    final nuevoActual = llenosActuales - menos;
    return StockRodanteProducto(
      idProducto: idProducto,
      sku: sku,
      llenosSalida: llenosSalida,
      vaciosSalida: vaciosSalida,
      recargasLlenos: recargasLlenos,
      llenosActuales: nuevoActual < 0 ? 0 : nuevoActual,
      llenosEntrada: llenosEntrada,
      vaciosActuales: vaciosActuales,
      vaciosEntrada: vaciosEntrada,
      averiadosActuales: averiadosActuales,
      disponiblesParaVenta: nuevoDisponible < 0 ? 0 : nuevoDisponible,
      vaciosEnCamion: vaciosEnCamion,
      totalVendidoLlenos: totalVendidoLlenos + menos,
    );
  }

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
    final llenosEntradaRaw = parseInt(json['llenosEntrada']) ??
        parseInt(json['llenos_entrada']);
    final vaciosActualesRaw =
        parseInt(json['vaciosActuales']) ?? parseInt(json['vacios_actuales']);
    final vaciosEntradaRaw = parseInt(json['vaciosEntrada']) ??
        parseInt(json['vacios_entrada']);
    final averiadosRaw = parseInt(json['averiadosActuales']) ??
        parseInt(json['averiadosEntrada']) ??
        parseInt(json['averiados_entrada']);
    final disponibles = parseInt(json['disponiblesParaVenta']) ??
        parseInt(json['disponibles_para_venta']);
    final vaciosCamion = parseInt(json['vaciosEnCamion']) ??
        parseInt(json['vacios_en_camion']);
    final vendidos = parseInt(json['totalVendidoLlenos']) ??
        parseInt(json['total_vendido_llenos']) ??
        0;
    final llenosActuales = llenosActualesRaw ?? (llenosSalida + recargasLlenos);
    return StockRodanteProducto(
      idProducto: (json['idProducto'] ?? json['id_producto'] ?? '').toString(),
      sku: (json['sku'] ?? '').toString(),
      llenosSalida: llenosSalida,
      vaciosSalida: vaciosSalida,
      recargasLlenos: recargasLlenos,
      llenosActuales: llenosActuales,
      llenosEntrada: llenosEntradaRaw ?? 0,
      vaciosActuales: vaciosActualesRaw ?? vaciosSalida,
      vaciosEntrada: vaciosEntradaRaw ?? 0,
      averiadosActuales: averiadosRaw ?? 0,
      disponiblesParaVenta: disponibles ?? llenosActuales,
      vaciosEnCamion: vaciosCamion ?? (vaciosActualesRaw ?? vaciosSalida),
      totalVendidoLlenos: vendidos,
    );
  }
}

class StockRodanteChofer {
  final int? idNota;
  final String? numeroNota;
  final String? nombreChofer;
  final String? dominioVehiculo;
  final String? estado;
  final int? totalLlenosDisponiblesBackend;
  final int? totalVaciosEnCamionBackend;
  final List<StockRodanteProducto> productos;

  const StockRodanteChofer({
    this.idNota,
    this.numeroNota,
    this.nombreChofer,
    this.dominioVehiculo,
    this.estado,
    this.totalLlenosDisponiblesBackend,
    this.totalVaciosEnCamionBackend,
    this.productos = const [],
  });

  int get totalLlenosActuales => productos.fold(0, (a, p) => a + p.llenosActuales);
  int get totalCargaInicial => productos.fold(0, (a, p) => a + p.llenosSalida);
  int get totalRecargas => productos.fold(0, (a, p) => a + p.recargasLlenos);

  int get totalLlenosDisponibles =>
      totalLlenosDisponiblesBackend ??
      productos.fold(0, (a, p) => a + p.disponiblesParaVenta);

  int get totalVaciosEnCamion =>
      totalVaciosEnCamionBackend ??
      productos.fold(0, (a, p) => a + p.vaciosEnCamion);

  bool get jornadaCerrada =>
      (estado ?? '').toUpperCase() == 'ENTRADA_COMPLETA';

  List<StockRodanteProducto> get ordenados {
    final lista = [...productos];
    lista.sort((a, b) => (a.kg ?? 0).compareTo(b.kg ?? 0));
    return lista;
  }

  Map<String, dynamic> toStorageJson() => {
        'idNota': idNota,
        'numeroNota': numeroNota,
        'nombreChofer': nombreChofer,
        'dominioVehiculo': dominioVehiculo,
        'estado': estado,
        'totalLlenosDisponibles': totalLlenosDisponiblesBackend,
        'totalVaciosEnCamion': totalVaciosEnCamionBackend,
        'detalles': productos.map((p) => p.toStorageJson()).toList(),
      };

  StockRodanteChofer aplicarSalidas(Map<String, int> llenosPorProducto) {
    if (llenosPorProducto.isEmpty) return this;
    final nuevos = productos.map((p) {
      final menos = llenosPorProducto[p.idProducto] ?? 0;
      return menos > 0 ? p.conMenosLlenos(menos) : p;
    }).toList();
    return StockRodanteChofer(
      idNota: idNota,
      numeroNota: numeroNota,
      nombreChofer: nombreChofer,
      dominioVehiculo: dominioVehiculo,
      estado: estado,
      totalLlenosDisponiblesBackend: null,
      totalVaciosEnCamionBackend: null,
      productos: nuevos,
    );
  }

  factory StockRodanteChofer.fromJson(Map<String, dynamic> json) {
    final rawProductos = json['detalles'] ?? json['productos'];
    return StockRodanteChofer(
      idNota: parseInt(json['idNota']) ?? parseInt(json['id_nota']),
      numeroNota: (json['numeroNota'] ?? json['numero_nota'])?.toString(),
      nombreChofer: (json['nombreChofer'] ?? json['nombre_chofer'])?.toString(),
      dominioVehiculo:
          (json['dominioVehiculo'] ?? json['dominio_vehiculo'])?.toString(),
      estado: (json['estado'])?.toString(),
      totalLlenosDisponiblesBackend: parseInt(json['totalLlenosDisponibles']) ??
          parseInt(json['total_llenos_disponibles']),
      totalVaciosEnCamionBackend: parseInt(json['totalVaciosEnCamion']) ??
          parseInt(json['total_vacios_en_camion']),
      productos: rawProductos is List
          ? rawProductos
              .whereType<Map<String, dynamic>>()
              .map(StockRodanteProducto.fromJson)
              .toList()
          : const [],
    );
  }
}
