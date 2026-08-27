import '../utils/json_parsing.dart';

class ProductoCatalogo {
  final String idProducto;
  final String sku;
  final String descripcion;
  final double? pesoKg;
  final String tipoProducto;

  const ProductoCatalogo({
    required this.idProducto,
    required this.sku,
    required this.descripcion,
    this.pesoKg,
    this.tipoProducto = '',
  });

  String get etiquetaKg {
    final kg = pesoKg;
    if (kg == null || kg <= 0) return descripcion.isNotEmpty ? descripcion : sku;
    final entero = kg == kg.roundToDouble() ? kg.toInt().toString() : '$kg';
    return '$entero kg';
  }

  factory ProductoCatalogo.fromJson(Map<String, dynamic> json) {
    return ProductoCatalogo(
      idProducto: (json['idProducto'] ?? json['id'] ?? '').toString(),
      sku: (json['sku'] ?? '').toString(),
      descripcion: (json['descripcion'] ?? '').toString(),
      pesoKg: parseDouble(json['pesoKg']),
      tipoProducto: (json['tipoProducto'] ?? '').toString(),
    );
  }
}
