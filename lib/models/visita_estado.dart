enum VisitaEstado {pendiente,enCurso,completada,cancelada,noAsistio,inactivo,unknown}

class VisitaEstadoMapper {
  VisitaEstadoMapper._();

  static VisitaEstado fromValue(dynamic value) {
    if (value == null) return VisitaEstado.unknown;

    final normalized = value.toString().trim().toUpperCase();
    switch (normalized) {
      case 'PENDIENTE':
        return VisitaEstado.pendiente;
      case 'EN_CURSO':
        return VisitaEstado.enCurso;
      case 'COMPLETADA':
        return VisitaEstado.completada;
      case 'CANCELADA':
        return VisitaEstado.cancelada;
      case 'NO_ASISTIO':
        return VisitaEstado.noAsistio;
      case 'INACTIVO':
        return VisitaEstado.inactivo;
      default:
        return VisitaEstado.unknown;
    }
  }

  static String toValue(VisitaEstado estado) {
    switch (estado) {
      case VisitaEstado.pendiente:
        return 'PENDIENTE';
      case VisitaEstado.enCurso:
        return 'EN_CURSO';
      case VisitaEstado.completada:
        return 'COMPLETADA';
      case VisitaEstado.cancelada:
        return 'CANCELADA';
      case VisitaEstado.noAsistio:
        return 'NO_ASISTIO';
      case VisitaEstado.inactivo:
        return 'INACTIVO';
      case VisitaEstado.unknown:
        return 'PENDIENTE';
    }
  }
}
