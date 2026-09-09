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
