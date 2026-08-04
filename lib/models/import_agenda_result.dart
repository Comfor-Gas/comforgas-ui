import '../utils/json_parsing.dart';

class ImportAgendaResult {
  final int totalRecibidas;
  final int insertadas;
  final int omitidas;
  final List<String> errores;

  const ImportAgendaResult({
    required this.totalRecibidas,
    required this.insertadas,
    required this.omitidas,
    required this.errores,
  });

  factory ImportAgendaResult.fromJson(Map<String, dynamic> json) {
    return ImportAgendaResult(
      totalRecibidas: parseInt(json['totalRecibidas']) ?? 0,
      insertadas: parseInt(json['insertadas']) ?? 0,
      omitidas: parseInt(json['omitidas']) ?? 0,
      errores: (json['errores'] as List?)?.whereType<String>().toList() ??
          const [],
    );
  }
}
