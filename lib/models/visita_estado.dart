enum VisitaEstado {pendiente,enCurso,pausadaSocial,visitado,completada,cancelada,noAsistio,inactivo,unknown}

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
      case 'PAUSADA_SOCIAL':
        return VisitaEstado.pausadaSocial;
      case 'VISITADO':
        return VisitaEstado.visitado;
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
      case VisitaEstado.pausadaSocial:
        return 'PAUSADA_SOCIAL';
      case VisitaEstado.visitado:
        return 'VISITADO';
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

  /// Indica si la visita ya "terminó" desde la perspectiva del chofer en
  /// campo, es decir si ya hizo check-out (o el estado avanzó más allá de
  /// eso). Se usa para separar las visitas pendientes de las completadas
  /// en la agenda del chofer.
  ///
  /// Espeja a `EstadoVisita.esTerminal()` del backend: todo menos
  /// PENDIENTE y EN_CURSO.
  static bool esTerminadaEnCampo(VisitaEstado estado) {
    switch (estado) {
      case VisitaEstado.visitado:
      case VisitaEstado.completada:
      case VisitaEstado.cancelada:
      case VisitaEstado.noAsistio:
      case VisitaEstado.inactivo:
        return true;
      case VisitaEstado.pendiente:
      case VisitaEstado.enCurso:
      case VisitaEstado.pausadaSocial:
      case VisitaEstado.unknown:
        return false;
    }
  }
}
