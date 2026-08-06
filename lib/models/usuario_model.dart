import '../utils/json_parsing.dart';

class UsuarioModel {
  final String id;
  final String email;
  final String fullName;
  final String rol;
  final DateTime? createdAt;

  const UsuarioModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.rol,
    this.createdAt,
  });

  factory UsuarioModel.fromJson(Map<String, dynamic> json) {
    return UsuarioModel(
      id: (json['id'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      fullName: (json['fullName'] ?? '').toString(),
      rol: (json['rol'] ?? '').toString(),
      createdAt: parseDate(json['createdAt']),
    );
  }
}
