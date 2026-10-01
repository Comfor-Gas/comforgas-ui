import '../utils/json_parsing.dart';

class ChoferCuenta {
  final String idUsuario;
  final String email;
  final String nombre;
  final String? idChoferExterno;
  final String? documento;
  final DateTime? createdAt;

  const ChoferCuenta({
    required this.idUsuario,
    required this.email,
    required this.nombre,
    this.idChoferExterno,
    this.documento,
    this.createdAt,
  });

  String get nombreMostrado => nombre.trim().isNotEmpty ? nombre.trim() : email;

  factory ChoferCuenta.fromJson(Map<String, dynamic> json) {
    String? texto(dynamic v) {
      final s = v?.toString().trim();
      return s == null || s.isEmpty ? null : s;
    }

    return ChoferCuenta(
      idUsuario: (json['idUsuario'] ?? json['id'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      nombre: (json['nombre'] ?? json['fullName'] ?? '').toString(),
      idChoferExterno: texto(json['idChoferExterno'] ?? json['externalDriverId']),
      documento: texto(json['documento']),
      createdAt: parseDate(json['createdAt']),
    );
  }
}
