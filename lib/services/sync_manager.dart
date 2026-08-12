import 'dart:async';
import 'package:http/http.dart' as http;
import '../local/offline_queue_service.dart';
import '../repositories/network_exception.dart';
import '../repositories/sincronizacion_repository.dart';
import 'connectivity_service.dart';

class SyncManager {
  SyncManager._();

  static final SyncManager instance = SyncManager._();
  final _queue = OfflineQueueService.instance;
  final _connectivity = ConnectivityService.instance;

  SincronizacionRepository? _repo;
  bool _sincronizando = false;

  final _estadoController = StreamController<bool>.broadcast();

  Stream<bool> get sincronizando => _estadoController.stream;
  void configurar(http.Client apiClient) {
    _repo = SincronizacionRepository(apiClient);
    _connectivity.escucharReconexion(() {
      sincronizar();
    });
    sincronizar();
  }


  void detener() {
    _connectivity.detener();
    _repo = null;
  }

  int get cantidadPendiente => _queue.cantidadPendiente;

  Future<SincronizacionLoteResultado?> sincronizar() async {
    final repo = _repo;
    if (_sincronizando || repo == null) return null;

    final pendientes = _queue.listarPendientes();
    if (pendientes.isEmpty) return null;

    if (!await _connectivity.tieneConexion()) return null;

    _sincronizando = true;
    _estadoController.add(true);
    try {
      final resultado = await repo.sincronizarLote(pendientes);

      for (final item in resultado.resultados) {
        if (item.resueltoEnBackend) {
          await _queue.eliminar(item.uuidOffline);
        } else {
          await _queue.registrarError(
            item.uuidOffline,
            item.mensaje ?? 'Error desconocido al sincronizar.',
          );
        }
      }

      return resultado;
    } on NetworkException {
      return null;
    } catch (_) {
      return null;
    } finally {
      _sincronizando = false;
      _estadoController.add(false);
    }
  }

  void dispose() {
    _connectivity.detener();
    _estadoController.close();
  }
}
