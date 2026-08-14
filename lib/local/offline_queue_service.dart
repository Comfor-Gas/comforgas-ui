import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:hive_flutter/hive_flutter.dart';
import 'offline_evento.dart';

class OfflineQueueService {
  OfflineQueueService._();

  static final OfflineQueueService instance = OfflineQueueService._();
  static const String boxName = 'offline_eventos_visita';

  Box<OfflineEvento>? _box;


  Future<void> init() async {
    if (!Hive.isAdapterRegistered(OfflineEventoAdapter().typeId)) {
      Hive.registerAdapter(OfflineEventoAdapter());
    }
    _box = await Hive.openBox<OfflineEvento>(boxName);
  }

  Box<OfflineEvento> get _requireBox {
    final box = _box;
    if (box == null) {
      throw StateError(
        'OfflineQueueService.init() no fue llamado antes de usar la cola offline.',
      );
    }
    return box;
  }

  Future<void> encolar(OfflineEvento evento) async {
    await _requireBox.put(evento.uuidOffline, evento);
  }

  List<OfflineEvento> listarPendientes() {
    final eventos = _requireBox.values.toList();
    eventos.sort((a, b) => a.creadoEn.compareTo(b.creadoEn));
    return eventos;
  }


  List<OfflineEvento> pendientesDeVisita(int idVisita) {
    return listarPendientes().where((e) => e.idVisita == idVisita).toList();
  }

  List<OfflineEvento> pendientesDeAgendaItem(int idAgendaItem) {
    return listarPendientes().where((e) => e.idAgendaItem == idAgendaItem).toList();
  }

  bool tienePendientes(int idVisita) => pendientesDeVisita(idVisita).isNotEmpty;

  bool tienePendientesAgendaItem(int idAgendaItem) =>
      pendientesDeAgendaItem(idAgendaItem).isNotEmpty;

  int get cantidadPendiente => _requireBox.length;


  ValueListenable<Box<OfflineEvento>> escuchar() => _requireBox.listenable();

  Future<void> eliminar(String uuidOffline) async {
    await _requireBox.delete(uuidOffline);
  }

  Future<void> registrarError(String uuidOffline, String mensaje) async {
    final evento = _requireBox.get(uuidOffline);
    if (evento == null) return;
    await _requireBox.put(
      uuidOffline,
      evento.copyWith(intentos: evento.intentos + 1, ultimoError: mensaje),
    );
  }
}
