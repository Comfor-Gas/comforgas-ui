import 'dart:convert';
import '../utils/json_parsing.dart';

class DetalleContratoComodato {
  final String tipoEnvase;
  final int cantidadContratada;

  const DetalleContratoComodato({
    required this.tipoEnvase,
    required this.cantidadContratada,
  });

  factory DetalleContratoComodato.fromJson(Map<String, dynamic> json) {
    return DetalleContratoComodato(
      tipoEnvase: (json['tipo_envase'] ?? json['tipoEnvase'] ?? '').toString(),
      cantidadContratada: parseInt(json['cantidad_contratada']) ??
          parseInt(json['cantidadContratada']) ??
          0,
    );
  }
}

class ContratoComodato {
  final int? idContrato;
  final int? idClienteExt;
  final int? version;
  final List<DetalleContratoComodato> detalles;
  final int cantidadContratadaTotal;
  final String? observaciones;

  const ContratoComodato({
    this.idContrato,
    this.idClienteExt,
    this.version,
    required this.detalles,
    required this.cantidadContratadaTotal,
    this.observaciones,
  });

  factory ContratoComodato.fromJson(Map<String, dynamic> json) {
    final lista = (json['detalles'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(DetalleContratoComodato.fromJson)
        .toList();
    final total = parseInt(json['cantidad_contratada_total']) ??
        parseInt(json['cantidadContratadaTotal']) ??
        lista.fold<int>(0, (a, d) => a + d.cantidadContratada);
    return ContratoComodato(
      idContrato: parseInt(json['id_contrato']) ?? parseInt(json['idContrato']),
      idClienteExt:
          parseInt(json['id_cliente_ext']) ?? parseInt(json['idClienteExt']),
      version: parseInt(json['numero_version']) ?? parseInt(json['version']),
      detalles: lista,
      cantidadContratadaTotal: total,
      observaciones: json['observaciones'] as String?,
    );
  }
}

class DetalleControlComodato {
  final String tipoEnvase;
  final int cantidadContratada;
  final int? cantidadFisicaActual;
  final int? cantidadFaltante;
  final bool tieneFaltante;
  final String estadoConteo;

  const DetalleControlComodato({
    required this.tipoEnvase,
    required this.cantidadContratada,
    this.cantidadFisicaActual,
    this.cantidadFaltante,
    required this.tieneFaltante,
    required this.estadoConteo,
  });

  factory DetalleControlComodato.fromJson(Map<String, dynamic> json) {
    return DetalleControlComodato(
      tipoEnvase: (json['tipo_envase'] ?? json['tipoEnvase'] ?? '').toString(),
      cantidadContratada: parseInt(json['cantidad_contratada']) ??
          parseInt(json['cantidadContratada']) ??
          0,
      cantidadFisicaActual: parseInt(json['cantidad_fisica_actual']) ??
          parseInt(json['cantidadFisicaActual']),
      cantidadFaltante:
          parseInt(json['cantidad_faltante']) ?? parseInt(json['cantidadFaltante']),
      tieneFaltante:
          (json['tiene_faltante'] ?? json['tieneFaltante'] ?? false) == true,
      estadoConteo:
          (json['estado_conteo'] ?? json['estadoConteo'] ?? 'PENDIENTE').toString(),
    );
  }
}

class ControlComodato {
  final int? idControl;
  final int? idVisita;
  final int? idClienteExt;
  final String? idChofer;
  final String? nombreChofer;
  final DateTime? fechaControl;
  final DateTime? timestampCaptura;
  final String? estado;
  final List<DetalleControlComodato> detalles;
  final int cantidadContratadaTotal;
  final int cantidadFisicaTotal;
  final int cantidadFaltanteTotal;
  final bool tieneFaltante;
  final String? observaciones;
  final String? uuidOffline;

  const ControlComodato({
    this.idControl,
    this.idVisita,
    this.idClienteExt,
    this.idChofer,
    this.nombreChofer,
    this.fechaControl,
    this.timestampCaptura,
    this.estado,
    required this.detalles,
    required this.cantidadContratadaTotal,
    required this.cantidadFisicaTotal,
    required this.cantidadFaltanteTotal,
    required this.tieneFaltante,
    this.observaciones,
    this.uuidOffline,
  });

  factory ControlComodato.fromJson(Map<String, dynamic> json) {
    final lista = (json['detalles'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(DetalleControlComodato.fromJson)
        .toList();
    return ControlComodato(
      idControl: parseInt(json['id_control']) ?? parseInt(json['idControl']),
      idVisita: parseInt(json['id_visita']) ?? parseInt(json['idVisita']),
      idClienteExt:
          parseInt(json['id_cliente_ext']) ?? parseInt(json['idClienteExt']),
      idChofer: (json['id_chofer'] ?? json['idChofer'])?.toString(),
      nombreChofer: (json['nombre_chofer'] ?? json['nombreChofer']) as String?,
      fechaControl:
          parseDate(json['fecha_control']) ?? parseDate(json['fechaControl']),
      timestampCaptura: parseDate(json['timestamp_captura']) ??
          parseDate(json['timestampCaptura']),
      estado: json['estado'] as String?,
      detalles: lista,
      cantidadContratadaTotal: parseInt(json['cantidad_contratada_total']) ??
          parseInt(json['cantidadContratadaTotal']) ??
          0,
      cantidadFisicaTotal: parseInt(json['cantidad_fisica_total']) ??
          parseInt(json['cantidadFisicaTotal']) ??
          0,
      cantidadFaltanteTotal: parseInt(json['cantidad_faltante_total']) ??
          parseInt(json['cantidadFaltanteTotal']) ??
          0,
      tieneFaltante:
          (json['tiene_faltante'] ?? json['tieneFaltante'] ?? false) == true,
      observaciones: json['observaciones'] as String?,
      uuidOffline: (json['uuid_offline'] ?? json['uuidOffline']) as String?,
    );
  }
}

class DetalleControlDraft {
  final String tipoEnvase;
  final int cantidadContratada;
  final int? cantidadFisicaActual;

  const DetalleControlDraft({
    required this.tipoEnvase,
    required this.cantidadContratada,
    this.cantidadFisicaActual,
  });

  bool get contado => cantidadFisicaActual != null;

  int get faltante {
    final fisica = cantidadFisicaActual;
    if (fisica == null) return 0;
    final dif = cantidadContratada - fisica;
    return dif > 0 ? dif : 0;
  }

  DetalleControlDraft copyWith({int? cantidadFisicaActual, bool contado = true}) {
    return DetalleControlDraft(
      tipoEnvase: tipoEnvase,
      cantidadContratada: cantidadContratada,
      cantidadFisicaActual: contado ? cantidadFisicaActual : null,
    );
  }

  Map<String, dynamic> toStorageJson() {
    return {
      'tipoEnvase': tipoEnvase,
      'cantidadContratada': cantidadContratada,
      'cantidadFisicaActual': cantidadFisicaActual,
    };
  }

  factory DetalleControlDraft.fromStorageJson(Map<String, dynamic> json) {
    return DetalleControlDraft(
      tipoEnvase: (json['tipoEnvase'] ?? '').toString(),
      cantidadContratada: parseInt(json['cantidadContratada']) ?? 0,
      cantidadFisicaActual: parseInt(json['cantidadFisicaActual']),
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
  final DateTime timestampCaptura;
  final String? observaciones;
  final List<DetalleControlDraft> detalles;

  const ControlComodatoDraft({
    this.idVisita,
    this.idAgendaItem,
    required this.idUsuario,
    this.fecha,
    this.idClienteExt,
    required this.uuidOffline,
    required this.timestampCaptura,
    this.observaciones,
    required this.detalles,
  });

  int get contratadaTotal =>
      detalles.fold(0, (a, d) => a + d.cantidadContratada);

  int get fisicaTotal =>
      detalles.fold(0, (a, d) => a + (d.cantidadFisicaActual ?? 0));

  int get faltanteTotal => detalles.fold(0, (a, d) => a + d.faltante);

  bool get tieneFaltante => faltanteTotal > 0;

  bool get completo => detalles.every((d) => d.contado);

  factory ControlComodatoDraft.desdeContrato(
    ContratoComodato contrato, {
    required String idUsuario,
    required String uuidOffline,
    required DateTime timestampCaptura,
    int? idVisita,
    int? idAgendaItem,
    DateTime? fecha,
    String? observaciones,
  }) {
    return ControlComodatoDraft(
      idVisita: idVisita,
      idAgendaItem: idAgendaItem,
      idUsuario: idUsuario,
      fecha: fecha,
      idClienteExt: contrato.idClienteExt,
      uuidOffline: uuidOffline,
      timestampCaptura: timestampCaptura,
      observaciones: observaciones,
      detalles: contrato.detalles
          .map((d) => DetalleControlDraft(
                tipoEnvase: d.tipoEnvase,
                cantidadContratada: d.cantidadContratada,
                cantidadFisicaActual: d.cantidadContratada,
              ))
          .toList(),
    );
  }

  ControlComodatoDraft copyWith({
    int? idVisita,
    List<DetalleControlDraft>? detalles,
    String? observaciones,
  }) {
    return ControlComodatoDraft(
      idVisita: idVisita ?? this.idVisita,
      idAgendaItem: idAgendaItem,
      idUsuario: idUsuario,
      fecha: fecha,
      idClienteExt: idClienteExt,
      uuidOffline: uuidOffline,
      timestampCaptura: timestampCaptura,
      observaciones: observaciones ?? this.observaciones,
      detalles: detalles ?? this.detalles,
    );
  }

  Map<String, dynamic> toRequestJson() {
    return {
      'detalles': detalles
          .map((d) => {
                'tipoEnvase': d.tipoEnvase,
                if (d.cantidadFisicaActual != null)
                  'cantidadFisicaActual': d.cantidadFisicaActual,
              })
          .toList(),
      'timestampCaptura': timestampCaptura.toUtc().toIso8601String(),
      'uuidOffline': uuidOffline,
      if (observaciones != null && observaciones!.trim().isNotEmpty)
        'observaciones': observaciones!.trim(),
    };
  }

  String detallesStorageJson() {
    return jsonEncode(detalles.map((d) => d.toStorageJson()).toList());
  }

  static List<DetalleControlDraft> detallesDesdeStorage(String raw) {
    if (raw.isEmpty) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(DetalleControlDraft.fromStorageJson)
        .toList();
  }
}
