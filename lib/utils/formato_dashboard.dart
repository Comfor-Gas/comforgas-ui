import 'formato.dart';

String formatEntero(num valor) {
  final negativo = valor < 0;
  final digitos = valor.abs().round().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digitos.length; i++) {
    if (i > 0 && (digitos.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digitos[i]);
  }
  return '${negativo ? '-' : ''}$buffer';
}

String formatPorcentaje(num valor, {int decimales = 1}) {
  final texto = valor.toStringAsFixed(decimales).replaceAll('.', ',');
  final limpio = texto.endsWith(',0') ? texto.substring(0, texto.length - 2) : texto;
  return '$limpio %';
}

String formatMonedaCompacta(num valor) {
  final abs = valor.abs();
  if (abs >= 1000000) {
    return '\$${(valor / 1000000).toStringAsFixed(abs >= 10000000 ? 0 : 1).replaceAll('.', ',')} M';
  }
  if (abs >= 10000) {
    return '\$${(valor / 1000).toStringAsFixed(0)} k';
  }
  return formatMoneda(valor);
}

String formatDiaMes(DateTime fecha) {
  final d = fecha.day.toString().padLeft(2, '0');
  final m = fecha.month.toString().padLeft(2, '0');
  return '$d/$m';
}

String formatFechaDashboard(DateTime fecha) => '${formatDiaMes(fecha)}/${fecha.year}';
