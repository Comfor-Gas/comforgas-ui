import '../utils/json_parsing.dart';

class CuadreProducto {
  final String idProducto;
  final String sku;
  final int llenosSalida;
  final int vaciosSalida;
  final int recargasLlenos;
  final int llenosCargados;
  final int ventas;
  final int prestamos;
  final int canjes;
  final int llenosTeoricos;
  final int vaciosTeoricos;
  final int averiadosTeoricos;
  final int? llenosEntrada;
  final int? vaciosEntrada;
  final int? averiadosEntrada;
  final int? diferenciaLlenos;
  final int? diferenciaVacios;
  final int? diferenciaAveriados;
  final int? envasesSalida;
  final int? envasesEntrada;
  final int? diferenciaEnvases;
  final int? faltanteNoExplicado;
  final bool cuadra;

  const CuadreProducto({
    required this.idProducto,
    required this.sku,
    this.llenosSalida = 0,
    this.vaciosSalida = 0,
    this.recargasLlenos = 0,
    this.llenosCargados = 0,
    this.ventas = 0,
    this.prestamos = 0,
    this.canjes = 0,
    this.llenosTeoricos = 0,
    this.vaciosTeoricos = 0,
    this.averiadosTeoricos = 0,
    this.llenosEntrada,
    this.vaciosEntrada,
    this.averiadosEntrada,
    this.diferenciaLlenos,
    this.diferenciaVacios,
    this.diferenciaAveriados,
    this.envasesSalida,
    this.envasesEntrada,
    this.diferenciaEnvases,
    this.faltanteNoExplicado,
    this.cuadra = true,
  });

  int? get kg {
    final match = RegExp(r'\d+').firstMatch(sku) ?? RegExp(r'\d+').firstMatch(idProducto);
    return match != null ? int.tryParse(match.group(0)!) : null;
  }

  String get etiqueta => kg != null ? '$kg kg' : sku;

  factory CuadreProducto.fromJson(Map<String, dynamic> json) {
    return CuadreProducto(
      idProducto: (json['idProducto'] ?? '').toString(),
      sku: (json['sku'] ?? '').toString(),
      llenosSalida: parseInt(json['llenosSalida']) ?? 0,
      vaciosSalida: parseInt(json['vaciosSalida']) ?? 0,
      recargasLlenos: parseInt(json['recargasLlenos']) ?? 0,
      ventas: parseInt(json['ventas']) ?? 0,
      prestamos: parseInt(json['prestamos']) ?? 0,
      canjes: parseInt(json['canjes']) ?? 0,
      llenosTeoricos: parseInt(json['llenosTeoricos']) ?? 0,
      vaciosTeoricos: parseInt(json['vaciosTeoricos']) ?? 0,
      averiadosTeoricos: parseInt(json['averiadosTeoricos']) ?? 0,
      llenosEntrada: parseInt(json['llenosEntrada']),
      vaciosEntrada: parseInt(json['vaciosEntrada']),
      averiadosEntrada: parseInt(json['averiadosEntrada']),
      diferenciaLlenos: parseInt(json['diferenciaLlenos']),
      diferenciaVacios: parseInt(json['diferenciaVacios']),
      diferenciaAveriados: parseInt(json['diferenciaAveriados']),
      cuadra: json['cuadra'] == true,
    );
  }

  factory CuadreProducto.fromInforme(
    Map<String, dynamic> json, {
    required bool entradaRegistrada,
  }) {
    final llenosSalida = parseInt(json['llenosSalida']) ?? 0;
    final recargas = parseInt(json['recargaLlenos']) ?? 0;
    final cargados =
        parseInt(json['totalLlenosCargados']) ?? (llenosSalida + recargas);
    final vendidos = parseInt(json['llenosVendidosEstimados']) ?? 0;
    final vaciosSalida = parseInt(json['vaciosSalida']) ?? 0;
    final llenosEntrada = parseInt(json['llenosEntrada']) ?? 0;
    final vaciosEntrada = parseInt(json['vaciosEntrada']) ?? 0;
    final averiadosEntrada = parseInt(json['averiadosEntrada']) ?? 0;
    final envasesSalida =
        parseInt(json['totalEnvasesSalida']) ?? (llenosSalida + vaciosSalida);
    final envasesEntrada = parseInt(json['totalEnvasesEntrada']) ??
        (llenosEntrada + vaciosEntrada + averiadosEntrada);
    final difEnvases = parseInt(json['diferenciaEnvases']) ?? 0;
    final faltante = parseInt(json['faltanteNoExplicado']) ?? 0;

    return CuadreProducto(
      idProducto: (json['idProducto'] ?? '').toString(),
      sku: (json['sku'] ?? '').toString(),
      llenosSalida: llenosSalida,
      vaciosSalida: vaciosSalida,
      recargasLlenos: recargas,
      llenosCargados: cargados,
      ventas: vendidos,
      llenosEntrada: entradaRegistrada ? llenosEntrada : null,
      vaciosEntrada: entradaRegistrada ? vaciosEntrada : null,
      averiadosEntrada: entradaRegistrada ? averiadosEntrada : null,
      envasesSalida: envasesSalida,
      envasesEntrada: entradaRegistrada ? envasesEntrada : null,
      diferenciaEnvases: entradaRegistrada ? difEnvases : null,
      faltanteNoExplicado: entradaRegistrada ? faltante : null,
      cuadra: difEnvases == 0 && faltante == 0,
    );
  }
}

class CuadreRodante {
  final int idNota;
  final String? numeroNota;
  final String? nombreChofer;
  final String? dominioVehiculo;
  final DateTime? fechaRuta;
  final String estado;
  final bool entradaRegistrada;
  final bool cuadra;
  final List<CuadreProducto> productos;

  const CuadreRodante({
    required this.idNota,
    this.numeroNota,
    this.nombreChofer,
    this.dominioVehiculo,
    this.fechaRuta,
    this.estado = '',
    this.entradaRegistrada = false,
    this.cuadra = true,
    this.productos = const [],
  });

  factory CuadreRodante.fromJson(Map<String, dynamic> json) {
    final raw = json['productos'];
    return CuadreRodante(
      idNota: parseInt(json['idNota']) ?? 0,
      numeroNota: json['numeroNota']?.toString(),
      nombreChofer: json['nombreChofer']?.toString(),
      dominioVehiculo: json['dominioVehiculo']?.toString(),
      fechaRuta: parseDate(json['fechaRuta']),
      estado: (json['estado'] ?? '').toString(),
      entradaRegistrada: json['entradaRegistrada'] == true,
      cuadra: json['cuadra'] == true,
      productos: raw is List
          ? raw.whereType<Map<String, dynamic>>().map(CuadreProducto.fromJson).toList()
          : const [],
    );
  }

  factory CuadreRodante.fromInforme(Map<String, dynamic> json) {
    final estado = (json['estado'] ?? '').toString();
    final entradaRegistrada = estado.toUpperCase() == 'ENTRADA_COMPLETA';
    var cuadra = true;
    final totales = json['totales'];
    if (totales is Map<String, dynamic>) {
      final dif = parseInt(totales['diferenciaTotalEnvases']) ?? 0;
      final faltante = parseInt(totales['totalFaltanteNoExplicado']) ?? 0;
      cuadra = dif == 0 && faltante == 0;
    }
    final raw = json['items'] ?? json['productos'];
    return CuadreRodante(
      idNota: parseInt(json['idNota']) ?? 0,
      numeroNota: json['numeroNota']?.toString(),
      nombreChofer: json['nombreChofer']?.toString(),
      dominioVehiculo: json['dominioVehiculo']?.toString(),
      fechaRuta: parseDate(json['fechaRuta']),
      estado: estado,
      entradaRegistrada: entradaRegistrada,
      cuadra: cuadra,
      productos: raw is List
          ? raw
              .whereType<Map<String, dynamic>>()
              .map((e) =>
                  CuadreProducto.fromInforme(e, entradaRegistrada: entradaRegistrada))
              .toList()
          : const [],
    );
  }
}
