import '../utils/json_parsing.dart';

class CuadreEnvaseLinea {
  final String sku;
  final String etiqueta;
  final int llenosSistema;
  final int llenosDeclarado;
  final int vaciosSistema;
  final int vaciosDeclarado;
  final int averiadosDeclarado;

  const CuadreEnvaseLinea({
    required this.sku,
    required this.etiqueta,
    this.llenosSistema = 0,
    this.llenosDeclarado = 0,
    this.vaciosSistema = 0,
    this.vaciosDeclarado = 0,
    this.averiadosDeclarado = 0,
  });

  int get difLlenos => llenosDeclarado - llenosSistema;
  int get difVacios => vaciosDeclarado - vaciosSistema;
  bool get cuadraLlenos => difLlenos == 0;
  bool get cuadraVacios => difVacios == 0;
  bool get cuadra => cuadraLlenos && cuadraVacios;

  factory CuadreEnvaseLinea.fromJson(Map<String, dynamic> json) {
    final sku = (json['sku'] ?? '').toString();
    return CuadreEnvaseLinea(
      sku: sku,
      etiqueta: (json['etiqueta'] ?? _etiquetaDeSku(sku)).toString(),
      llenosSistema: parseInt(json['llenosSistema']) ?? 0,
      llenosDeclarado: parseInt(json['llenosDeclarado']) ?? 0,
      vaciosSistema: parseInt(json['vaciosSistema']) ?? 0,
      vaciosDeclarado: parseInt(json['vaciosDeclarado']) ?? 0,
      averiadosDeclarado: parseInt(json['averiadosDeclarado']) ?? 0,
    );
  }

  static String _etiquetaDeSku(String sku) {
    final match = RegExp(r'\d+').firstMatch(sku);
    return match != null ? '${match.group(0)} kg' : sku;
  }
}

class CuadreRendicion {
  final String idUsuario;
  final String nombreChofer;
  final DateTime? fecha;
  final String estado;
  final bool rutaBloqueada;
  final int efectivoDeclarado;
  final int chequesDeclarado;
  final int transferenciasDeclarado;
  final List<CuadreEnvaseLinea> envases;
  final String observaciones;

  const CuadreRendicion({
    required this.idUsuario,
    this.nombreChofer = '',
    this.fecha,
    this.estado = 'PENDIENTE_CONCILIACION',
    this.rutaBloqueada = false,
    this.efectivoDeclarado = 0,
    this.chequesDeclarado = 0,
    this.transferenciasDeclarado = 0,
    this.envases = const [],
    this.observaciones = '',
  });

  int get totalDeclaradoValores =>
      efectivoDeclarado + chequesDeclarado + transferenciasDeclarado;

  int get totalLlenosDeclarado =>
      envases.fold(0, (a, e) => a + e.llenosDeclarado);
  int get totalVaciosDeclarado =>
      envases.fold(0, (a, e) => a + e.vaciosDeclarado);

  bool get aprobada => estado.toUpperCase() == 'APROBADA';
  bool get aprobable => !rutaBloqueada && !aprobada;

  int declaradoDe(String metodo) {
    switch (metodo.toUpperCase()) {
      case 'EFECTIVO':
        return efectivoDeclarado;
      case 'CHEQUE':
        return chequesDeclarado;
      case 'TRANSFERENCIA':
        return transferenciasDeclarado;
      default:
        return 0;
    }
  }

  factory CuadreRendicion.fromJson(Map<String, dynamic> json) {
    final valores = json['valores'];
    int ef = 0, ch = 0, tr = 0;
    if (valores is Map<String, dynamic>) {
      ef = parseInt(valores['efectivo']) ?? 0;
      ch = parseInt(valores['cheques']) ?? 0;
      tr = parseInt(valores['transferencias']) ?? 0;
    }
    return CuadreRendicion(
      idUsuario: (json['idUsuario'] ?? '').toString(),
      nombreChofer: (json['nombreChofer'] ?? '').toString(),
      fecha: parseDate(json['fecha']),
      estado: (json['estado'] ?? 'PENDIENTE_CONCILIACION').toString(),
      rutaBloqueada: json['rutaBloqueada'] == true,
      efectivoDeclarado: ef,
      chequesDeclarado: ch,
      transferenciasDeclarado: tr,
      envases: (json['envases'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(CuadreEnvaseLinea.fromJson)
          .toList(),
      observaciones: (json['observaciones'] ?? '').toString(),
    );
  }
}
