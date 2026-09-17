import 'dart:convert';
import '../utils/json_parsing.dart';

class RendicionEnvaseItem {
  final String idProducto;
  final String sku;
  final String etiqueta;
  final int vaciosRecuperados;
  final int llenosNoVendidos;
  final int averiados;

  const RendicionEnvaseItem({
    required this.idProducto,
    required this.sku,
    required this.etiqueta,
    this.vaciosRecuperados = 0,
    this.llenosNoVendidos = 0,
    this.averiados = 0,
  });

  int get total => vaciosRecuperados + llenosNoVendidos + averiados;

  bool get tieneMovimiento => total > 0;

  Map<String, dynamic> toRequestJson() => {
        'idProducto': idProducto,
        'sku': sku,
        'vaciosRecuperados': vaciosRecuperados,
        'llenosNoVendidos': llenosNoVendidos,
        'averiados': averiados,
      };

  Map<String, dynamic> toStorageJson() => {
        'idProducto': idProducto,
        'sku': sku,
        'etiqueta': etiqueta,
        'vaciosRecuperados': vaciosRecuperados,
        'llenosNoVendidos': llenosNoVendidos,
        'averiados': averiados,
      };

  factory RendicionEnvaseItem.fromStorageJson(Map<String, dynamic> json) {
    return RendicionEnvaseItem(
      idProducto: (json['idProducto'] ?? '').toString(),
      sku: (json['sku'] ?? '').toString(),
      etiqueta: (json['etiqueta'] ?? '').toString(),
      vaciosRecuperados: parseInt(json['vaciosRecuperados']) ?? 0,
      llenosNoVendidos: parseInt(json['llenosNoVendidos']) ?? 0,
      averiados: parseInt(json['averiados']) ?? 0,
    );
  }
}

class RendicionDraft {
  final String uuidOffline;
  final DateTime fecha;
  final DateTime timestamp;
  final int efectivo;
  final int cheques;
  final int transferencias;
  final String observaciones;
  final List<RendicionEnvaseItem> envases;

  const RendicionDraft({
    required this.uuidOffline,
    required this.fecha,
    required this.timestamp,
    this.efectivo = 0,
    this.cheques = 0,
    this.transferencias = 0,
    this.observaciones = '',
    this.envases = const [],
  });

  int get totalValores => efectivo + cheques + transferencias;

  int get totalVacios => envases.fold(0, (a, e) => a + e.vaciosRecuperados);
  int get totalLlenos => envases.fold(0, (a, e) => a + e.llenosNoVendidos);
  int get totalAveriados => envases.fold(0, (a, e) => a + e.averiados);
  int get totalGarrafas => totalVacios + totalLlenos + totalAveriados;

  bool get tieneAlgoParaEnviar => totalValores > 0 || totalGarrafas > 0;

  Map<String, dynamic> toRequestJson() => {
        'uuidOffline': uuidOffline,
        'fecha': formatDateOnly(fecha),
        'timestampOrigen': timestamp.toUtc().toIso8601String(),
        'observaciones': observaciones,
        'valores': {
          'efectivo': efectivo,
          'cheques': cheques,
          'transferencias': transferencias,
        },
        'envases': envases.map((e) => e.toRequestJson()).toList(),
      };

  String toStorageJson() => jsonEncode({
        'uuidOffline': uuidOffline,
        'fecha': fecha.toIso8601String(),
        'timestamp': timestamp.toIso8601String(),
        'efectivo': efectivo,
        'cheques': cheques,
        'transferencias': transferencias,
        'observaciones': observaciones,
        'envases': envases.map((e) => e.toStorageJson()).toList(),
      });

  static RendicionDraft? fromStorageJson(String raw) {
    if (raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      final lista = (decoded['envases'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(RendicionEnvaseItem.fromStorageJson)
          .toList();
      return RendicionDraft(
        uuidOffline: (decoded['uuidOffline'] ?? '').toString(),
        fecha: parseDate(decoded['fecha']) ?? DateTime.now(),
        timestamp: parseDate(decoded['timestamp']) ?? DateTime.now(),
        efectivo: parseInt(decoded['efectivo']) ?? 0,
        cheques: parseInt(decoded['cheques']) ?? 0,
        transferencias: parseInt(decoded['transferencias']) ?? 0,
        observaciones: (decoded['observaciones'] ?? '').toString(),
        envases: lista,
      );
    } catch (_) {
      return null;
    }
  }
}
