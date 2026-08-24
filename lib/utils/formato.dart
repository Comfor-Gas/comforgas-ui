String formatMoneda(num monto) {
  final entero = monto.round();
  final negativo = entero < 0;
  final digitos = entero.abs().toString();

  final buffer = StringBuffer();
  for (int i = 0; i < digitos.length; i++) {
    if (i > 0 && (digitos.length - i) % 3 == 0) {
      buffer.write('.');
    }
    buffer.write(digitos[i]);
  }

  return '${negativo ? '-' : ''}\$${buffer.toString()}';
}
