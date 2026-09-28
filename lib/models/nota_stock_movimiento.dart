import '../utils/json_parsing.dart';

class NotaStockMovimiento {
  final int idMovimiento;
  final String tipo;
  final DateTime? fechaHora;
  final String? nombreOperador;
  final String? observaciones;
  final List<Map<String, dynamic>> items;

  const NotaStockMovimiento({
    required this.idMovimiento,
    required this.tipo,
    this.fechaHora,
    this.nombreOperador,
    this.observaciones,
    this.items = const [],
  });

  bool get esCargaInicial => tipo.toUpperCase() == 'CARGA_INICIAL';

  bool get esRecarga => tipo.toUpperCase() == 'RECARGA';

  factory NotaStockMovimiento.fromJson(Map<String, dynamic> json) {
    final items = json['items'];
    final observaciones = json['observaciones']?.toString();
    final operador = json['nombreOperador']?.toString();
    return NotaStockMovimiento(
      idMovimiento: parseInt(json['idMovimiento']) ?? 0,
      tipo: (json['tipo'] ?? '').toString(),
      fechaHora: parseDate(json['fechaHora']),
      nombreOperador: operador == null || operador.isEmpty ? null : operador,
      observaciones: observaciones == null || observaciones.isEmpty ? null : observaciones,
      items: items is List ? items.whereType<Map<String, dynamic>>().toList() : const [],
    );
  }
}
