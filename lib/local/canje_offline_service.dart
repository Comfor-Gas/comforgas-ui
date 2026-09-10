import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:hive_flutter/hive_flutter.dart';
import 'canje_pendiente.dart';

class CanjeOfflineService {
  CanjeOfflineService._();

  static final CanjeOfflineService instance = CanjeOfflineService._();
  static const String boxName = 'canjes_garrafa_pendientes';

  Box<CanjePendiente>? _box;

  Future<void> init() async {
    if (!Hive.isAdapterRegistered(CanjePendienteAdapter().typeId)) {
      Hive.registerAdapter(CanjePendienteAdapter());
    }
    _box = await Hive.openBox<CanjePendiente>(boxName);
  }

  Box<CanjePendiente> get _requireBox {
    final box = _box;
    if (box == null) {
      throw StateError('CanjeOfflineService.init() no fue llamado.');
    }
    return box;
  }

  Future<void> encolar(CanjePendiente canje) async {
    await _requireBox.put(canje.uuidOffline, canje);
  }

  List<CanjePendiente> listarPendientes() {
    final canjes = _requireBox.values.toList();
    canjes.sort((a, b) => a.creadoEn.compareTo(b.creadoEn));
    return canjes;
  }

  List<CanjePendiente> pendientesDeVisita(int idVisita) =>
      listarPendientes().where((c) => c.idVisita == idVisita).toList();

  List<CanjePendiente> pendientesDeAgendaItem(int idAgendaItem) =>
      listarPendientes().where((c) => c.idAgendaItem == idAgendaItem).toList();

  int get cantidadPendiente => _requireBox.length;

  ValueListenable<Box<CanjePendiente>> escuchar() => _requireBox.listenable();

  Future<void> eliminar(String uuidOffline) async {
    await _requireBox.delete(uuidOffline);
  }

  Future<void> registrarError(String uuidOffline, String mensaje) async {
    final canje = _requireBox.get(uuidOffline);
    if (canje == null) return;
    await _requireBox.put(
      uuidOffline,
      canje.copyWith(intentos: canje.intentos + 1, ultimoError: mensaje),
    );
  }
}
