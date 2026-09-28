import 'dart:convert';
import 'package:http/http.dart' as http;
import '../local/offline_evento.dart';
import '../local/offline_queue_service.dart';
import '../local/stock_rodante_cache_service.dart';
import '../models/producto_catalogo.dart';
import '../models/producto_sku.dart';
import '../models/stock_rodante_chofer.dart';
import '../models/visita_model.dart';
import '../repositories/network_exception.dart';
import '../repositories/producto_repository.dart';
import '../repositories/stock_rodante_repository.dart';
import 'catalogo_garrafas_service.dart';

class CatalogoVenta {
  final List<ProductoSku> productos;
  final String? aviso;
  final bool jornadaCerrada;
  final bool sinCarga;

  const CatalogoVenta({
    required this.productos,
    this.aviso,
    this.jornadaCerrada = false,
    this.sinCarga = false,
  });
}

class VentaCatalogoLoader {
  static const _catalogoService = CatalogoGarrafasService();

  static const avisoJornadaCerrada =
      'La jornada está cerrada (rendición completa): no se pueden registrar más ventas para esta fecha.';

  final http.Client apiClient;

  const VentaCatalogoLoader(this.apiClient);

  Future<CatalogoVenta> cargar(VisitaModel visita) async {
    final idUsuario = visita.idUsuario;
    final fecha = visita.fecha ?? DateTime.now();

    final productos = await _cargarProductos(visita);

    StockRodanteChofer? nota;
    var sinSenal = false;
    var errorServidor = false;
    try {
      nota = await StockRodanteRepository(apiClient).getMiStock(idUsuario: idUsuario, fecha: fecha);
      if (nota != null) {
        nota = nota.aplicarSalidas(_salidasPendientesDeSync(fecha));
        await StockRodanteCacheService.instance.guardar(idUsuario, nota);
      }
    } on NetworkException {
      sinSenal = true;
      nota = StockRodanteCacheService.instance.obtener(idUsuario, fecha: fecha);
    } catch (_) {
      errorServidor = true;
      nota = StockRodanteCacheService.instance.obtener(idUsuario, fecha: fecha);
    }

    if (nota != null) {
      final cerrada = nota.jornadaCerrada;
      return CatalogoVenta(
        productos: cerrada ? const [] : _catalogoService.paraVentaDesdeNota(visita, nota, productos),
        jornadaCerrada: cerrada,
        aviso: cerrada
            ? avisoJornadaCerrada
            : (sinSenal ? 'Sin conexión: se muestra el último stock del día guardado.' : null),
      );
    }

    if (!sinSenal && !errorServidor) {
      return const CatalogoVenta(
        productos: [],
        sinCarga: true,
        aviso: 'No tenés una Nota de Control de Stock asignada para esta fecha. '
            'Pedile al administrador que te asigne la carga del camión.',
      );
    }

    return CatalogoVenta(
      productos: _catalogoService.sinControlDeStock(visita, productos),
      aviso: sinSenal
          ? 'Sin conexión: no se pudo obtener el stock del día. La venta se valida contra el stock del camión al sincronizar.'
          : 'No se pudo obtener el stock del día del camión. La venta se valida contra el stock al registrarla.',
    );
  }

  Future<List<ProductoCatalogo>> _cargarProductos(VisitaModel visita) async {
    try {
      return await ProductoRepository(apiClient).listar(idAgendaItem: visita.idAgendaItem);
    } catch (_) {
      return const [];
    }
  }

  Map<String, int> _salidasPendientesDeSync(DateTime fecha) {
    final salidas = <String, int>{};
    List<OfflineEvento> pendientes;
    try {
      pendientes = OfflineQueueService.instance.listarPendientes();
    } catch (_) {
      return salidas;
    }
    for (final evento in pendientes) {
      final origen = evento.timestampOrigen.toLocal();
      if (origen.year != fecha.year || origen.month != fecha.month || origen.day != fecha.day) {
        continue;
      }
      for (final item in _itemsDe(evento)) {
        final id = (item['idProducto'] ?? '').toString();
        final cantidad = item['cantidadEntregada'];
        if (id.isEmpty || cantidad is! num || cantidad <= 0) continue;
        salidas[id] = (salidas[id] ?? 0) + cantidad.toInt();
      }
    }
    return salidas;
  }

  List<Map<String, dynamic>> _itemsDe(OfflineEvento evento) {
    try {
      if (evento.tipoEvento == OfflineEventoTipo.venta && evento.ventaItemsJson != null) {
        final items = jsonDecode(evento.ventaItemsJson!);
        return items is List ? items.whereType<Map<String, dynamic>>().toList() : const [];
      }
      if (evento.tipoEvento == OfflineEventoTipo.pausarSocial && evento.socialPayloadJson != null) {
        final payload = jsonDecode(evento.socialPayloadJson!);
        final items = payload is Map<String, dynamic> ? payload['items'] : null;
        return items is List ? items.whereType<Map<String, dynamic>>().toList() : const [];
      }
    } catch (_) {}
    return const [];
  }
}
