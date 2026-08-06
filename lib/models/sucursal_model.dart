import '../utils/json_parsing.dart';


class SucursalModel {
  final int idSucursal;
  final String nombre;
  final String? direccion;
  final String? telefono;
  final bool activo;

  const SucursalModel({
    required this.idSucursal,
    required this.nombre,
    this.direccion,
    this.telefono,
    this.activo = true,
  });

  factory SucursalModel.fromJson(Map<String, dynamic> json) {
    return SucursalModel(
      idSucursal: parseInt(json['idSucursal']) ?? 0,
      nombre: (json['nombre'] ?? '').toString(),
      direccion: json['direccion'] as String?,
      telefono: json['telefono'] as String?,
      activo: json['activo'] as bool? ?? true,
    );
  }
}
