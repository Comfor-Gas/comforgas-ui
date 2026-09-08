import 'dart:async';
import 'package:http/http.dart' as http;
import '../local/comodato_offline_service.dart';
import '../local/comodato_pendiente.dart';
import '../models/control_comodato.dart';
import '../repositories/comodato_repository.dart';
import '../repositories/network_exception.dart';
import '../repositories/visita_repository.dart';
import 'connectivity_service.dart';

class ComodatoSyncManager {
  ComodatoSyncManager._();

  static final ComodatoSyncManager instance = ComodatoSyncManager._();

  final _queue = ComodatoOfflineService.instance;
  final _connectivity = ConnectivityService.instance;

  ComodatoRepository? _repo;
  VisitaRepository? _visitaRepo;
  StreamSubscription<bool>? _conexionSub;
  bool _sincronizando = false;
  bool _pendienteReintento = false;

  final _estadoController = StreamController<bool>.broadcast();

  Stream<bool> get sincronizando => _estadoController.stream;

  void configurar(http.Client apiClient) {
    _repo = ComodatoRepository(apiClient);
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
    ComodatoRepository repo,
    VisitaRepository visitaRepo,
    ComodatoPendiente pendiente,
  ) async {
    final idVisita = pendiente.idVisita ?? await _resolverIdVisita(visitaRepo, pendiente);
    if (idVisita == null) return true;

    final draft = _draftDe(pendiente, idVisita);
    try {
      await repo.registrarControl(idVisita, draft);
      await _queue.eliminar(pendiente.uuidOffline);
      return true;
    } on NetworkException {
      return false;
    } on ComodatoRepositoryException catch (e) {
      await _queue.registrarError(pendiente.uuidOffline, e.message);
      await _queue.eliminar(pendiente.uuidOffline);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<int?> _resolverIdVisita(
    VisitaRepository visitaRepo,
    ComodatoPendiente pendiente,
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

  ControlComodatoDraft _draftDe(ComodatoPendiente pendiente, int idVisita) {
    return ControlComodatoDraft(
      idVisita: idVisita,
      idAgendaItem: pendiente.idAgendaItem,
      idUsuario: pendiente.idUsuario,
      fecha: pendiente.fecha,
      idClienteExt: pendiente.idClienteExt,
      uuidOffline: pendiente.uuidOffline,
      timestampCaptura: pendiente.timestampCaptura,
      observaciones: pendiente.observaciones,
      detalles: ControlComodatoDraft.detallesDesdeStorage(pendiente.detallesJson),
    );
  }

  void dispose() {
    _conexionSub?.cancel();
    _estadoController.close();
  }
}
