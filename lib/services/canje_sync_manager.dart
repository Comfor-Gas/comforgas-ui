import 'dart:async';
import 'package:http/http.dart' as http;
import '../local/canje_offline_service.dart';
import '../local/canje_pendiente.dart';
import '../models/canje_garrafa.dart';
import '../repositories/canje_repository.dart';
import '../repositories/network_exception.dart';
import '../repositories/visita_repository.dart';
import 'connectivity_service.dart';

class CanjeSyncManager {
  CanjeSyncManager._();

  static final CanjeSyncManager instance = CanjeSyncManager._();

  final _queue = CanjeOfflineService.instance;
  final _connectivity = ConnectivityService.instance;

  CanjeRepository? _repo;
  VisitaRepository? _visitaRepo;
  StreamSubscription<bool>? _conexionSub;
  bool _sincronizando = false;
  bool _pendienteReintento = false;

  final _estadoController = StreamController<bool>.broadcast();

  Stream<bool> get sincronizando => _estadoController.stream;

  void configurar(http.Client apiClient) {
    _repo = CanjeRepository(apiClient);
    _visitaRepo = VisitaRepository(apiClient);

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
    _visitaRepo = null;
  }

  int get cantidadPendiente => _queue.cantidadPendiente;

  Future<void> sincronizar() async {
    final repo = _repo;
    final visitaRepo = _visitaRepo;
    if (repo == null || visitaRepo == null) return;
    if (_sincronizando) {
      _pendienteReintento = true;
      return;
    }

    final pendientes = _queue.listarPendientes();
    if (pendientes.isEmpty) return;
    if (!await _connectivity.tieneConexion()) return;

    _sincronizando = true;
    _estadoController.add(true);
    try {
      for (final pendiente in pendientes) {
        final continuar = await _procesar(repo, visitaRepo, pendiente);
        if (!continuar) break;
      }
    } finally {
      _sincronizando = false;
      _estadoController.add(false);
      if (_pendienteReintento) {
        _pendienteReintento = false;
        unawaited(sincronizar());
      }
    }
  }

  Future<bool> _procesar(
    CanjeRepository repo,
    VisitaRepository visitaRepo,
    CanjePendiente pendiente,
  ) async {
    final idVisita = pendiente.idVisita ?? await _resolverIdVisita(visitaRepo, pendiente);
    if (idVisita == null) return true;

    final draft = _draftDe(pendiente, idVisita);
    try {
      await repo.registrarCanje(idVisita, draft);
      await _queue.eliminar(pendiente.uuidOffline);
      return true;
    } on NetworkException {
      return false;
    } on CanjeRepositoryException catch (e) {
      await _queue.registrarError(pendiente.uuidOffline, e.message);
      await _queue.eliminar(pendiente.uuidOffline);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<int?> _resolverIdVisita(
    VisitaRepository visitaRepo,
    CanjePendiente pendiente,
  ) async {
    final fecha = pendiente.fecha;
    if (pendiente.idUsuario.isEmpty || fecha == null) return null;
    try {
      final items = await visitaRepo.getVisitasPorUsuarioYFecha(
        idUsuario: pendiente.idUsuario,
        fecha: fecha,
      );
      for (final item in items) {
        if (item.idAgendaItem == pendiente.idAgendaItem) {
          return item.idVisita;
        }
      }
    } on NetworkException {
      return null;
    } on VisitaRepositoryException {
      return null;
    } catch (_) {
      return null;
    }
    return null;
  }

  CanjeGarrafaDraft _draftDe(CanjePendiente p, int idVisita) {
    return CanjeGarrafaDraft(
      idVisita: idVisita,
      idAgendaItem: p.idAgendaItem,
      idUsuario: p.idUsuario,
      fecha: p.fecha,
      idClienteExt: p.idClienteExt,
      uuidOffline: p.uuidOffline,
      productoId: p.productoId,
      sku: p.sku,
      descripcion: p.descripcion,
      kg: p.kg,
      descripcionDanio: p.descripcionDanio,
      timestamp: p.timestamp,
    );
  }

  void dispose() {
    _conexionSub?.cancel();
    _estadoController.close();
  }
}
