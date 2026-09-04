import '../utils/json_parsing.dart';

class SucursalModel {
  final int idSucursal;
  final int? idClienteExt;
  final String nombre;
  final String? direccion;
  final String? barrio;
  final String? ciudad;
  final String? telefono;
  final double? latitud;
  final double? longitud;
  final bool activo;

  const SucursalModel({
    required this.idSucursal,
    this.idClienteExt,
    required this.nombre,
    this.direccion,
    this.barrio,
    this.ciudad,
    this.telefono,
    this.latitud,
    this.longitud,
    this.activo = true,
  });

  factory SucursalModel.fromJson(Map<String, dynamic> json) {
    return SucursalModel(
      idSucursal: parseInt(json['idCliente']) ?? parseInt(json['idSucursal']) ?? 0,
      idClienteExt: parseInt(json['idClienteExt']),
      nombre: (json['nombre'] ?? '').toString(),
      direccion: json['direccion'] as String?,
      barrio: json['barrio'] as String?,
      ciudad: json['ciudad'] as String?,
      telefono: json['telefono'] as String?,
      latitud: parseDouble(json['latitud']),
      longitud: parseDouble(json['longitud']),
      activo: json['activo'] as bool? ?? true,
    );
  }
}
