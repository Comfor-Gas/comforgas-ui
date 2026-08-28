import 'dart:async';
import 'package:http/http.dart' as http;
import '../local/cobro_offline_service.dart';
import '../repositories/cobro_repository.dart';
import '../repositories/network_exception.dart';
import 'connectivity_service.dart';

class CobroSyncManager {
  CobroSyncManager._();

  static final CobroSyncManager instance = CobroSyncManager._();

  final _queue = CobroOfflineService.instance;
  final _connectivity = ConnectivityService.instance;

  CobroRepository? _repo;
  StreamSubscription<bool>? _conexionSub;
  bool _sincronizando = false;

  final _estadoController = StreamController<bool>.broadcast();

  Stream<bool> get sincronizando => _estadoController.stream;

  void configurar(http.Client apiClient) {
    _repo = CobroRepository(apiClient);
    _conexionSub?.cancel();
    _conexionSub = _connectivity.observarConexion().listen((online) {
      if (online) sincronizar();
    });
    sincronizar();
  }

  void detener() {
    _conexionSub?.cancel();
    _conexionSub = null;
    _repo = null;
  }

  int get cantidadPendiente => _queue.cantidadPendiente;

  Future<void> sincronizar() async {
    final repo = _repo;
    if (_sincronizando || repo == null) return;

    final pendientes = _queue.listarPendientes();
    if (pendientes.isEmpty) return;
    if (!await _connectivity.tieneConexion()) return;

    _sincronizando = true;
    _estadoController.add(true);
    try {
      final resultado = await repo.sincronizarLote(pendientes);
      for (final uuid in resultado.resueltos) {
        await _queue.eliminar(uuid);
      }
      for (final entry in resultado.errores.entries) {
        await _queue.registrarError(entry.key, entry.value);
      }
    } on NetworkException {
      return;
    } catch (_) {
      return;
    } finally {
      _sincronizando = false;
      _estadoController.add(false);
    }
  }

  void dispose() {
    _conexionSub?.cancel();
    _estadoController.close();
  }
}
