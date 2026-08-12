import 'dart:async';

import 'package:http/http.dart' as http;

import '../local/offline_queue_service.dart';
import '../repositories/network_exception.dart';
import '../repositories/sincronizacion_repository.dart';
import 'connectivity_service.dart';

/// Coordina el envío de la cola offline hacia `POST /api/visitas/sync-lote`:
/// escucha la reconexión de red, evita sincronizaciones concurrentes, y
/// depura del almacenamiento local los eventos que el backend confirma
/// como PROCESADO u OMITIDO (los que vuelven ERROR se conservan para el
/// próximo intento).
class SyncManager {
  SyncManager._();

  static final SyncManager instance = SyncManager._();

  final _queue = OfflineQueueService.instance;
  final _connectivity = ConnectivityService.instance;

  SincronizacionRepository? _repo;
  bool _sincronizando = false;

  final _estadoController = StreamController<bool>.broadcast();

  /// Emite `true` mientras hay una sincronización en curso, `false` al
  /// terminar. Útil para mostrar un spinner en la agenda.
  Stream<bool> get sincronizando => _estadoController.stream;

  /// Debe llamarse cuando el usuario queda autenticado (o al arrancar la
  /// app si ya había sesión), pasando el cliente HTTP autenticado
  /// (`AuthProvider.apiClient`) para que las requests de sync lleven el
  /// token vigente.
  void configurar(http.Client apiClient) {
    _repo = SincronizacionRepository(apiClient);
    _connectivity.escucharReconexion(() {
      sincronizar();
    });
    // Intento inicial por si ya hay eventos pendientes de una sesión
    // anterior y ya hay señal al abrir la app.
    sincronizar();
  }

  /// Se llama al cerrar sesión: deja de escuchar reconexión hasta que
  /// haya un usuario autenticado de nuevo.
  void detener() {
    _connectivity.detener();
    _repo = null;
  }

  int get cantidadPendiente => _queue.cantidadPendiente;

  /// Intenta sincronizar la cola pendiente. No hace nada si ya hay una
  /// sincronización en curso, si no hay eventos pendientes, o si no hay
  /// conectividad de red detectada.
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
      // Falso positivo de conectividad (ej. WiFi conectado sin salida a
      // internet, o el backend no responde): no tocamos la cola, se
      // reintenta en la próxima reconexión o intento manual.
      return null;
    } catch (_) {
      // Error de backend (401/403/500/etc.): tampoco tocamos la cola.
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
