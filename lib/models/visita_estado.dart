enum VisitaEstado {pendiente,enCurso,visitado,completada,cancelada,noAsistio,inactivo,unknown}

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
      // Estado resultante del check-out del chofer en campo
      // (VisitaServiceImpl.checkOut → EstadoVisita.VISITADO).
      case 'VISITADO':
        return VisitaEstado.visitado;
      // Cierre administrativo posterior al VISITADO (opcional, backend).
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

  /// Una visita se considera "terminada en campo" (el chofer ya la resolvió)
  /// cuando está en VISITADO (check-out de campo) o COMPLETADA (cierre
  /// administrativo posterior). Se usa para agrupar la agenda del chofer
  /// en "pendientes" vs "Clientes Visitados".
  static bool esTerminadaEnCampo(VisitaEstado estado) {
    return estado == VisitaEstado.visitado || estado == VisitaEstado.completada;
  }
}
