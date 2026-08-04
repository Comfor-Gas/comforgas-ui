import '../utils/json_parsing.dart';


class EvidenciaFotograficaModel {
  final int? idFotografia;
  final int idVisita;
  final String tipoEvidencia;
  final String? observaciones;
  final String urlAlmacenamiento;
  final DateTime? timestampCaptura;
  final DateTime? createdAt;

  const EvidenciaFotograficaModel({
    this.idFotografia,
    required this.idVisita,
    required this.tipoEvidencia,
    this.observaciones,
    required this.urlAlmacenamiento,
    this.timestampCaptura,
    this.createdAt,
  });

  factory EvidenciaFotograficaModel.fromJson(Map<String, dynamic> json) {
    return EvidenciaFotograficaModel(
      idFotografia: parseInt(json['idFotografia']),
      idVisita: parseInt(json['idVisita']) ?? 0,
      tipoEvidencia: (json['tipoEvidencia'] ?? '').toString(),
      observaciones: json['observaciones'] as String?,
      urlAlmacenamiento: (json['urlAlmacenamiento'] ?? '').toString(),
      timestampCaptura: parseDate(json['timestampCaptura']),
      createdAt: parseDate(json['createdAt']),
    );
  }

  Map<String, String> toUpdateFields() {
    return {
      if (tipoEvidencia.isNotEmpty) 'tipoEvidencia': tipoEvidencia,
      if (observaciones != null) 'observaciones': observaciones!,
    };
  }

  EvidenciaFotograficaModel copyWith({
    int? idFotografia,
    int? idVisita,
    String? tipoEvidencia,
    String? observaciones,
    String? urlAlmacenamiento,
    DateTime? timestampCaptura,
    DateTime? createdAt,
  }) {
    return EvidenciaFotograficaModel(
      idFotografia: idFotografia ?? this.idFotografia,
      idVisita: idVisita ?? this.idVisita,
      tipoEvidencia: tipoEvidencia ?? this.tipoEvidencia,
      observaciones: observaciones ?? this.observaciones,
      urlAlmacenamiento: urlAlmacenamiento ?? this.urlAlmacenamiento,
      timestampCaptura: timestampCaptura ?? this.timestampCaptura,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
