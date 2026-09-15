import 'package:hive_flutter/hive_flutter.dart';
import '../models/venta_social.dart';

class VentaSocialLocalService {
  VentaSocialLocalService._();

  static final VentaSocialLocalService instance = VentaSocialLocalService._();
  static const String boxName = 'venta_social_pausas';

  Box<String>? _box;

  Future<void> init() async {
    _box = await Hive.openBox<String>(boxName);
  }

  Box<String> get _requireBox {
    final box = _box;
    if (box == null) {
      throw StateError('VentaSocialLocalService.init() no fue llamado.');
    }
    return box;
  }

  Future<void> guardar(int idAgendaItem, PausaSocialDraft draft) async {
    await _requireBox.put('$idAgendaItem', draft.toStorageJson());
  }

  PausaSocialDraft? obtener(int idAgendaItem) {
    final raw = _requireBox.get('$idAgendaItem');
    if (raw == null || raw.isEmpty) return null;
    return PausaSocialDraft.fromStorageJson(raw);
  }

  Future<void> eliminar(int idAgendaItem) async {
    await _requireBox.delete('$idAgendaItem');
  }

  Future<void> marcarFinalizada(int idAgendaItem) async {
    await _requireBox.put('fin_$idAgendaItem', DateTime.now().toIso8601String());
  }

  bool estaFinalizada(int idAgendaItem) {
    final raw = _requireBox.get('fin_$idAgendaItem');
    return raw != null && raw.isNotEmpty;
  }
}
