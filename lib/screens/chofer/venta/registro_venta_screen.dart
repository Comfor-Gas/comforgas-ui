import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../local/stock_rodante_cache_service.dart';
import '../../../models/detalle_venta_draft.dart';
import '../../../models/producto_catalogo.dart';
import '../../../models/producto_sku.dart';
import '../../../models/stock_rodante_chofer.dart';
import '../../../models/tipo_operacion_venta.dart';
import '../../../models/venta_draft.dart';
import '../../../models/visita_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../repositories/network_exception.dart';
import '../../../repositories/producto_repository.dart';
import '../../../repositories/stock_rodante_repository.dart';
import '../../../repositories/venta_repository.dart';
import '../../../services/catalogo_garrafas_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../utils/formato.dart';
import '../../../widgets/chofer/venta/detalle_venta_card.dart';
import '../../../widgets/chofer/venta/detalle_venta_editor_sheet.dart';
import '../../../widgets/chofer/venta/sku_catalogo_card.dart';
import '../../../widgets/chofer/venta/stock_aviso_banner.dart';
import '../../../widgets/chofer/venta/tipo_operacion_sheet.dart';
import '../../../widgets/chofer/venta/venta_total_bar.dart';

class VentaPreviaResumen {
  final String etiqueta;
  final int monto;
  final String? detalle;

  const VentaPreviaResumen({
    required this.etiqueta,
    required this.monto,
    this.detalle,
  });
}

class RegistroVentaScreen extends StatefulWidget {
  final VisitaModel visita;
  final String nombreCliente;
  final String direccionCliente;
  final VentaDraft? inicial;
  final bool ventaSocialBloqueada;
  final List<VentaPreviaResumen> ventasPrevias;
  final Future<void> Function(VentaDraft venta) onRegistrar;

  const RegistroVentaScreen({
    super.key,
    required this.visita,
    required this.nombreCliente,
    required this.direccionCliente,
    required this.onRegistrar,
    this.inicial,
    this.ventaSocialBloqueada = false,
    this.ventasPrevias = const [],
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
  bool _jornadaCerrada = false;
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
    final fecha = widget.visita.fecha ?? DateTime.now();

    List<ProductoCatalogo> productos = const [];
    try {
      productos = await ProductoRepository(apiClient)
          .listar(idAgendaItem: widget.visita.idAgendaItem);
    } catch (_) {
      productos = const [];
    }

    StockRodanteChofer? diario;
    var sinSenal = false;
    try {
      diario = await StockRodanteRepository(apiClient)
          .getMiStock(idUsuario: idUsuario, fecha: fecha);
      if (diario != null) {
        await StockRodanteCacheService.instance.guardar(idUsuario, diario);
      }
    } on NetworkException {
      sinSenal = true;
      diario = StockRodanteCacheService.instance.obtener(idUsuario);
    } catch (_) {
      diario = StockRodanteCacheService.instance.obtener(idUsuario);
    }

    if (productos.isNotEmpty) {
      List<ProductoSku> catalogo;
      String? aviso;
      var cerrada = false;
      if (diario != null) {
        final diarioRef = diario;
        cerrada = diario.jornadaCerrada;
        catalogo = _catalogoService.desdeCatalogoConStock(
          widget.visita,
          productos,
          (prod) => _disponibleDiario(diarioRef, prod),
        );
        if (cerrada) {
          aviso = 'La jornada está cerrada (rendición completa): no se pueden registrar más ventas para esta fecha.';
        } else if (sinSenal) {
          aviso = 'Sin conexión: se muestra el último stock del día guardado.';
        }
      } else {
        catalogo = _catalogoService.desdeCatalogoConStock(
          widget.visita,
          productos,
          (_) => 0,
        );
        aviso = sinSenal
            ? 'Sin conexión: no se pudo obtener el stock del día. Reintentá cuando tengas señal.'
            : 'No se pudo obtener el stock del día del camión. Actualizá para reintentar.';
      }
      if (!mounted) return;
      setState(() {
        _catalogo = catalogo;
        _avisoStock = aviso;
        _jornadaCerrada = cerrada;
        _cargandoCatalogo = false;
      });
      return;
    }

    List<ProductoSku> catalogo;
    String? aviso;
    var cerrada = false;
    if (diario != null) {
      cerrada = diario.jornadaCerrada;
      catalogo = _catalogoService.desdeStockRodante(widget.visita, diario);
      if (cerrada) {
        aviso = 'La jornada está cerrada (rendición completa): no se pueden registrar más ventas para esta fecha.';
      } else if (sinSenal) {
        aviso = 'Sin conexión: se muestra el último stock del día guardado.';
      }
    } else {
      catalogo = ProductoSku.desdeVisita(widget.visita);
      aviso = sinSenal
          ? 'Sin conexión: no se pudo obtener el stock del día. Se muestran los precios de la agenda sin control de stock.'
          : 'No se pudo obtener el stock del día del camión: se muestran los precios de la agenda sin control de stock.';
    }

    if (!mounted) return;
    setState(() {
      _catalogo = catalogo;
      _avisoStock = aviso;
      _jornadaCerrada = cerrada;
      _cargandoCatalogo = false;
    });
  }

  int _disponibleDiario(StockRodanteChofer diario, ProductoCatalogo prod) {
    final kg = prod.kgEntero;
    for (final p in diario.productos) {
      if (p.idProducto == prod.idProducto ||
          (p.sku.isNotEmpty && p.sku == prod.sku) ||
          (kg != null && p.kg == kg)) {
        return p.disponiblesParaVenta;
      }
    }
    return 0;
  }

  Future<void> _onAgregarSku(ProductoSku producto) async {
    final tipo = await mostrarTipoOperacionSheet(
      context,
      ventaSocialBloqueada: widget.ventaSocialBloqueada,
    );
    if (tipo == null || !mounted) return;

    final existente = _venta.buscar(producto.idProducto, tipo);

    final detalle = await mostrarDetalleVentaEditor(
      context,
      producto: producto,
      tipoOperacion: tipo,
      inicial: existente,
    );
    if (detalle == null || !mounted) return;

    setState(() => _venta.guardarLinea(detalle));
  }

  Future<void> _onEditarLinea(DetalleVentaDraft linea) async {
    final detalle = await mostrarDetalleVentaEditor(
      context,
      producto: linea.producto,
      tipoOperacion: linea.tipoOperacion,
      inicial: linea,
    );
    if (detalle == null || !mounted) return;

    setState(() => _venta.guardarLinea(detalle));
  }

  void _onEliminarLinea(DetalleVentaDraft linea) {
    setState(() => _venta.eliminarLinea(linea));
  }

  String get _textoBotonGuardar {
    if (_venta.tieneSocial && !_venta.tieneVentaNormal) {
      return 'DEJAR EN EL PUNTO Y PAUSAR';
    }
    if (_venta.tieneSocial && _venta.tieneVentaNormal) {
      return 'GUARDAR VENTA Y PAUSAR SOCIAL';
    }
    return 'GUARDAR VENTA';
  }

  Future<void> _guardarVenta() async {
    if (!_venta.puedeGuardar || _guardando) return;
    if (_jornadaCerrada) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La jornada está cerrada: no se pueden registrar más ventas para esta fecha.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _guardando = true);
    try {
      await widget.onRegistrar(_venta);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on VentaRepositoryException catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      final low = e.message.toLowerCase();
      if (low.contains('insuficiente') || low.contains('stock_insuficiente')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No hay stock suficiente en el camión para esta venta. Actualizamos el stock disponible.',
            ),
            backgroundColor: AppColors.error,
            duration: Duration(seconds: 4),
          ),
        );
        _cargarCatalogo();
      } else if (low.contains('jornada') ||
          low.contains('cerrada') ||
          low.contains('entrada_completa')) {
        setState(() => _jornadaCerrada = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('La jornada está cerrada: no se pueden registrar más ventas para esta fecha.'),
            backgroundColor: AppColors.error,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
        );
      }
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
                          if (widget.ventasPrevias.isNotEmpty) ...[
                            _VentasPreviasCard(ventas: widget.ventasPrevias),
                            const SizedBox(height: 16),
                          ],
                          _Seccion(titulo: 'Productos disponibles'),
                          const SizedBox(height: 12),
                          ..._catalogo.map(
                            (sku) => SkuCatalogoCard(
                              producto: sku,
                              agregado: _venta.contieneProducto(sku.idProducto),
                              onTap: () => _onAgregarSku(sku),
                            ),
                          ),
                          if (_venta.tieneVentaNormal) ...[
                            const SizedBox(height: 12),
                            _Seccion(titulo: 'Detalle de la venta'),
                            const SizedBox(height: 12),
                            ..._venta.lineasVenta.map(
                              (linea) => DetalleVentaCard(
                                detalle: linea,
                                onEditar: () => _onEditarLinea(linea),
                                onEliminar: () => _onEliminarLinea(linea),
                              ),
                            ),
                          ],
                          if (_venta.tieneSocial) ...[
                            const SizedBox(height: 12),
                            _Seccion(titulo: 'Venta Social · garrafas a dejar'),
                            const SizedBox(height: 12),
                            ..._venta.lineasSociales.map(
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
            if (_venta.tieneSocial) _ResumenSocialBar(venta: _venta),
            VentaTotalBar(
              total: _venta.montoVentaNormal,
              cantidadItems: _venta.lineasVenta.length,
              habilitado: _venta.puedeGuardar && !_jornadaCerrada,
              cargando: _guardando,
              hayInconsistencias: _venta.hayInconsistencias,
              textoBoton: _textoBotonGuardar,
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

class _ResumenSocialBar extends StatelessWidget {
  final VentaDraft venta;

  const _ResumenSocialBar({required this.venta});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.steelBlue.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.steelBlue.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.volunteer_activism_outlined, size: 18, color: AppColors.steelBlue),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Venta Social: ${venta.totalGarrafasSociales} '
                '${venta.totalGarrafasSociales == 1 ? 'garrafa' : 'garrafas'} a dejar en el punto. '
                'La visita queda pausada y se liquida al volver.',
                style: AppTextStyles.footer.copyWith(color: AppColors.graphiteGray),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VentasPreviasCard extends StatelessWidget {
  final List<VentaPreviaResumen> ventas;

  const _VentasPreviasCard({required this.ventas});

  @override
  Widget build(BuildContext context) {
    final total = ventas.fold(0, (a, v) => a + v.monto);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.steelBlue.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.steelBlue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long_outlined, size: 18, color: AppColors.steelBlue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  ventas.length == 1
                      ? 'Ya registraste 1 venta en esta visita'
                      : 'Ya registraste ${ventas.length} ventas en esta visita',
                  style: AppTextStyles.label.copyWith(fontSize: 13.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final v in ventas)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          v.etiqueta,
                          style: AppTextStyles.link.copyWith(fontSize: 13),
                        ),
                      ),
                      Text(
                        formatMoneda(v.monto),
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.steelBlue,
                        ),
                      ),
                    ],
                  ),
                  if (v.detalle != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.propane_tank_outlined, size: 13, color: AppColors.inputHint),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            v.detalle!,
                            style: AppTextStyles.footer.copyWith(
                              fontSize: 12,
                              color: AppColors.graphiteGray,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          const Divider(height: 8, color: AppColors.inputBorder),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Total ya registrado',
                  style: AppTextStyles.footer.copyWith(
                    color: AppColors.graphiteGray,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                formatMoneda(total),
                style: AppTextStyles.title.copyWith(fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Lo que cargues acá se suma como una venta nueva.',
            style: AppTextStyles.footer.copyWith(
              color: AppColors.graphiteGray,
              fontStyle: FontStyle.italic,
              fontSize: 11.5,
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
