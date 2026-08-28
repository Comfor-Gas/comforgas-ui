import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:hive_flutter/hive_flutter.dart';
import 'cobro_pendiente.dart';

class CobroOfflineService {
  CobroOfflineService._();

  static final CobroOfflineService instance = CobroOfflineService._();
  static const String boxName = 'cobros_pendientes';

  Box<CobroPendiente>? _box;

  Future<void> init() async {
    if (!Hive.isAdapterRegistered(CobroPendienteAdapter().typeId)) {
      Hive.registerAdapter(CobroPendienteAdapter());
    }
    _box = await Hive.openBox<CobroPendiente>(boxName);
  }

  Box<CobroPendiente> get _requireBox {
    final box = _box;
    if (box == null) {
      throw StateError('CobroOfflineService.init() no fue llamado.');
    }
    return box;
  }

  Future<void> encolar(CobroPendiente cobro) async {
    await _requireBox.put(cobro.uuidOffline, cobro);
  }

  List<CobroPendiente> listarPendientes() {
    final cobros = _requireBox.values.toList();
    cobros.sort((a, b) => a.creadoEn.compareTo(b.creadoEn));
    return cobros;
  }

  bool tienePendienteDeVenta(int idVenta) =>
      _requireBox.values.any((c) => c.idVenta == idVenta);

  int get cantidadPendiente => _requireBox.length;

  ValueListenable<Box<CobroPendiente>> escuchar() => _requireBox.listenable();

  Future<void> eliminar(String uuidOffline) async {
    await _requireBox.delete(uuidOffline);
  }

  Future<void> registrarError(String uuidOffline, String mensaje) async {
    final cobro = _requireBox.get(uuidOffline);
    if (cobro == null) return;
    await _requireBox.put(
      uuidOffline,
      cobro.copyWith(intentos: cobro.intentos + 1, ultimoError: mensaje),
    );
  }
}
