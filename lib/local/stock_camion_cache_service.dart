import 'dart:convert';
import 'package:hive/hive.dart';
import '../models/stock_camion.dart';

class StockCamionCacheService {
  StockCamionCacheService._();

  static final StockCamionCacheService instance = StockCamionCacheService._();

  static const String boxName = 'stock_camion_cache';

  Box<String>? _box;

  Future<void> init() async {
    _box = await Hive.openBox<String>(boxName);
  }

  Box<String> get _requireBox {
    final box = _box;
    if (box == null) {
      throw StateError(
        'StockCamionCacheService.init() no fue llamado antes de usarlo.',
      );
    }
    return box;
  }

  Future<void> guardar(String idUsuario, StockCamion stock) async {
    await _requireBox.put(idUsuario, jsonEncode(stock.toJson()));
  }

  StockCamion? obtener(String idUsuario) {
    final raw = _requireBox.get(idUsuario);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return StockCamion.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }
}
