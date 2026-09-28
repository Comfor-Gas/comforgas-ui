import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/detalle_venta_draft.dart';
import '../../../models/producto_sku.dart';
import '../../../models/venta_draft.dart';
import '../../../models/venta_previa_resumen.dart';
import '../../../models/visita_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../repositories/venta_repository.dart';
import '../../../services/venta_catalogo_loader.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/chofer/venta/catalogo_venta_estados.dart';
import '../../../widgets/chofer/venta/detalle_venta_card.dart';
import '../../../widgets/chofer/venta/detalle_venta_editor_sheet.dart';
import '../../../widgets/chofer/venta/registro_venta_header.dart';
import '../../../widgets/chofer/venta/resumen_social_bar.dart';
import '../../../widgets/chofer/venta/sku_catalogo_card.dart';
import '../../../widgets/chofer/venta/stock_aviso_banner.dart';
import '../../../widgets/chofer/venta/tipo_operacion_sheet.dart';
import '../../../widgets/chofer/venta/venta_total_bar.dart';
import '../../../widgets/chofer/venta/ventas_previas_card.dart';
import '../../../widgets/common/carga/zona_carga.dart';
import '../../../core/feedback/app_feedback.dart';

export '../../../models/venta_previa_resumen.dart';

class RegistroVentaScreen extends StatefulWidget {
  final VisitaModel visita;
  final String nombreCliente;
  final String direccionCliente;
  final VentaDraft? inicial;
  final bool ventaSocialBloqueada;
  final bool ventaNormalBloqueada;
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
    this.ventaNormalBloqueada = false,
    this.ventasPrevias = const [],
  });

  @override
  State<RegistroVentaScreen> createState() => _RegistroVentaScreenState();
}

class _RegistroVentaScreenState extends State<RegistroVentaScreen> {
  late final VentaDraft _venta;
  List<ProductoSku> _catalogo = const [];
  bool _cargandoCatalogo = true;
  bool _guardando = false;
  bool _jornadaCerrada = false;
  bool _sinCarga = false;
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
    final resultado = await VentaCatalogoLoader(apiClient).cargar(widget.visita);
    if (!mounted) return;
    setState(() {
      _catalogo = resultado.productos;
      _avisoStock = resultado.aviso;
      _jornadaCerrada = resultado.jornadaCerrada;
      _sinCarga = resultado.sinCarga;
      _cargandoCatalogo = false;
    });
  }

  int? _stockRestante(ProductoSku producto, {DetalleVentaDraft? excluir}) {
    final stock = producto.stockDisponible;
    if (stock == null) return null;
    final usado = _venta.lineas
        .where((l) =>
            l.producto.idProducto == producto.idProducto &&
            !(excluir != null && l.tipoOperacion == excluir.tipoOperacion))
        .fold<int>(0, (a, l) => a + l.cantidadEntregada);
    final restante = stock - usado;
    return restante < 0 ? 0 : restante;
  }

  ProductoSku _productoDelCatalogo(ProductoSku producto) {
    for (final p in _catalogo) {
      if (p.idProducto == producto.idProducto) return p;
    }
    return producto;
  }

  void _avisarSinStock() {
    AppFeedback.advertencia(
      'No quedan garrafas llenas de este tipo en tu camión.',
      titulo: 'Sin stock',
    );
  }

  Future<void> _onAgregarSku(ProductoSku producto) async {
    final hayNormal = widget.ventasPrevias.isNotEmpty || _venta.tieneVentaNormal;
    final tipo = await mostrarTipoOperacionSheet(
      context,
      ventaSocialBloqueada: widget.ventaSocialBloqueada || hayNormal,
      mensajeVentaSocialBloqueada: widget.ventaSocialBloqueada
          ? 'Ya registraste una venta social en esta visita.'
          : 'Esta visita tiene ventas VACÍO X LLENO o PRÉSTAMO: no admite Venta Social.',
      ventaNormalBloqueada: widget.ventaNormalBloqueada || _venta.tieneSocial,
    );
    if (tipo == null || !mounted) return;

    final existente = _venta.buscar(producto.idProducto, tipo);
    final restante = _stockRestante(producto, excluir: existente);
    if (restante != null && restante <= 0) {
      _avisarSinStock();
      return;
    }

    final detalle = await mostrarDetalleVentaEditor(
      context,
      producto: producto.conStock(restante),
      tipoOperacion: tipo,
      inicial: existente,
    );
    if (detalle == null || !mounted) return;

    setState(() => _venta.guardarLinea(detalle));
  }

  Future<void> _onEditarLinea(DetalleVentaDraft linea) async {
    final base = _productoDelCatalogo(linea.producto);
    final detalle = await mostrarDetalleVentaEditor(
      context,
      producto: base.conStock(_stockRestante(base, excluir: linea)),
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

  bool get _bloqueada => _jornadaCerrada || _sinCarga;

  void _mostrarError(String mensaje, {Duration? duracion}) {
    AppFeedback.error(mensaje, duracion: duracion);
  }

  Future<void> _guardarVenta() async {
    if (!_venta.puedeGuardar || _guardando) return;
    if (_bloqueada) {
      _mostrarError(_avisoStock ?? VentaCatalogoLoader.avisoJornadaCerrada);
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
      if (e.esStockInsuficiente) {
        _mostrarError(
          'No hay stock suficiente en el camión para esta venta. Actualizamos el stock disponible.',
        );
        _cargarCatalogo();
      } else if (e.esSinNotaAsignada) {
        setState(() {
          _sinCarga = true;
          _avisoStock = e.message;
        });
        _mostrarError(e.message);
      } else if (e.esJornadaCerrada) {
        setState(() => _jornadaCerrada = true);
        _mostrarError(VentaCatalogoLoader.avisoJornadaCerrada);
      } else {
        _mostrarError(e.message);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _guardando = false);
      _mostrarError('No se pudo registrar la venta. Intentá de nuevo.');
    }
  }

  Widget _cuerpo() {
    if (_cargandoCatalogo) return const CatalogoVentaCargando();
    if (_catalogo.isEmpty) return CatalogoVentaVacio(aviso: _avisoStock);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_avisoStock != null) StockAvisoBanner(mensaje: _avisoStock!),
          if (widget.ventasPrevias.isNotEmpty) ...[
            VentasPreviasCard(ventas: widget.ventasPrevias),
            const SizedBox(height: 16),
          ],
          const CatalogoVentaSeccion(titulo: 'Productos disponibles'),
          const SizedBox(height: 12),
          ..._catalogo.map((sku) {
            final restante = _stockRestante(sku);
            return SkuCatalogoCard(
              producto: sku.conStock(restante),
              agregado: _venta.contieneProducto(sku.idProducto),
              onTap: () {
                if (restante != null && restante <= 0) {
                  _avisarSinStock();
                } else {
                  _onAgregarSku(sku);
                }
              },
            );
          }),
          if (_venta.tieneVentaNormal) ...[
            const SizedBox(height: 12),
            const CatalogoVentaSeccion(titulo: 'Detalle de la venta'),
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
            const CatalogoVentaSeccion(titulo: 'Venta Social · garrafas a dejar'),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            RegistroVentaHeader(
              nombreCliente: widget.nombreCliente,
              direccionCliente: widget.direccionCliente,
              onBack: () => Navigator.of(context).maybePop(),
            ),
            Expanded(child: ZonaCarga(child: _cuerpo())),
            if (_venta.tieneSocial) ResumenSocialBar(venta: _venta),
            VentaTotalBar(
              total: _venta.montoVentaNormal,
              cantidadItems: _venta.lineasVenta.length,
              habilitado: _venta.puedeGuardar && !_bloqueada,
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
