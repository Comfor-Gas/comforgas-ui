/// Excepción específica para fallas de conectividad (sin señal, timeout,
/// DNS, servidor caído) al intentar una request HTTP — a diferencia de
/// las excepciones de negocio de cada repositorio (401/403/400/etc.),
/// que sí llegaron al servidor y fueron rechazadas.
///
/// Se usa en las pantallas de campo (check-in, evidencia, check-out) para
/// decidir cuándo conviene encolar un evento para sincronización offline
/// en vez de mostrar un error bloqueante: solo tiene sentido reintentar
/// más tarde cuando la falla es de conectividad, no cuando el backend
/// rechazó la operación por una razón de negocio (visita en mal estado,
/// sesión sin permisos, etc.).
class NetworkException implements Exception {
  final String message;

  NetworkException([
    this.message = 'No se pudo conectar con el servidor. Revisa tu conexión.',
  ]);

  @override
  String toString() => message;
}
