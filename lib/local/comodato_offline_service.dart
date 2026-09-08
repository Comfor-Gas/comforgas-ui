import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:hive_flutter/hive_flutter.dart';
import 'comodato_pendiente.dart';

class ComodatoOfflineService {
  ComodatoOfflineService._();

  static final ComodatoOfflineService instance = ComodatoOfflineService._();
  static const String boxName = 'controles_comodato_pendientes';

  Box<ComodatoPendiente>? _box;

  Future<void> init() async {
    if (!Hive.isAdapterRegistered(ComodatoPendienteAdapter().typeId)) {
      Hive.registerAdapter(ComodatoPendienteAdapter());
    }
    _box = await Hive.openBox<ComodatoPendiente>(boxName);
  }

  Box<ComodatoPendiente> get _requireBox {
    final box = _box;
    if (box == null) {
      throw StateError('ComodatoOfflineService.init() no fue llamado.');
    }
    return box;
  }

  Future<void> encolar(ComodatoPendiente control) async {
    await _requireBox.put(control.uuidOffline, control);
  }

  List<ComodatoPendiente> listarPendientes() {
    final controles = _requireBox.values.toList();
    controles.sort((a, b) => a.creadoEn.compareTo(b.creadoEn));
    return controles;
  }

  ComodatoPendiente? pendienteDeVisita(int idVisita) {
    for (final c in _requireBox.values) {
      if (c.idVisita == idVisita) return c;
    }
    return null;
  }

  ComodatoPendiente? pendienteDeAgendaItem(int idAgendaItem) {
    for (final c in _requireBox.values) {
      if (c.idAgendaItem == idAgendaItem) return c;
    }
    return null;
  }

  bool tienePendienteDeVisita(int idVisita) =>
      pendienteDeVisita(idVisita) != null;

  bool tienePendienteDeAgendaItem(int idAgendaItem) =>
      pendienteDeAgendaItem(idAgendaItem) != null;

  int get cantidadPendiente => _requireBox.length;

  ValueListenable<Box<ComodatoPendiente>> escuchar() => _requireBox.listenable();

  Future<void> eliminar(String uuidOffline) async {
    await _requireBox.delete(uuidOffline);
  }

  Future<void> registrarError(String uuidOffline, String mensaje) async {
    final control = _requireBox.get(uuidOffline);
    if (control == null) return;
    await _requireBox.put(
      uuidOffline,
      control.copyWith(intentos: control.intentos + 1, ultimoError: mensaje),
    );
  }
}
