import 'dart:convert';
import 'package:hive/hive.dart';

class MetasCacheadas {
  final Map<String, dynamic> json;
  final DateTime obtenidoEn;

  const MetasCacheadas(this.json, this.obtenidoEn);
}

class MetasChoferCacheService {
  MetasChoferCacheService._();

  static final MetasChoferCacheService instance = MetasChoferCacheService._();

  static const String boxName = 'metas_chofer_cache';

  Box<String>? _box;

  Future<void> init() async {
    _box = await Hive.openBox<String>(boxName);
  }

  Future<void> guardar(String idUsuario, Map<String, dynamic> json) async {
    final box = _box;
    if (box == null) return;
    await box.put(
      idUsuario,
      jsonEncode({'obtenidoEn': DateTime.now().toIso8601String(), 'datos': json}),
    );
  }

  MetasCacheadas? obtener(String idUsuario) {
    final raw = _box?.get(idUsuario);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      final obtenido = DateTime.tryParse('${decoded['obtenidoEn']}');
      final datos = decoded['datos'];
      if (obtenido == null || datos is! Map<String, dynamic>) return null;
      final hoy = DateTime.now();
      if (obtenido.year != hoy.year || obtenido.month != hoy.month || obtenido.day != hoy.day) return null;
      return MetasCacheadas(datos, obtenido);
    } catch (_) {
      return null;
    }
  }
}
