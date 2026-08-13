enum VisitaAlertaTipo { ninguna, gpsDesvio, fueraDeHorario, clienteSalteado }

class VisitaAlertaMapper {
  VisitaAlertaMapper._();

  static VisitaAlertaTipo fromValue(dynamic value) {
    if (value == null) return VisitaAlertaTipo.ninguna;
    final normalized = value.toString().trim().toUpperCase();
    switch (normalized) {
      case 'GPS_DESVIO':
      case 'DESVIO_GPS':
        return VisitaAlertaTipo.gpsDesvio;
      case 'FUERA_DE_HORARIO':
        return VisitaAlertaTipo.fueraDeHorario;
      case 'CLIENTE_SALTEADO':
      case 'CLIENTE_SALTADO':
        return VisitaAlertaTipo.clienteSalteado;
      default:
        return VisitaAlertaTipo.ninguna;
    }
  }

  static String toValue(VisitaAlertaTipo tipo) {
    switch (tipo) {
      case VisitaAlertaTipo.gpsDesvio:
        return 'GPS_DESVIO';
      case VisitaAlertaTipo.fueraDeHorario:
        return 'FUERA_DE_HORARIO';
      case VisitaAlertaTipo.clienteSalteado:
        return 'CLIENTE_SALTEADO';
      case VisitaAlertaTipo.ninguna:
        return '';
    }
  }

  static String label(VisitaAlertaTipo tipo) {
    switch (tipo) {
      case VisitaAlertaTipo.gpsDesvio:
        return 'GPS Desvío';
      case VisitaAlertaTipo.fueraDeHorario:
        return 'Fuera de Horario';
      case VisitaAlertaTipo.clienteSalteado:
        return 'Cliente Salteado';
      case VisitaAlertaTipo.ninguna:
        return '';
    }
  }
}
