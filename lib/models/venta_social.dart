import 'dart:convert';
import '../utils/json_parsing.dart';

class EnvaseSocialEntregado {
  final String idProducto;
  final String sku;
  final String descripcion;
  final int kg;
  final int cantidadEntregada;
  final int precioUnitario;

  const EnvaseSocialEntregado({
    required this.idProducto,
    required this.sku,
    required this.descripcion,
    required this.kg,
    required this.cantidadEntregada,
    required this.precioUnitario,
  });

  String get etiqueta {
    if (descripcion.trim().isNotEmpty) return descripcion.trim();
    if (kg > 0) return 'Garrafa $kg kg';
    return sku;
  }

  Map<String, dynamic> _snapshot() => {
        'sku': sku,
        'descripcion': descripcion,
        'precio': precioUnitario,
      };

  Map<String, dynamic> toItemPausaJson() => {
        'idProducto': idProducto,
        'cantidadEntregada': cantidadEntregada,
        'precioUnitario': precioUnitario,
        'productoSnapshot': _snapshot(),
      };

  Map<String, dynamic> toStorageJson() => {
        'idProducto': idProducto,
        'sku': sku,
        'descripcion': descripcion,
        'kg': kg,
        'cantidadEntregada': cantidadEntregada,
        'precioUnitario': precioUnitario,
      };

  factory EnvaseSocialEntregado.fromStorageJson(Map<String, dynamic> json) {
    return EnvaseSocialEntregado(
      idProducto: (json['idProducto'] ?? '').toString(),
      sku: (json['sku'] ?? '').toString(),
      descripcion: (json['descripcion'] ?? '').toString(),
      kg: parseInt(json['kg']) ?? 0,
      cantidadEntregada: parseInt(json['cantidadEntregada']) ?? 0,
      precioUnitario: parseInt(json['precioUnitario']) ?? 0,
    );
  }
}

class PausaSocialDraft {
  final List<EnvaseSocialEntregado> items;
  final String uuidOffline;
  final DateTime timestamp;

  const PausaSocialDraft({
    required this.items,
    required this.uuidOffline,
    required this.timestamp,
  });

  int get totalEntregado =>
      items.fold(0, (a, i) => a + i.cantidadEntregada);

  Map<String, dynamic> toRequestJson() => {
        'items': items.map((i) => i.toItemPausaJson()).toList(),
        'cantidadEntregada': totalEntregado,
        'timestampOrigen': timestamp.toUtc().toIso8601String(),
        'uuidOffline': uuidOffline,
      };

  Map<String, dynamic> toEventoOfflineJson() => {
        'items': items.map((i) => i.toItemPausaJson()).toList(),
        'cantidadEntregada': totalEntregado,
      };

  String toStorageJson() => jsonEncode({
        'uuidOffline': uuidOffline,
        'timestamp': timestamp.toIso8601String(),
        'items': items.map((i) => i.toStorageJson()).toList(),
      });

  static PausaSocialDraft? fromStorageJson(String raw) {
    if (raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      final lista = (decoded['items'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(EnvaseSocialEntregado.fromStorageJson)
          .toList();
      return PausaSocialDraft(
        items: lista,
        uuidOffline: (decoded['uuidOffline'] ?? '').toString(),
        timestamp: parseDate(decoded['timestamp']) ?? DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }
}

class PausaSocialResult {
  final String? estadoVisita;
  final int envasesEntregadosSocial;

  const PausaSocialResult({
    this.estadoVisita,
    this.envasesEntregadosSocial = 0,
  });

  factory PausaSocialResult.fromJson(Map<String, dynamic> json) {
    return PausaSocialResult(
      estadoVisita: (json['estadoVisita'] ?? json['estado_visita'])?.toString(),
      envasesEntregadosSocial:
          parseInt(json['envasesEntregadosSocial']) ?? parseInt(json['envases_entregados_social']) ?? 0,
    );
  }
}

class RetornoSocialItem {
  final EnvaseSocialEntregado entregado;
  final int llenosRetornados;
  final int vaciosRecuperados;

  const RetornoSocialItem({
    required this.entregado,
    required this.llenosRetornados,
    required this.vaciosRecuperados,
  });

  int get devueltos => llenosRetornados + vaciosRecuperados;
  int get vendidos => entregado.cantidadEntregada - llenosRetornados;
  bool get cuadra => devueltos == entregado.cantidadEntregada;

  Map<String, dynamic> toItemReanudarJson() => {
        'idProducto': entregado.idProducto,
        'llenosRetornados': llenosRetornados,
        'vaciosRecuperados': vaciosRecuperados,
        'precioUnitario': entregado.precioUnitario,
        'inconsistente': !cuadra,
        'productoSnapshot': {
          'sku': entregado.sku,
          'descripcion': entregado.descripcion,
          'precio': entregado.precioUnitario,
        },
      };
}

class ReanudarSocialDraft {
  final List<RetornoSocialItem> items;
  final String uuidOffline;
  final DateTime timestamp;

  const ReanudarSocialDraft({
    required this.items,
    required this.uuidOffline,
    required this.timestamp,
  });

  int get totalLlenos => items.fold(0, (a, i) => a + i.llenosRetornados);
  int get totalVacios => items.fold(0, (a, i) => a + i.vaciosRecuperados);
  int get totalVendidos => items.fold(0, (a, i) => a + i.vendidos);
  int get montoVendidoLocal =>
      items.fold(0, (a, i) => a + i.vendidos * i.entregado.precioUnitario);
  bool get cuadra => items.every((i) => i.cuadra);
  bool get esUnicoSku => items.length == 1;

  Map<String, dynamic> toRequestJson() {
    if (esUnicoSku) {
      final it = items.first;
      return {
        'llenosRetornados': it.llenosRetornados,
        'vaciosRecuperados': it.vaciosRecuperados,
        'idProducto': it.entregado.idProducto,
        'precioUnitario': it.entregado.precioUnitario,
        'inconsistente': !cuadra,
        'productoSnapshot': {
          'sku': it.entregado.sku,
          'descripcion': it.entregado.descripcion,
          'precio': it.entregado.precioUnitario,
        },
        'timestampOrigen': timestamp.toUtc().toIso8601String(),
        'uuidOffline': uuidOffline,
      };
    }
    return {
      'llenosRetornados': totalLlenos,
      'vaciosRecuperados': totalVacios,
      'inconsistente': !cuadra,
      'items': items.map((i) => i.toItemReanudarJson()).toList(),
      'timestampOrigen': timestamp.toUtc().toIso8601String(),
      'uuidOffline': uuidOffline,
    };
  }

  Map<String, dynamic> toEventoOfflineJson() {
    if (esUnicoSku) {
      final it = items.first;
      return {
        'llenosRetornados': it.llenosRetornados,
        'vaciosRecuperados': it.vaciosRecuperados,
        'idProducto': it.entregado.idProducto,
        'precioUnitario': it.entregado.precioUnitario,
        'inconsistente': !cuadra,
        'productoSnapshot': {
          'sku': it.entregado.sku,
          'descripcion': it.entregado.descripcion,
          'precio': it.entregado.precioUnitario,
        },
      };
    }
    return {
      'llenosRetornados': totalLlenos,
      'vaciosRecuperados': totalVacios,
      'inconsistente': !cuadra,
      'items': items.map((i) => i.toItemReanudarJson()).toList(),
    };
  }
}

class ReanudarSocialResult {
  final String? estadoVisita;
  final int envasesVendidos;
  final int? idVenta;
  final int montoTotal;
  final String? estadoVenta;

  const ReanudarSocialResult({
    this.estadoVisita,
    this.envasesVendidos = 0,
    this.idVenta,
    this.montoTotal = 0,
    this.estadoVenta,
  });

  bool get tieneVenta => idVenta != null;

  factory ReanudarSocialResult.fromJson(Map<String, dynamic> json) {
    final venta = json['venta'];
    int? idVenta;
    int monto = 0;
    String? estadoVenta;
    if (venta is Map<String, dynamic>) {
      idVenta = parseInt(venta['idVenta']) ?? parseInt(venta['id_venta']);
      monto = parseInt(venta['montoTotal']) ?? parseInt(venta['monto_total']) ?? 0;
      estadoVenta = (venta['estadoVenta'] ?? venta['estado_venta'])?.toString();
    }
    return ReanudarSocialResult(
      estadoVisita: (json['estadoVisita'] ?? json['estado_visita'])?.toString(),
      envasesVendidos: parseInt(json['envasesVendidos']) ?? parseInt(json['envases_vendidos']) ?? 0,
      idVenta: idVenta,
      montoTotal: monto,
      estadoVenta: estadoVenta,
    );
  }
}
