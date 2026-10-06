import '../utils/json_parsing.dart';

class AdministradorCuenta {
  final String id;
  final String email;
  final String nombre;
  final String rol;
  final DateTime? creadoEl;
  final bool? principalBackend;

  const AdministradorCuenta({
    required this.id,
    required this.email,
    required this.nombre,
    required this.rol,
    this.creadoEl,
    this.principalBackend,
  });

  String get nombreMostrado => nombre.trim().isEmpty ? email : nombre.trim();

  factory AdministradorCuenta.fromJson(Map<String, dynamic> json) {
    final principal = json['esPrincipal'] ?? json['principal'] ?? json['protegido'];
    return AdministradorCuenta(
      id: (json['id'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      nombre: (json['fullName'] ?? json['nombre'] ?? '').toString(),
      rol: (json['rol'] ?? '').toString(),
      creadoEl: parseDate(json['createdAt']),
      principalBackend: principal is bool ? principal : null,
    );
  }
}

String? idAdministradorPrincipal(List<AdministradorCuenta> cuentas) {
  if (cuentas.isEmpty) return null;
  for (final c in cuentas) {
    if (c.principalBackend == true) return c.id;
  }
  if (cuentas.any((c) => c.principalBackend != null)) return null;
  final ordenadas = [...cuentas]..sort((a, b) {
      final fa = a.creadoEl;
      final fb = b.creadoEl;
      if (fa == null && fb == null) return a.email.compareTo(b.email);
      if (fa == null) return 1;
      if (fb == null) return -1;
      return fa.compareTo(fb);
    });
  return ordenadas.first.id;
}
