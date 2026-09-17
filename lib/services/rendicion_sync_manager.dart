import 'dart:async';
import 'package:http/http.dart' as http;
import '../local/rendicion_local_service.dart';
import '../repositories/network_exception.dart';
import '../repositories/rendicion_repository.dart';
import 'connectivity_service.dart';

class RendicionSyncManager {
  RendicionSyncManager._();

  static final RendicionSyncManager instance = RendicionSyncManager._();

  final _local = RendicionLocalService.instance;
  final _connectivity = ConnectivityService.instance;

  RendicionRepository? _repo;
  StreamSubscription<bool>? _conexionSub;
  bool _sincronizando = false;

  final _estadoController = StreamController<bool>.broadcast();

  Stream<bool> get sincronizando => _estadoController.stream;

  void configurar(http.Client apiClient) {
    _repo = RendicionRepository(apiClient);
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

  int get cantidadPendiente => _local.cantidadPendiente;

  Future<void> sincronizar() async {
    final repo = _repo;
    if (repo == null || _sincronizando) return;

    final pendientes = _local.listarPendientes();
    if (pendientes.isEmpty) return;
    if (!await _connectivity.tieneConexion()) return;

    _sincronizando = true;
    _estadoController.add(true);
    try {
      for (final draft in pendientes) {
        try {
          await repo.enviar(draft);
          await _local.eliminar(draft.fecha);
        } on NetworkException {
          break;
        } on RendicionRepositoryException catch (e) {
          if (e.endpointNoDisponible) break;
        }
      }
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
