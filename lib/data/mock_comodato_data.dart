import '../models/control_comodato.dart';

const bool kComodatoMock = true;

ContratoComodato mockContratoComodato(int? idClienteExt) {
  return ContratoComodato(
    idContrato: 9001,
    idClienteExt: idClienteExt,
    version: 1,
    detalles: const [
      DetalleContratoComodato(tipoEnvase: 'GARRAFA 10KG', cantidadContratada: 10),
      DetalleContratoComodato(tipoEnvase: 'GARRAFA 12KG', cantidadContratada: 4),
    ],
    cantidadContratadaTotal: 14,
    observaciones: null,
  );
}

List<ControlComodato> mockAuditoriaComodato({bool soloFaltantes = true}) {
  final hoy = DateTime.now();
  final todos = [
    _mockControl(1, 'García, Juan', 101, hoy, [
      ['GARRAFA 10KG', 10, 8],
      ['GARRAFA 12KG', 4, 4],
    ], 'Cliente informa 2 envases rotos, asume costo.'),
    _mockControl(2, 'Ruiz, Liliana', 102, hoy, [
      ['GARRAFA 10KG', 10, 10],
      ['GARRAFA 12KG', 4, 4],
    ], null),
    _mockControl(3, 'Peralta, Carmen', 103, hoy, [
      ['GARRAFA 10KG', 20, 15],
    ], 'Faltan 5 cilindros en depósito.'),
    _mockControl(4, 'Chamorro, Moira', 104, hoy, [
      ['GARRAFA 10KG', 6, 7],
    ], null),
  ];
  if (soloFaltantes) return todos.where((c) => c.tieneFaltante).toList();
  return todos;
}

ControlComodato _mockControl(
  int id,
  String chofer,
  int idClienteExt,
  DateTime fecha,
  List<List<Object>> tipos,
  String? observaciones,
) {
  final detalles = <DetalleControlComodato>[];
  int contratada = 0;
  int fisica = 0;
  int faltante = 0;
  bool tieneFaltante = false;
  for (final t in tipos) {
    final tipo = t[0] as String;
    final c = t[1] as int;
    final f = t[2] as int;
    final falt = c > f ? c - f : 0;
    final tiene = f < c;
    contratada += c;
    fisica += f;
    faltante += falt;
    tieneFaltante = tieneFaltante || tiene;
    detalles.add(DetalleControlComodato(
      tipoEnvase: tipo,
      cantidadContratada: c,
      cantidadFisicaActual: f,
      cantidadFaltante: falt,
      tieneFaltante: tiene,
      estadoConteo: 'CONTADO',
    ));
  }
  return ControlComodato(
    idControl: id,
    idVisita: id,
    idClienteExt: idClienteExt,
    idChofer: 'chofer-$id',
    nombreChofer: chofer,
    fechaControl: fecha,
    timestampCaptura: fecha,
    estado: 'COMPLETO',
    detalles: detalles,
    cantidadContratadaTotal: contratada,
    cantidadFisicaTotal: fisica,
    cantidadFaltanteTotal: faltante,
    tieneFaltante: tieneFaltante,
    observaciones: observaciones,
    uuidOffline: null,
  );
}

ControlComodato mockControlDesdeDraft(ControlComodatoDraft draft) {
  final detalles = draft.detalles.map((d) {
    final fisica = d.cantidadFisicaActual;
    final contado = fisica != null;
    final tieneFaltante = contado && fisica < d.cantidadContratada;
    final faltante = !contado
        ? null
        : (d.cantidadContratada > fisica ? d.cantidadContratada - fisica : 0);
    return DetalleControlComodato(
      tipoEnvase: d.tipoEnvase,
      cantidadContratada: d.cantidadContratada,
      cantidadFisicaActual: fisica,
      cantidadFaltante: faltante,
      tieneFaltante: tieneFaltante,
      estadoConteo: contado ? 'CONTADO' : 'PENDIENTE',
    );
  }).toList();

  return ControlComodato(
    idControl: 8001,
    idVisita: draft.idVisita,
    idClienteExt: draft.idClienteExt,
    nombreChofer: null,
    timestampCaptura: draft.timestampCaptura,
    estado: draft.completo ? 'COMPLETO' : 'PARCIAL',
    detalles: detalles,
    cantidadContratadaTotal: draft.contratadaTotal,
    cantidadFisicaTotal: draft.fisicaTotal,
    cantidadFaltanteTotal: draft.faltanteTotal,
    tieneFaltante: draft.faltanteTotal > 0,
    observaciones: draft.observaciones,
    uuidOffline: draft.uuidOffline,
  );
}
