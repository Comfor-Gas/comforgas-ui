import '../utils/json_parsing.dart';

class ContratoComodato {
  final int? idCliente;
  final int? idClienteExt;
  final int cantidadContratada;
  final bool tieneComodato;
  final bool comodato10;
  final bool comodato11;
  final bool comodato12;
  final String? observaciones;

  const ContratoComodato({
    this.idCliente,
    this.idClienteExt,
    required this.cantidadContratada,
    required this.tieneComodato,
    this.comodato10 = false,
    this.comodato11 = false,
    this.comodato12 = false,
    this.observaciones,
  });

  static bool _bool(dynamic v) {
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) {
      final n = v.trim().toLowerCase();
      return n == 'true' || n == '1' || n == 'si' || n == 'sí';
    }
    return false;
  }

  static int _sumaDetalles(dynamic detalles) {
    if (detalles is! List) return 0;
    var total = 0;
    for (final d in detalles.whereType<Map<String, dynamic>>()) {
      total += parseInt(d['cantidad_contratada']) ?? parseInt(d['cantidadContratada']) ?? 0;
    }
    return total;
  }

  factory ContratoComodato.fromJson(Map<String, dynamic> json) {
    final cantidad = parseInt(json['cantidad_contratada']) ??
        parseInt(json['cantidadContratada']) ??
        parseInt(json['cantidad_contratada_total']) ??
        parseInt(json['cantidadContratadaTotal']) ??
        _sumaDetalles(json['detalles']);
    final comodato10 = _bool(json['comodato_10'] ?? json['comodato10']);
    final comodato11 = _bool(json['comodato_11'] ?? json['comodato11']);
    final comodato12 = _bool(json['comodato_12'] ?? json['comodato12']);
    return ContratoComodato(
      idCliente: parseInt(json['id_cliente']) ?? parseInt(json['idCliente']),
      idClienteExt:
          parseInt(json['id_cliente_ext']) ?? parseInt(json['idClienteExt']),
      cantidadContratada: cantidad,
      tieneComodato: json.containsKey('tiene_comodato') || json.containsKey('tieneComodato')
          ? _bool(json['tiene_comodato'] ?? json['tieneComodato'])
          : (cantidad > 0 || comodato10 || comodato11 || comodato12),
      comodato10: comodato10,
      comodato11: comodato11,
      comodato12: comodato12,
      observaciones: json['observaciones'] as String?,
    );
  }
}

class ControlComodato {
  final int? idControl;
  final int? idVisita;
  final int? idClienteExt;
  final String? idChofer;
  final String? nombreChofer;
  final int cantidadContratada;
  final int cantidadFisicaActual;
  final int discrepancia;
  final bool tieneFaltante;
  final DateTime? timestampControl;
  final DateTime? timestampRecepcion;
  final String? observaciones;
  final String? uuidOffline;

  const ControlComodato({
    this.idControl,
    this.idVisita,
    this.idClienteExt,
    this.idChofer,
    this.nombreChofer,
    required this.cantidadContratada,
    required this.cantidadFisicaActual,
    required this.discrepancia,
    required this.tieneFaltante,
    this.timestampControl,
    this.timestampRecepcion,
    this.observaciones,
    this.uuidOffline,
  });

  int get faltante => discrepancia > 0 ? discrepancia : 0;
  int get sobrante => discrepancia < 0 ? -discrepancia : 0;

  factory ControlComodato.fromJson(Map<String, dynamic> json) {
    final contratada = parseInt(json['cantidad_contratada']) ??
        parseInt(json['cantidadContratada']) ??
        parseInt(json['cantidad_contratada_total']) ??
        parseInt(json['cantidadContratadaTotal']) ??
        0;
    final fisica = parseInt(json['cantidad_fisica_actual']) ??
        parseInt(json['cantidadFisicaActual']) ??
        parseInt(json['cantidad_fisica_total']) ??
        parseInt(json['cantidadFisicaTotal']) ??
        0;
    final discrepancia = parseInt(json['discrepancia']) ??
        parseInt(json['cantidad_faltante_total']) ??
        parseInt(json['cantidadFaltanteTotal']) ??
        (contratada - fisica);
    return ControlComodato(
      idControl: parseInt(json['id_control']) ?? parseInt(json['idControl']),
      idVisita: parseInt(json['id_visita']) ?? parseInt(json['idVisita']),
      idClienteExt:
          parseInt(json['id_cliente_ext']) ?? parseInt(json['idClienteExt']),
      idChofer: (json['id_chofer'] ?? json['idChofer'])?.toString(),
      nombreChofer: (json['nombre_chofer'] ?? json['nombreChofer']) as String?,
      cantidadContratada: contratada,
      cantidadFisicaActual: fisica,
      discrepancia: discrepancia,
      tieneFaltante: json.containsKey('tiene_faltante') || json.containsKey('tieneFaltante')
          ? ContratoComodato._bool(json['tiene_faltante'] ?? json['tieneFaltante'])
          : discrepancia > 0,
      timestampControl: parseDate(json['timestamp_control']) ??
          parseDate(json['timestampControl']) ??
          parseDate(json['fecha_control']) ??
          parseDate(json['fechaControl']) ??
          parseDate(json['timestamp_captura']) ??
          parseDate(json['timestampCaptura']),
      timestampRecepcion: parseDate(json['timestamp_recepcion']) ??
          parseDate(json['timestampRecepcion']),
      observaciones: json['observaciones'] as String?,
      uuidOffline: (json['uuid_offline'] ?? json['uuidOffline']) as String?,
    );
  }
}

class ControlComodatoDraft {
  final int? idVisita;
  final int? idAgendaItem;
  final String idUsuario;
  final DateTime? fecha;
  final int? idClienteExt;
  final String uuidOffline;
  final DateTime timestampControl;
  final String? observaciones;
  final int cantidadContratada;
  final int cantidadFisicaActual;

  const ControlComodatoDraft({
    this.idVisita,
    this.idAgendaItem,
    required this.idUsuario,
    this.fecha,
    this.idClienteExt,
    required this.uuidOffline,
    required this.timestampControl,
    this.observaciones,
    required this.cantidadContratada,
    required this.cantidadFisicaActual,
  });

  int get faltante {
    final dif = cantidadContratada - cantidadFisicaActual;
    return dif > 0 ? dif : 0;
  }

  int get sobrante {
    final dif = cantidadFisicaActual - cantidadContratada;
    return dif > 0 ? dif : 0;
  }

  bool get tieneFaltante => faltante > 0;

  ControlComodatoDraft copyWith({
    int? idVisita,
    int? cantidadFisicaActual,
    String? observaciones,
  }) {
    return ControlComodatoDraft(
      idVisita: idVisita ?? this.idVisita,
      idAgendaItem: idAgendaItem,
      idUsuario: idUsuario,
      fecha: fecha,
      idClienteExt: idClienteExt,
      uuidOffline: uuidOffline,
      timestampControl: timestampControl,
      observaciones: observaciones ?? this.observaciones,
      cantidadContratada: cantidadContratada,
      cantidadFisicaActual: cantidadFisicaActual ?? this.cantidadFisicaActual,
    );
  }

  Map<String, dynamic> toRequestJson() {
    return {
      if (idVisita != null) 'id_visita': idVisita,
      'cantidad_contratada': cantidadContratada,
      'cantidad_fisica_actual': cantidadFisicaActual,
      'timestamp_control': timestampControl.toUtc().toIso8601String(),
      'uuid_offline': uuidOffline,
      if (observaciones != null && observaciones!.trim().isNotEmpty)
        'observaciones': observaciones!.trim(),
    };
  }
}
