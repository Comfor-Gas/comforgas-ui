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

class MockComodato {
  final bool comodato10;
  final bool comodato11;
  final bool comodato12;

  const MockComodato({
    required this.comodato10,
    required this.comodato11,
    required this.comodato12,
  });

  static const MockComodato ninguno =
      MockComodato(comodato10: false, comodato11: false, comodato12: false);
}

MockComodato mockComodatoFor(int idCliente) {
  final base = idCliente.abs();
  if (base % 5 == 0) return MockComodato.ninguno;
  final c10 = base % 2 == 0;
  final c11 = base % 3 == 0;
  final c12 = base % 4 == 0;
  if (!c10 && !c11 && !c12) {
    return const MockComodato(comodato10: true, comodato11: false, comodato12: false);
  }
  return MockComodato(comodato10: c10, comodato11: c11, comodato12: c12);
}

DateTime mockUltimaBajadaFor(int idCliente) {
  final dias = 2 + (idCliente.abs() % 27);
  return DateTime.now().subtract(Duration(days: dias));
}
