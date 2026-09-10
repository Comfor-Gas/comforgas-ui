import '../utils/json_parsing.dart';

class EstadoGarrafa {
  final int id;
  final String codigo;
  final String descripcion;

  const EstadoGarrafa({
    required this.id,
    required this.codigo,
    required this.descripcion,
  });

  factory EstadoGarrafa.fromJson(Map<String, dynamic> json) {
    return EstadoGarrafa(
      id: parseInt(json['idEstadoGarrafa']) ?? parseInt(json['id']) ?? 0,
      codigo: (json['codigo'] ?? '').toString(),
      descripcion: (json['descripcion'] ?? '').toString(),
    );
  }
}
