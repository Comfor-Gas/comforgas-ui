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

String _claveSku(String valor) => valor.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

const Set<String> _bloqueosIgnorados = {
  'ARQUEO_ABIERTO_O_INEXISTENTE',
};

enum ConceptoAjuste { efectivo, cheques, transferencias, vacios, llenos, danados }

extension ConceptoAjusteInfo on ConceptoAjuste {
  String get codigo {
    switch (this) {
      case ConceptoAjuste.efectivo:
        return 'EFECTIVO';
      case ConceptoAjuste.cheques:
        return 'CHEQUES';
      case ConceptoAjuste.transferencias:
        return 'TRANSFERENCIAS';
      case ConceptoAjuste.vacios:
        return 'VACIOS';
      case ConceptoAjuste.llenos:
        return 'LLENOS';
      case ConceptoAjuste.danados:
        return 'DANADOS';
    }
  }

  String get etiqueta {
    switch (this) {
      case ConceptoAjuste.efectivo:
        return 'Efectivo';
      case ConceptoAjuste.cheques:
        return 'Cheques';
      case ConceptoAjuste.transferencias:
        return 'Transferencias';
      case ConceptoAjuste.vacios:
        return 'Garrafas vacías';
      case ConceptoAjuste.llenos:
        return 'Garrafas llenas';
      case ConceptoAjuste.danados:
        return 'Garrafas dañadas';
    }
  }

  bool get esDinero =>
      this == ConceptoAjuste.efectivo ||
      this == ConceptoAjuste.cheques ||
      this == ConceptoAjuste.transferencias;

  static ConceptoAjuste? desdeCodigo(String codigo) {
    final c = codigo.trim().toUpperCase();
    for (final v in ConceptoAjuste.values) {
      if (v.codigo == c) return v;
    }
    if (c.startsWith('CHEQUE')) return ConceptoAjuste.cheques;
    if (c.startsWith('TRANSFER')) return ConceptoAjuste.transferencias;
    return null;
  }
}

enum TipoAjuste { faltanteCobrado, sobranteAceptado }

extension TipoAjusteInfo on TipoAjuste {
  String get codigo => this == TipoAjuste.faltanteCobrado ? 'FALTANTE_COBRADO' : 'SOBRANTE_ACEPTADO';

  String get etiqueta => this == TipoAjuste.faltanteCobrado ? 'Faltante' : 'Sobrante';

  static TipoAjuste? desdeCodigo(String codigo) {
    final c = codigo.trim().toUpperCase();
    if (c == 'FALTANTE_COBRADO') return TipoAjuste.faltanteCobrado;
    if (c == 'SOBRANTE_ACEPTADO') return TipoAjuste.sobranteAceptado;
    return null;
  }
}

class AjusteCuadre {
  final ConceptoAjuste concepto;
  final TipoAjuste tipo;
  final int valor;
  final String observacion;
  final DateTime? fecha;

  const AjusteCuadre({
    required this.concepto,
    required this.tipo,
    required this.valor,
    required this.observacion,
    this.fecha,
  });

  static AjusteCuadre? fromJson(Map<String, dynamic> json) {
    final concepto = ConceptoAjusteInfo.desdeCodigo((json['concepto'] ?? '').toString());
    final tipo = TipoAjusteInfo.desdeCodigo((json['tipo'] ?? '').toString());
    if (concepto == null || tipo == null) return null;
    final valor = concepto.esDinero
        ? (parseDouble(json['importe']) ?? 0).round()
        : (parseInt(json['cantidad']) ?? 0);
    return AjusteCuadre(
      concepto: concepto,
      tipo: tipo,
      valor: valor,
      observacion: (json['observacion'] ?? '').toString(),
      fecha: parseDate(json['ajustadoAt']),
    );
  }

  int get valorFirmado => tipo == TipoAjuste.sobranteAceptado ? -valor : valor;
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
  final int averiadosSistema;
  final int averiadosDeclarado;

  const CuadreEnvaseLinea({
    required this.sku,
    required this.etiqueta,
    this.llenosSistema = 0,
    this.llenosDeclarado = 0,
    this.vaciosSistema = 0,
    this.vaciosDeclarado = 0,
    this.averiadosSistema = 0,
    this.averiadosDeclarado = 0,
  });

  int get difLlenos => llenosDeclarado - llenosSistema;
  int get difVacios => vaciosDeclarado - vaciosSistema;
  int get difAveriados => averiadosDeclarado - averiadosSistema;
  bool get cuadraLlenos => difLlenos == 0;
  bool get cuadraVacios => difVacios == 0;
  bool get cuadraAveriados => difAveriados == 0;
  bool get cuadra => cuadraLlenos && cuadraVacios && cuadraAveriados;
  bool get tieneAveriados => averiadosSistema > 0 || averiadosDeclarado > 0;

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
  final Map<ConceptoAjuste, int> saldos;
  final List<AjusteCuadre> ajustes;

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
    this.saldos = const {},
    this.ajustes = const [],
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
    final saldos = <ConceptoAjuste, int>{};
    final sinSaldoBackend = <ConceptoAjuste>{};
    final fin = json['financiero'];
    if (fin is Map<String, dynamic>) {
      for (final r in (fin['rubros'] as List? ?? const [])) {
        if (r is! Map) continue;
        final concepto = (r['concepto'] ?? '').toString().toUpperCase();
        final sistema = (parseDouble(r['sistema']) ?? 0).round();
        final rendido = (parseDouble(r['rendido']) ?? 0).round();
        final conceptoAjuste = ConceptoAjusteInfo.desdeCodigo(concepto);
        if (conceptoAjuste != null) {
          final saldoBackend = parseDouble(r['saldoAjustado']);
          if (saldoBackend == null) sinSaldoBackend.add(conceptoAjuste);
          saldos[conceptoAjuste] = (saldoBackend ?? (rendido - sistema).toDouble()).round();
        }
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

    final declaradoPorSku = <String, List<int>>{};
    for (final n in (json['notasStock'] as List? ?? const [])) {
      if (n is! Map) continue;
      for (final d in (n['detalles'] as List? ?? const [])) {
        if (d is! Map) continue;
        final clave = _claveSku((d['sku'] ?? d['idProducto'] ?? '').toString());
        if (clave.isEmpty) continue;
        final acumulado = declaradoPorSku.putIfAbsent(clave, () => [0, 0, 0]);
        acumulado[0] += parseInt(d['llenosEntrada']) ?? 0;
        acumulado[1] += parseInt(d['vaciosEntrada']) ?? 0;
        acumulado[2] += parseInt(d['averiadosEntrada']) ?? 0;
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
        final declarado = declaradoPorSku[_claveSku(sku)] ??
            declaradoPorSku[_claveSku((r['idProducto'] ?? '').toString())] ??
            const [0, 0, 0];
        envases.add(CuadreEnvaseLinea(
          sku: sku,
          etiqueta: CuadreEnvaseLinea._etiquetaDeSku(sku),
          llenosSistema: llenosEsp,
          llenosDeclarado: declarado[0],
          vaciosSistema: vaciosEsp,
          vaciosDeclarado: declarado[1],
          averiadosSistema: danadosEsp,
          averiadosDeclarado: declarado[2],
        ));
      }
    }

    final rendicion = json['rendicion'];
    final hayRendicion = rendicion is Map && rendicion.isNotEmpty;
    var observaciones = '';
    if (rendicion is Map) {
      observaciones = (rendicion['observacionesChofer'] ?? '').toString();
    }

    final ajustes = (json['ajustes'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(AjusteCuadre.fromJson)
        .whereType<AjusteCuadre>()
        .toList();

    for (final a in ajustes) {
      if (!a.concepto.esDinero || !sinSaldoBackend.contains(a.concepto)) continue;
      saldos[a.concepto] = (saldos[a.concepto] ?? 0) + a.valorFirmado;
    }

    if (rendicion is Map) {
      final teorico = rendicion['teoricoEnvases'];
      if (teorico is Map) {
        final baseEnvases = <ConceptoAjuste, int>{
          ConceptoAjuste.vacios: (parseInt(rendicion['cantidadVaciosRendidos']) ?? 0) -
              (parseInt(teorico['vaciosEsperadosRetorno']) ?? 0),
          ConceptoAjuste.llenos: (parseInt(rendicion['cantidadLlenosDevueltos']) ?? 0) -
              (parseInt(teorico['llenosEsperadosRetorno']) ?? 0),
          ConceptoAjuste.danados: (parseInt(rendicion['cantidadDanadosRendidos']) ?? 0) -
              (parseInt(teorico['danadosEsperadosRetorno']) ?? 0),
        };
        for (final a in ajustes) {
          if (a.concepto.esDinero) continue;
          baseEnvases[a.concepto] = (baseEnvases[a.concepto] ?? 0) + a.valorFirmado;
        }
        saldos.addAll(baseEnvases);
      }
    }

    final bloqueos = <String>[
      for (final b in (json['bloqueos'] as List? ?? const []))
        if (b != null && !_bloqueosIgnorados.contains(b.toString().trim().toUpperCase())) b.toString(),
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
      saldos: saldos,
      ajustes: ajustes,
    );
  }

  bool get aprobadaORutaCerrada => rutaBloqueada || aprobada;

  List<MapEntry<ConceptoAjuste, int>> get saldosPendientes => [
        for (final c in ConceptoAjuste.values)
          if ((saldos[c] ?? 0) != 0) MapEntry(c, saldos[c]!),
      ];

  int get totalDeclaradoValores =>
      efectivoDeclarado + chequesDeclarado + transferenciasDeclarado;

  int get totalSistemaValores =>
      efectivoSistema + chequesSistema + transferenciasSistema;

  int get totalLlenosDeclarado =>
      envases.fold(0, (a, e) => a + e.llenosDeclarado);
  int get totalVaciosDeclarado =>
      envases.fold(0, (a, e) => a + e.vaciosDeclarado);

  bool get aprobada {
    final e = estado.toUpperCase();
    return e == 'APROBADA' || e == 'CONCILIADO';
  }
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
