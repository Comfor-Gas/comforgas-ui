/// Helpers de parseo tolerantes usados por los modelos de datos
/// compartidos entre la app Web (Admin) y la app Móvil (Chofer).
///
/// El backend puede devolver fechas/números en formatos ligeramente
/// distintos según el endpoint; estas funciones evitan repetir la misma
/// lógica defensiva en cada modelo.
library;

DateTime? parseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}

double? parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  return double.tryParse(value.toString());
}

int? parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.toInt();
  return int.tryParse(value.toString());
}

/// Formatea una fecha como 'yyyy-MM-dd' (sin hora), el formato que
/// normalmente espera un path param de tipo LocalDate en el backend.
String formatDateOnly(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}
