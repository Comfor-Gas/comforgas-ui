import '../utils/json_parsing.dart';

class RutaModel {
  final int idRuta;
  final String nombre;
  final String? descripcion;
  final bool activo;

  const RutaModel({
    required this.idRuta,
    required this.nombre,
    this.descripcion,
    this.activo = true,
  });

  factory RutaModel.fromJson(Map<String, dynamic> json) {
    return RutaModel(
      idRuta: parseInt(json['idRuta']) ?? 0,
      nombre: (json['nombre'] ?? '').toString(),
      descripcion: json['descripcion'] as String?,
      activo: json['activo'] as bool? ?? true,
    );
  }
}
