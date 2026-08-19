/// Formatea una hora en formato 12hs con AM/PM (ej: "09:30 AM"), sin
/// depender del paquete `intl`.
String formatHora12(DateTime fecha) {
  final hora24 = fecha.hour;
  final minuto = fecha.minute.toString().padLeft(2, '0');
  final periodo = hora24 >= 12 ? 'PM' : 'AM';
  var hora12 = hora24 % 12;
  if (hora12 == 0) hora12 = 12;
  return '${hora12.toString().padLeft(2, '0')}:$minuto $periodo';
}

String formatFechaCorta(DateTime fecha) {
  return '${fecha.day}/${fecha.month}/${fecha.year}';
}
