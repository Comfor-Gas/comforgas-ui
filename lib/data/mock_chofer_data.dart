String mockPatenteFor(String idUsuario) {
  final base = idUsuario.hashCode.abs();
  final letras = String.fromCharCodes([
    65 + (base % 26),
    65 + ((base ~/ 26) % 26),
    65 + ((base ~/ 676) % 26),
  ]);
  final numeros = (100 + (base % 900)).toString();
  return '$letras-$numeros';
}

const double mockMontoPromedioPorVisita = 2500.0;
