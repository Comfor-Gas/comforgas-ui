import 'dart:convert';
import 'package:hive/hive.dart';
import '../models/stock_rodante_chofer.dart';

class StockRodanteCacheService {
  StockRodanteCacheService._();

  static final StockRodanteCacheService instance = StockRodanteCacheService._();

  static const String boxName = 'stock_rodante_cache';

  Box<String>? _box;

  Future<void> init() async {
    _box = await Hive.openBox<String>(boxName);
  }

  Box<String>? get _safeBox => _box;

  Future<void> guardar(String idUsuario, StockRodanteChofer stock) async {
    final box = _safeBox;
    if (box == null) return;
    await box.put(idUsuario, jsonEncode(stock.toStorageJson()));
  }

  StockRodanteChofer? obtener(String idUsuario) {
    final box = _safeBox;
    if (box == null) return null;
    final raw = box.get(idUsuario);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return StockRodanteChofer.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<void> aplicarSalidas(
    String idUsuario,
    Map<String, int> llenosPorProducto,
  ) async {
    if (llenosPorProducto.isEmpty) return;
    final actual = obtener(idUsuario);
    if (actual == null) return;
    await guardar(idUsuario, actual.aplicarSalidas(llenosPorProducto));
  }
}
