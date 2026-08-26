import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../local/stock_camion_cache_service.dart';
import '../../../models/detalle_venta_draft.dart';
import '../../../models/producto_sku.dart';
import '../../../models/venta_draft.dart';
import '../../../models/visita_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../repositories/network_exception.dart';
import '../../../repositories/stock_repository.dart';
import '../../../repositories/venta_repository.dart';
import '../../../services/catalogo_garrafas_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../widgets/chofer/venta/detalle_venta_card.dart';
import '../../../widgets/chofer/venta/detalle_venta_editor_sheet.dart';
import '../../../widgets/chofer/venta/sku_catalogo_card.dart';
import '../../../widgets/chofer/venta/stock_aviso_banner.dart';
import '../../../widgets/chofer/venta/tipo_operacion_sheet.dart';
import '../../../widgets/chofer/venta/venta_total_bar.dart';

class RegistroVentaScreen extends StatefulWidget {
  final VisitaModel visita;
  final String nombreCliente;
  final String direccionCliente;
  final VentaDraft? inicial;
  final Future<void> Function(VentaDraft venta) onRegistrar;

  const RegistroVentaScreen({
    super.key,
    required this.visita,
    required this.nombreCliente,
    required this.direccionCliente,
    required this.onRegistrar,
    this.inicial,
  });

  @override
  State<RegistroVentaScreen> createState() => _RegistroVentaScreenState();
}

class _RegistroVentaScreenState extends State<RegistroVentaScreen> {
  static const _catalogoService = CatalogoGarrafasService();

  late final VentaDraft _venta;
  List<ProductoSku> _catalogo = const [];
  bool _cargandoCatalogo = true;
  bool _guardando = false;
  String? _avisoStock;

  @override
  void initState() {
    super.initState();
    _venta = VentaDraft(
      lineas: widget.inicial?.lineas.map((l) => l.copy()).toList(),
    );
    _cargarCatalogo();
  }

  Future<void> _cargarCatalogo() async {
    final apiClient = context.read<AuthProvider>().apiClient;
    final idUsuario = widget.visita.idUsuario;

    List<ProductoSku> catalogo;
    String? aviso;
    try {
      final stock = await StockRepository(apiClient).getStockMiCamion();
      await StockCamionCacheService.instance.guardar(idUsuario, stock);
      catalogo = _catalogoService.desdeStock(widget.visita, stock);
    } on NetworkException {
      final resultado = _catalogoDesdeCacheOFallback(idUsuario);
      catalogo = resultado.$1;
      aviso = resultado.$2;
    } on StockRepositoryException catch (e) {
      final resultado = _catalogoDesdeCacheOFallback(idUsuario, motivo: e.message);
      catalogo = resultado.$1;
      aviso = resultado.$2;
    } catch (_) {
      final resultado = _catalogoDesdeCacheOFallback(idUsuario);
      catalogo = resultado.$1;
      aviso = resultado.$2;
    }

    if (!mounted) return;
    setState(() {
      _catalogo = catalogo;
      _avisoStock = aviso;
      _cargandoCatalogo = false;
    });
  }

  (List<ProductoSku>, String?) _catalogoDesdeCacheOFallback(
    String idUsuario, {
    String? motivo,
  }) {
    final cache = StockCamionCacheService.instance.obtener(idUsuario);
    if (cache != null) {
      return (
        _catalogoService.desdeStock(widget.visita, cache),
        'Usando el último stock del camión guardado; puede estar desactualizado.',
      );
    }
    return (
      ProductoSku.desdeVisita(widget.visita),
      motivo ??
          'Sin stock del camión disponible: se muestran los precios de la agenda sin control de stock.',
    );
  }

  Future<void> _onAgregarSku(ProductoSku producto) async {
    final index = _venta.indexDe(producto.idProducto);
    final existente = index >= 0 ? _venta.lineas[index] : null;

    final tipo =
        existente?.tipoOperacion ?? await mostrarTipoOperacionSheet(context);
    if (tipo == null || !mounted) return;

    final detalle = await mostrarDetalleVentaEditor(
      context,
      producto: producto,
      tipoOperacion: tipo,
      inicial: existente,
    );
    if (detalle == null || !mounted) return;

    setState(() => _venta.guardarLinea(detalle));
  }

  void _onEditarLinea(DetalleVentaDraft linea) {
    _onAgregarSku(linea.producto);
  }

  void _onEliminarLinea(DetalleVentaDraft linea) {
    setState(() => _venta.eliminar(linea.producto.idProducto));
  }

  Future<void> _guardarVenta() async {
    if (!_venta.puedeGuardar || _guardando) return;

    setState(() => _guardando = true);
    try {
      await widget.onRegistrar(_venta);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on VentaRepositoryException catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _guardando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo registrar la venta. Intentá de nuevo.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Header(
              nombreCliente: widget.nombreCliente,
              direccionCliente: widget.direccionCliente,
              onBack: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: _cargandoCatalogo
                  ? const _CargandoCatalogo()
                  : _catalogo.isEmpty
                  ? _SinCatalogo(aviso: _avisoStock)
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_avisoStock != null)
                            StockAvisoBanner(mensaje: _avisoStock!),
                          _Seccion(titulo: 'Productos disponibles'),
                          const SizedBox(height: 12),
                          ..._catalogo.map(
                            (sku) => SkuCatalogoCard(
                              producto: sku,
                              agregado: _venta.indexDe(sku.idProducto) >= 0,
                              onTap: () => _onAgregarSku(sku),
                            ),
                          ),
                          if (_venta.lineas.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _Seccion(titulo: 'Detalle de la venta'),
                            const SizedBox(height: 12),
                            ..._venta.lineas.map(
                              (linea) => DetalleVentaCard(
                                detalle: linea,
                                onEditar: () => _onEditarLinea(linea),
                                onEliminar: () => _onEliminarLinea(linea),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
            ),
            VentaTotalBar(
              total: _venta.montoTotal,
              cantidadItems: _venta.lineas.length,
              habilitado: _venta.puedeGuardar,
              cargando: _guardando,
              hayInconsistencias: _venta.hayInconsistencias,
              textoBoton: 'GUARDAR VENTA',
              onGuardar: _guardarVenta,
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String nombreCliente;
  final String direccionCliente;
  final VoidCallback onBack;

  const _Header({
    required this.nombreCliente,
    required this.direccionCliente,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 18),
      decoration: const BoxDecoration(
        color: AppColors.steelBlue,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Registro de Venta',
                    style: AppTextStyles.title.copyWith(
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    nombreCliente,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 14, color: Colors.white70),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          direccionCliente,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Seccion extends StatelessWidget {
  final String titulo;

  const _Seccion({required this.titulo});

  @override
  Widget build(BuildContext context) {
    return Text(titulo, style: AppTextStyles.label.copyWith(fontSize: 15));
  }
}

class _CargandoCatalogo extends StatelessWidget {
  const _CargandoCatalogo();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            height: 34,
            width: 34,
            child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.orange),
          ),
          const SizedBox(height: 16),
          Text(
            'Consultando el stock de tu camión…',
            style: AppTextStyles.link,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SinCatalogo extends StatelessWidget {
  final String? aviso;

  const _SinCatalogo({this.aviso});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inventory_2_outlined,
                size: 56, color: AppColors.inputHint),
            const SizedBox(height: 16),
            Text(
              aviso ??
                  'No hay garrafas llenas disponibles en el stock de tu camión para este cliente.',
              textAlign: TextAlign.center,
              style: AppTextStyles.link,
            ),
          ],
        ),
      ),
    );
  }
}
