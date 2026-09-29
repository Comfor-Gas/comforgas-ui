import 'package:hive_flutter/hive_flutter.dart';
import '../models/rendicion_ruta.dart';
import '../utils/json_parsing.dart';

class RendicionLocalService {
  RendicionLocalService._();

  static final RendicionLocalService instance = RendicionLocalService._();
  static const String boxName = 'rendiciones_pendientes';
  static const String boxEnviadas = 'rendiciones_enviadas';

  Box<String>? _box;
  Box<String>? _enviadas;

  Future<void> init() async {
    _box = await Hive.openBox<String>(boxName);
    _enviadas = await Hive.openBox<String>(boxEnviadas);
  }

  Future<void> marcarEnviada(RendicionDraft draft) async {
    await _enviadas?.put(_clave(draft.fecha), draft.toStorageJson());
    await eliminar(draft.fecha);
  }

  RendicionDraft? obtenerEnviada(DateTime fecha) {
    final raw = _enviadas?.get(_clave(fecha));
    if (raw == null || raw.isEmpty) return null;
    return RendicionDraft.fromStorageJson(raw);
  }

  Box<String> get _requireBox {
    final box = _box;
    if (box == null) {
      throw StateError('RendicionLocalService.init() no fue llamado.');
    }
    return box;
  }

  String _clave(DateTime fecha) => formatDateOnly(fecha);

  Future<void> guardar(RendicionDraft draft) async {
    await _requireBox.put(_clave(draft.fecha), draft.toStorageJson());
  }

  RendicionDraft? obtener(DateTime fecha) {
    final raw = _requireBox.get(_clave(fecha));
    if (raw == null || raw.isEmpty) return null;
    return RendicionDraft.fromStorageJson(raw);
  }

  List<RendicionDraft> listarPendientes() {
    final result = <RendicionDraft>[];
    for (final raw in _requireBox.values) {
      final draft = RendicionDraft.fromStorageJson(raw);
      if (draft != null) result.add(draft);
    }
    return result;
  }

  Future<void> eliminar(DateTime fecha) async {
    await _requireBox.delete(_clave(fecha));
  }

  int get cantidadPendiente => _requireBox.length;
}
