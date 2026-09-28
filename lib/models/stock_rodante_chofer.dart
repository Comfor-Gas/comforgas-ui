import '../utils/garrafa_match.dart';
import '../utils/json_parsing.dart';

int _entero(Map<String, dynamic> json, List<String> claves, {int porDefecto = 0}) {
  for (final clave in claves) {
    final valor = parseInt(json[clave]);
    if (valor != null) return valor;
  }
  return porDefecto;
}

int? _enteroOpcional(Map<String, dynamic> json, List<String> claves) {
  for (final clave in claves) {
    final valor = parseInt(json[clave]);
    if (valor != null) return valor;
  }
  return null;
}

String _texto(Map<String, dynamic> json, List<String> claves) {
  for (final clave in claves) {
    final valor = json[clave];
    if (valor != null && valor.toString().isNotEmpty) return valor.toString();
  }
  return '';
}

String? _textoOpcional(Map<String, dynamic> json, List<String> claves) {
  final valor = _texto(json, claves);
  return valor.isEmpty ? null : valor;
}

class StockRodanteProducto {
  final String idProducto;
  final String sku;
  final int llenosSalida;
  final int vaciosSalida;
  final int recargasLlenos;
  final int llenosEntrada;
  final int vaciosEntrada;
  final int averiadosEntrada;
  final int disponiblesParaVenta;
  final int vaciosEnCamion;
  final int averiadosEnCamion;
  final int totalVendidoLlenos;
  final int canjesRealizados;
  final int custodiasPendientes;

  const StockRodanteProducto({
    required this.idProducto,
    required this.sku,
    this.llenosSalida = 0,
    this.vaciosSalida = 0,
    this.recargasLlenos = 0,
    this.llenosEntrada = 0,
    this.vaciosEntrada = 0,
    this.averiadosEntrada = 0,
    this.disponiblesParaVenta = 0,
    this.vaciosEnCamion = 0,
    this.averiadosEnCamion = 0,
    this.totalVendidoLlenos = 0,
    this.canjesRealizados = 0,
    this.custodiasPendientes = 0,
  });

  int? get kg => kgDesdeTexto(sku) ?? kgDesdeTexto(idProducto);

  String get etiqueta => kg != null ? '$kg kg' : sku;

  String get clave => idProducto.isNotEmpty ? idProducto : sku;

  int get llenosCargados => llenosSalida + recargasLlenos;

  int get llenosActuales => disponiblesParaVenta;

  int get averiadosActuales => averiadosEnCamion;

  bool coincideCon(String codigo) {
    final c = codigo.trim().toUpperCase();
    if (c.isEmpty) return false;
    return idProducto.toUpperCase() == c || sku.toUpperCase() == c;
  }

  Map<String, dynamic> toStorageJson() => {
        'idProducto': idProducto,
        'sku': sku,
        'llenosSalida': llenosSalida,
        'vaciosSalida': vaciosSalida,
        'recargaLlenos': recargasLlenos,
        'llenosEntrada': llenosEntrada,
        'vaciosEntrada': vaciosEntrada,
        'averiadosEntrada': averiadosEntrada,
        'disponiblesParaVenta': disponiblesParaVenta,
        'vaciosEnCamion': vaciosEnCamion,
        'averiadosEnCamion': averiadosEnCamion,
        'totalVendidoLlenos': totalVendidoLlenos,
        'canjesRealizados': canjesRealizados,
        'custodiasPendientes': custodiasPendientes,
      };

  StockRodanteProducto conMenosLlenos(int menos) {
    if (menos <= 0) return this;
    final nuevoDisponible = disponiblesParaVenta - menos;
    return StockRodanteProducto(
      idProducto: idProducto,
      sku: sku,
      llenosSalida: llenosSalida,
      vaciosSalida: vaciosSalida,
      recargasLlenos: recargasLlenos,
      llenosEntrada: llenosEntrada,
      vaciosEntrada: vaciosEntrada,
      averiadosEntrada: averiadosEntrada,
      disponiblesParaVenta: nuevoDisponible < 0 ? 0 : nuevoDisponible,
      vaciosEnCamion: vaciosEnCamion,
      averiadosEnCamion: averiadosEnCamion,
      totalVendidoLlenos: totalVendidoLlenos + menos,
      canjesRealizados: canjesRealizados,
      custodiasPendientes: custodiasPendientes,
    );
  }

  factory StockRodanteProducto.fromJson(Map<String, dynamic> json) {
    final llenosSalida = _entero(json, ['llenosSalida', 'llenos_salida']);
    final vaciosSalida = _entero(json, ['vaciosSalida', 'vacios_salida']);
    final recargas = _entero(json, ['recargaLlenos', 'recargasLlenos', 'recarga_llenos']);
    final disponibles = _enteroOpcional(
      json,
      ['disponiblesParaVenta', 'disponibles_para_venta'],
    );
    final vaciosCamion = _enteroOpcional(json, ['vaciosEnCamion', 'vacios_en_camion']);
    final averiadosCamion = _enteroOpcional(json, ['averiadosEnCamion', 'averiados_en_camion']);
    final averiadosEntrada = _entero(json, ['averiadosEntrada', 'averiados_entrada']);
    return StockRodanteProducto(
      idProducto: _texto(json, ['idProducto', 'id_producto']),
      sku: _texto(json, ['sku']),
      llenosSalida: llenosSalida,
      vaciosSalida: vaciosSalida,
      recargasLlenos: recargas,
      llenosEntrada: _entero(json, ['llenosEntrada', 'llenos_entrada']),
      vaciosEntrada: _entero(json, ['vaciosEntrada', 'vacios_entrada']),
      averiadosEntrada: averiadosEntrada,
      disponiblesParaVenta: disponibles ?? (llenosSalida + recargas),
      vaciosEnCamion: vaciosCamion ?? vaciosSalida,
      averiadosEnCamion: averiadosCamion ?? averiadosEntrada,
      totalVendidoLlenos: _entero(json, ['totalVendidoLlenos', 'total_vendido_llenos']),
      canjesRealizados: _entero(json, ['canjesRealizados', 'canjes_realizados']),
      custodiasPendientes: _entero(json, ['custodiasPendientes', 'custodias_pendientes']),
    );
  }
}

class StockRodanteChofer {
  final int? idNota;
  final String? numeroNota;
  final String? idUsuario;
  final String? nombreChofer;
  final String? dominioVehiculo;
  final DateTime? fechaRuta;
  final String? estado;
  final String? observaciones;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? totalLlenosDisponiblesBackend;
  final int? totalVaciosEnCamionBackend;
  final int? totalAveriadosEnCamionBackend;
  final List<StockRodanteProducto> productos;

  const StockRodanteChofer({
    this.idNota,
    this.numeroNota,
    this.idUsuario,
    this.nombreChofer,
    this.dominioVehiculo,
    this.fechaRuta,
    this.estado,
    this.observaciones,
    this.createdAt,
    this.updatedAt,
    this.totalLlenosDisponiblesBackend,
    this.totalVaciosEnCamionBackend,
    this.totalAveriadosEnCamionBackend,
    this.productos = const [],
  });

  int get totalLlenosActuales => totalLlenosDisponibles;
  int get totalCargaInicial => productos.fold(0, (a, p) => a + p.llenosSalida);
  int get totalRecargas => productos.fold(0, (a, p) => a + p.recargasLlenos);
  int get totalLlenosCargados => productos.fold(0, (a, p) => a + p.llenosCargados);
  int get totalVaciosEntrada => productos.fold(0, (a, p) => a + p.vaciosEntrada);
  int get totalVendidoLlenos => productos.fold(0, (a, p) => a + p.totalVendidoLlenos);

  int get totalLlenosDisponibles =>
      totalLlenosDisponiblesBackend ??
      productos.fold(0, (a, p) => a + p.disponiblesParaVenta);

  int get totalVaciosEnCamion =>
      totalVaciosEnCamionBackend ??
      productos.fold(0, (a, p) => a + p.vaciosEnCamion);

  int get totalAveriadosEnCamion =>
      totalAveriadosEnCamionBackend ??
      productos.fold(0, (a, p) => a + p.averiadosEnCamion);

  String get estadoNormalizado => (estado ?? '').toUpperCase();

  bool get jornadaCerrada => estadoNormalizado == 'ENTRADA_COMPLETA';

  bool get cerrada => jornadaCerrada;

  List<StockRodanteProducto> get ordenados {
    final lista = [...productos];
    lista.sort((a, b) => (a.kg ?? 0).compareTo(b.kg ?? 0));
    return lista;
  }

  StockRodanteProducto? buscarProducto({
    required String idProducto,
    String sku = '',
    int? kg,
  }) {
    return buscarGarrafa<StockRodanteProducto>(
      productos,
      idProducto: idProducto,
      sku: sku,
      kg: kg,
      idDe: (p) => p.idProducto,
      skuDe: (p) => p.sku,
      kgDe: (p) => p.kg,
    );
  }

  Map<String, dynamic> toStorageJson() => {
        'idNota': idNota,
        'numeroNota': numeroNota,
        'idUsuario': idUsuario,
        'nombreChofer': nombreChofer,
        'dominioVehiculo': dominioVehiculo,
        'fechaRuta': fechaRuta != null ? formatDateOnly(fechaRuta!) : null,
        'estado': estado,
        'observaciones': observaciones,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'totalLlenosDisponibles': totalLlenosDisponiblesBackend,
        'totalVaciosEnCamion': totalVaciosEnCamionBackend,
        'totalAveriadosEnCamion': totalAveriadosEnCamionBackend,
        'detalles': productos.map((p) => p.toStorageJson()).toList(),
      };

  StockRodanteChofer aplicarSalidas(Map<String, int> llenosPorProducto) {
    if (llenosPorProducto.isEmpty) return this;
    final nuevos = productos.map((p) {
      var menos = 0;
      llenosPorProducto.forEach((codigo, cantidad) {
        if (p.coincideCon(codigo)) menos += cantidad;
      });
      return menos > 0 ? p.conMenosLlenos(menos) : p;
    }).toList();
    return StockRodanteChofer(
      idNota: idNota,
      numeroNota: numeroNota,
      idUsuario: idUsuario,
      nombreChofer: nombreChofer,
      dominioVehiculo: dominioVehiculo,
      fechaRuta: fechaRuta,
      estado: estado,
      observaciones: observaciones,
      createdAt: createdAt,
      updatedAt: updatedAt,
      productos: nuevos,
    );
  }

  factory StockRodanteChofer.fromJson(Map<String, dynamic> json) {
    final rawProductos = json['detalles'] ?? json['productos'];
    return StockRodanteChofer(
      idNota: _enteroOpcional(json, ['idNota', 'id_nota']),
      numeroNota: _textoOpcional(json, ['numeroNota', 'numero_nota']),
      idUsuario: _textoOpcional(json, ['idUsuario', 'id_usuario']),
      nombreChofer: _textoOpcional(json, ['nombreChofer', 'nombre_chofer']),
      dominioVehiculo: _textoOpcional(json, ['dominioVehiculo', 'dominio_vehiculo']),
      fechaRuta: parseDate(json['fechaRuta'] ?? json['fecha_ruta']),
      estado: json['estado']?.toString(),
      observaciones: _textoOpcional(json, ['observaciones']),
      createdAt: parseDate(json['createdAt'] ?? json['created_at']),
      updatedAt: parseDate(json['updatedAt'] ?? json['updated_at']),
      totalLlenosDisponiblesBackend: _enteroOpcional(
        json,
        ['totalLlenosDisponibles', 'total_llenos_disponibles'],
      ),
      totalVaciosEnCamionBackend: _enteroOpcional(
        json,
        ['totalVaciosEnCamion', 'total_vacios_en_camion'],
      ),
      totalAveriadosEnCamionBackend: _enteroOpcional(
        json,
        ['totalAveriadosEnCamion', 'total_averiados_en_camion'],
      ),
      productos: rawProductos is List
          ? rawProductos
              .whereType<Map<String, dynamic>>()
              .map(StockRodanteProducto.fromJson)
              .toList()
          : const [],
    );
  }
}
