import '../utils/json_parsing.dart';

String traducirBloqueoCuadre(String codigo) {
  switch (codigo.trim().toUpperCase()) {
    case 'ARQUEO_ABIERTO_O_INEXISTENTE':
      return 'El arqueo de caja del chofer todavía no está cerrado. Cerralo en Cobranzas / Arqueo.';
    case 'NOTA_STOCK_INEXISTENTE':
      return 'No hay una Nota de Control de Stock del día para este chofer.';
    case 'STOCK_NO_CERRADO':
      return 'La Nota de Control de Stock no está cerrada: falta que el chofer envíe la rendición del día.';
    case 'VISITAS_NO_FINALIZADAS':
      return 'Hay visitas sin finalizar (pendientes, en curso o pausadas por venta social).';
    case 'CUSTODIA_SOCIAL_ABIERTA':
      return 'Hay una venta social sin liquidar.';
    case 'SALDOS_FINANCIEROS_PENDIENTES':
      return 'Hay diferencias de dinero sin ajustar. Podés registrar el ajuste o aprobar igual: la diferencia queda registrada.';
    case 'SALDOS_DE_ENVASES_PENDIENTES':
      return 'Hay diferencias de envases (garrafas) sin ajustar. Podés registrar el ajuste o aprobar igual: la diferencia queda registrada.';
    case 'VEHICULO_NO_ASIGNADO':
      return 'El chofer no tiene un camión asignado.';
    case 'STOCK_NO_DISPONIBLE':
      return 'El módulo de stock no está disponible en este momento.';
    case 'STOCK_CAMION_PENDIENTE':
      return 'El camión todavía figura con stock cargado en el sistema.';
    default:
      return codigo.trim();
  }
}

const Set<String> _bloqueosBlandos = {
  'SALDOS_FINANCIEROS_PENDIENTES',
  'SALDOS_DE_ENVASES_PENDIENTES',
};

bool esBloqueoBlando(String codigo) =>
    _bloqueosBlandos.contains(codigo.trim().toUpperCase());

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
  final int efectivoSistema;
  final int chequesSistema;
  final int transferenciasSistema;
  final int efectivoDeclarado;
  final int chequesDeclarado;
  final int transferenciasDeclarado;
  final List<CuadreEnvaseLinea> envases;
  final String observaciones;
  final bool hayRendicion;
  final int? idRendicion;
  final bool puedeAprobar;
  final List<String> bloqueos;

  const CuadreRendicion({
    required this.idUsuario,
    this.nombreChofer = '',
    this.fecha,
    this.estado = 'PENDIENTE_CONCILIACION',
    this.rutaBloqueada = false,
    this.efectivoSistema = 0,
    this.chequesSistema = 0,
    this.transferenciasSistema = 0,
    this.efectivoDeclarado = 0,
    this.chequesDeclarado = 0,
    this.transferenciasDeclarado = 0,
    this.envases = const [],
    this.observaciones = '',
    this.hayRendicion = false,
    this.idRendicion,
    this.puedeAprobar = false,
    this.bloqueos = const [],
  });

  factory CuadreRendicion.vacio({
    required String idUsuario,
    String nombreChofer = '',
    DateTime? fecha,
  }) {
    return CuadreRendicion(
      idUsuario: idUsuario,
      nombreChofer: nombreChofer,
      fecha: fecha,
      estado: 'PENDIENTE_RENDICION',
      hayRendicion: false,
    );
  }

  factory CuadreRendicion.fromConciliacion(Map<String, dynamic> json) {
    int sisEf = 0, sisCh = 0, sisTr = 0, decEf = 0, decCh = 0, decTr = 0;
    final fin = json['financiero'];
    if (fin is Map<String, dynamic>) {
      for (final r in (fin['rubros'] as List? ?? const [])) {
        if (r is! Map) continue;
        final concepto = (r['concepto'] ?? '').toString().toUpperCase();
        final sistema = (parseDouble(r['sistema']) ?? 0).round();
        final rendido = (parseDouble(r['rendido']) ?? 0).round();
        if (concepto.startsWith('EFECTIVO')) {
          sisEf = sistema;
          decEf = rendido;
        } else if (concepto.startsWith('CHEQUE')) {
          sisCh = sistema;
          decCh = rendido;
        } else if (concepto.startsWith('TRANSFER')) {
          sisTr = sistema;
          decTr = rendido;
        }
      }
    }

    final envases = <CuadreEnvaseLinea>[];
    final env = json['envases'];
    if (env is Map<String, dynamic>) {
      for (final r in (env['rubros'] as List? ?? const [])) {
        if (r is! Map) continue;
        final sku = (r['sku'] ?? '').toString();
        final llenosEsp = parseInt(r['llenosEsperados']) ?? 0;
        final vaciosEsp = parseInt(r['vaciosEsperados']) ?? 0;
        final danadosEsp = parseInt(r['danadosEsperados']) ?? 0;
        envases.add(CuadreEnvaseLinea(
          sku: sku,
          etiqueta: CuadreEnvaseLinea._etiquetaDeSku(sku),
          llenosSistema: llenosEsp,
          llenosDeclarado: llenosEsp,
          vaciosSistema: vaciosEsp,
          vaciosDeclarado: vaciosEsp,
          averiadosDeclarado: danadosEsp,
        ));
      }
    }

    final rendicion = json['rendicion'];
    final hayRendicion = rendicion is Map && rendicion.isNotEmpty;
    var observaciones = '';
    if (rendicion is Map) {
      observaciones = (rendicion['observacionesChofer'] ?? '').toString();
    }

    final bloqueos = <String>[
      for (final b in (json['bloqueos'] as List? ?? const []))
        if (b != null) b.toString(),
    ];

    return CuadreRendicion(
      idUsuario: (json['idUsuario'] ?? '').toString(),
      nombreChofer: (json['nombreUsuario'] ?? '').toString(),
      fecha: parseDate(json['fecha']),
      estado: (json['estadoRendicion'] ?? 'PENDIENTE_RENDICION').toString(),
      rutaBloqueada: json['aprobada'] == true,
      efectivoSistema: sisEf,
      chequesSistema: sisCh,
      transferenciasSistema: sisTr,
      efectivoDeclarado: decEf,
      chequesDeclarado: decCh,
      transferenciasDeclarado: decTr,
      envases: envases,
      observaciones: observaciones,
      hayRendicion: hayRendicion,
      idRendicion: parseInt(json['idRendicion']),
      puedeAprobar: json['puedeAprobar'] == true,
      bloqueos: bloqueos,
    );
  }

  int get totalDeclaradoValores =>
      efectivoDeclarado + chequesDeclarado + transferenciasDeclarado;

  int get totalSistemaValores =>
      efectivoSistema + chequesSistema + transferenciasSistema;

  int get totalLlenosDeclarado =>
      envases.fold(0, (a, e) => a + e.llenosDeclarado);
  int get totalVaciosDeclarado =>
      envases.fold(0, (a, e) => a + e.vaciosDeclarado);

  bool get aprobada => estado.toUpperCase() == 'APROBADA';
  bool get aprobable => !rutaBloqueada && !aprobada;

  List<String> get bloqueosDuros =>
      [for (final b in bloqueos) if (!esBloqueoBlando(b)) b];
  List<String> get bloqueosBlandos =>
      [for (final b in bloqueos) if (esBloqueoBlando(b)) b];
  bool get tieneDiferencias => bloqueosBlandos.isNotEmpty;

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
