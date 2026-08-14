import 'visita_alerta.dart';
import '../utils/json_parsing.dart';

class AlertaModel {
  final int idAlerta;
  final int idVisita;
  final String idChofer;
  final String? nombreChofer;
  final VisitaAlertaTipo? tipo;
  final VisitaAlertaEstado estado;
  final String? descripcion;
  final DateTime? detectadaAt;

  const AlertaModel({
    required this.idAlerta,
    required this.idVisita,
    required this.idChofer,
    this.nombreChofer,
    this.tipo,
    this.estado = VisitaAlertaEstado.abierta,
    this.descripcion,
    this.detectadaAt,
  });

  factory AlertaModel.fromJson(Map<String, dynamic> json) {
    return AlertaModel(
      idAlerta: parseInt(json['idAlerta']) ?? 0,
      idVisita: parseInt(json['idVisita']) ?? 0,
      idChofer: (json['idChofer'] ?? '').toString(),
      nombreChofer: json['nombreChofer'] as String?,
      tipo: VisitaAlertaMapper.fromValue(json['tipo']),
      estado: VisitaAlertaMapper.estadoFromValue(json['estado']),
      descripcion: json['descripcion'] as String?,
      detectadaAt: parseDate(json['detectadaAt']),
    );
  }
}
