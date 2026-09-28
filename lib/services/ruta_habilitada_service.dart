import 'package:http/http.dart' as http;
import '../local/stock_rodante_cache_service.dart';
import '../repositories/network_exception.dart';
import '../repositories/stock_rodante_repository.dart';

enum EstadoHabilitacion { habilitada, sinNota, cerrada, sinVerificar }

class HabilitacionRuta {
  final EstadoHabilitacion estado;
  final String mensaje;

  const HabilitacionRuta(this.estado, this.mensaje);

  bool get permitida =>
      estado == EstadoHabilitacion.habilitada || estado == EstadoHabilitacion.sinVerificar;

  bool get pendienteDeVerificar => estado == EstadoHabilitacion.sinVerificar;
}

class RutaHabilitadaService {
  static const mensajeSinNota =
      'Todavía no tenés stock asignado para hoy. Pedile al administrador que cargue tu stock del camión para poder iniciar las visitas.';
  static const mensajeCerrada =
      'Tu jornada ya está cerrada (rendición completa): no podés iniciar más visitas en esta fecha.';
  static const mensajeSinVerificar =
      'Sin señal: no pudimos verificar tu stock asignado. La visita se guarda en el dispositivo y el stock se valida al sincronizar.';

  final http.Client apiClient;

  const RutaHabilitadaService(this.apiClient);

  Future<HabilitacionRuta> verificar({
    required String idUsuario,
    DateTime? fecha,
    bool soloCache = false,
  }) async {
    final dia = fecha ?? DateTime.now();
    if (!soloCache) {
      try {
        final estado = await StockRodanteRepository(apiClient).estadoRuta(fecha: dia);
        if (estado != null) {
          final nota = estado.nota;
          if (nota != null) {
            await StockRodanteCacheService.instance.guardar(idUsuario, nota);
          }
          if (estado.habilitado) {
            return const HabilitacionRuta(EstadoHabilitacion.habilitada, '');
          }
          if (estado.jornadaCerrada) {
            return const HabilitacionRuta(EstadoHabilitacion.cerrada, mensajeCerrada);
          }
          return const HabilitacionRuta(EstadoHabilitacion.sinNota, mensajeSinNota);
        }
      } on NetworkException {
        return _desdeCache(idUsuario, dia);
      } catch (_) {
        return _desdeCache(idUsuario, dia);
      }
    }
    return _desdeCache(idUsuario, dia);
  }

  HabilitacionRuta _desdeCache(String idUsuario, DateTime dia) {
    final nota = StockRodanteCacheService.instance.obtener(idUsuario, fecha: dia);
    if (nota == null) {
      return const HabilitacionRuta(EstadoHabilitacion.sinVerificar, mensajeSinVerificar);
    }
    if (nota.jornadaCerrada) {
      return const HabilitacionRuta(EstadoHabilitacion.cerrada, mensajeCerrada);
    }
    return const HabilitacionRuta(EstadoHabilitacion.habilitada, '');
  }
}
