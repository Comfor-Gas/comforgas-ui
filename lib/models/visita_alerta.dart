enum VisitaAlertaTipo {
  desvioGeografico,
  desvioTemporal,
  paradaFueraDeOrden,
  omisionNoJustificada,
  incidenciaCampo,
  coordenadasAusentes,
  coordenadasInvalidas,
  faltanteGarrafas,
}

enum VisitaAlertaEstado { abierta, resuelta, descartada }

class VisitaAlertaMapper {
  VisitaAlertaMapper._();

  static VisitaAlertaTipo? fromValue(dynamic value) {
    if (value == null) return null;
    switch (value.toString().trim().toUpperCase()) {
      case 'DESVIO_GEOGRAFICO':
        return VisitaAlertaTipo.desvioGeografico;
      case 'DESVIO_TEMPORAL':
        return VisitaAlertaTipo.desvioTemporal;
      case 'PARADA_FUERA_DE_ORDEN':
        return VisitaAlertaTipo.paradaFueraDeOrden;
      case 'OMISION_NO_JUSTIFICADA':
        return VisitaAlertaTipo.omisionNoJustificada;
      case 'INCIDENCIA_CAMPO':
        return VisitaAlertaTipo.incidenciaCampo;
      case 'COORDENADAS_AUSENTES':
        return VisitaAlertaTipo.coordenadasAusentes;
      case 'COORDENADAS_INVALIDAS':
        return VisitaAlertaTipo.coordenadasInvalidas;
      case 'FALTANTE_GARRAFAS':
        return VisitaAlertaTipo.faltanteGarrafas;
      default:
        return null;
    }
  }

  static String toValue(VisitaAlertaTipo tipo) {
    switch (tipo) {
      case VisitaAlertaTipo.desvioGeografico:
        return 'DESVIO_GEOGRAFICO';
      case VisitaAlertaTipo.desvioTemporal:
        return 'DESVIO_TEMPORAL';
      case VisitaAlertaTipo.paradaFueraDeOrden:
        return 'PARADA_FUERA_DE_ORDEN';
      case VisitaAlertaTipo.omisionNoJustificada:
        return 'OMISION_NO_JUSTIFICADA';
      case VisitaAlertaTipo.incidenciaCampo:
        return 'INCIDENCIA_CAMPO';
      case VisitaAlertaTipo.coordenadasAusentes:
        return 'COORDENADAS_AUSENTES';
      case VisitaAlertaTipo.coordenadasInvalidas:
        return 'COORDENADAS_INVALIDAS';
      case VisitaAlertaTipo.faltanteGarrafas:
        return 'FALTANTE_GARRAFAS';
    }
  }

  static String label(VisitaAlertaTipo tipo) {
    switch (tipo) {
      case VisitaAlertaTipo.desvioGeografico:
        return 'Desvío GPS';
      case VisitaAlertaTipo.desvioTemporal:
        return 'Fuera de Horario';
      case VisitaAlertaTipo.paradaFueraDeOrden:
        return 'Parada Fuera de Orden';
      case VisitaAlertaTipo.omisionNoJustificada:
        return 'Cliente Salteado';
      case VisitaAlertaTipo.incidenciaCampo:
        return 'Incidencia en Campo';
      case VisitaAlertaTipo.coordenadasAusentes:
        return 'Sin Coordenadas';
      case VisitaAlertaTipo.coordenadasInvalidas:
        return 'Coordenadas Inválidas';
      case VisitaAlertaTipo.faltanteGarrafas:
        return 'Faltante de Garrafas';
    }
  }

  static VisitaAlertaEstado estadoFromValue(dynamic value) {
    switch (value.toString().trim().toUpperCase()) {
      case 'RESUELTA':
        return VisitaAlertaEstado.resuelta;
      case 'DESCARTADA':
        return VisitaAlertaEstado.descartada;
      default:
        return VisitaAlertaEstado.abierta;
    }
  }
}
