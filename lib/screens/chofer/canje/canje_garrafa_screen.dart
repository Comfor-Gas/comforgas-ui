import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../local/stock_camion_cache_service.dart';
import '../../../models/producto_sku.dart';
import '../../../models/visita_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../repositories/canje_repository.dart';
import '../../../repositories/network_exception.dart';
import '../../../repositories/stock_repository.dart';
import '../../../services/catalogo_garrafas_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../widgets/chofer/canje/selector_sku_canje.dart';
import '../../../widgets/primary_button.dart';

typedef GuardarCanjeGarrafa = Future<void> Function(
  ProductoSku producto,
  String descripcionDanio,
);

const List<String> _sugerenciasDanio = [
  'Válvula defectuosa',
  'Fuga en envase',
  'Cuerpo abollado',
];

class CanjeGarrafaScreen extends StatefulWidget {
  final VisitaModel visita;
  final String nombreCliente;
  final GuardarCanjeGarrafa onGuardar;

  const CanjeGarrafaScreen({
    super.key,
    required this.visita,
    required this.nombreCliente,
    required this.onGuardar,
  });

  @override
  State<CanjeGarrafaScreen> createState() => _CanjeGarrafaScreenState();
}

class _CanjeGarrafaScreenState extends State<CanjeGarrafaScreen> {
  static const _catalogoService = CatalogoGarrafasService();

  final _danioCtrl = TextEditingController();
  List<ProductoSku> _catalogo = const [];
  ProductoSku? _producto;
  bool _cargandoCatalogo = true;
  bool _guardando = false;
  String? _avisoStock;

  @override
  void initState() {
    super.initState();
    _danioCtrl.addListener(() => setState(() {}));
    _cargarCatalogo();
  }

  @override
  void dispose() {
    _danioCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarCatalogo() async {
    final apiClient = context.read<AuthProvider>().apiClient;
    final idUsuario = widget.visita.idUsuario;

    List<ProductoSku> catalogo;
    String? aviso;
    try {
      final stock = await StockRepository(apiClient).getStockMiCamion();
      await StockCamionCacheService.instance.guardar(idUsuario, stock);
      catalogo = _catalogoService.desdeStockParaCanje(stock);
    } on NetworkException {
      final resultado = _catalogoDesdeCache(idUsuario);
      catalogo = resultado.$1;
      aviso = resultado.$2;
    } on StockRepositoryException catch (e) {
      final resultado = _catalogoDesdeCache(idUsuario, motivo: e.message);
      catalogo = resultado.$1;
      aviso = resultado.$2;
    } catch (_) {
      final resultado = _catalogoDesdeCache(idUsuario);
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

  (List<ProductoSku>, String?) _catalogoDesdeCache(
    String idUsuario, {
    String? motivo,
  }) {
    final cache = StockCamionCacheService.instance.obtener(idUsuario);
    if (cache != null) {
      return (
        _catalogoService.desdeStockParaCanje(cache),
        'Usando el último stock del camión guardado; puede estar desactualizado.',
      );
    }
    return (
      const <ProductoSku>[],
      motivo ??
          'Sin stock del camión disponible. Conectate para ver las garrafas que podés canjear.',
    );
  }

  bool get _puedeGuardar =>
      _producto != null && _danioCtrl.text.trim().isNotEmpty && !_guardando;

  Future<void> _guardar() async {
    if (!_puedeGuardar) return;
    setState(() => _guardando = true);
    try {
      await widget.onGuardar(_producto!, _danioCtrl.text.trim());
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on CanjeRepositoryException catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      _mostrarError(e.message);
    } on NetworkException catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      _mostrarError(e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _guardando = false);
      _mostrarError('No se pudo registrar el canje. Intentá de nuevo.');
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TopBar(nombreCliente: widget.nombreCliente),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_avisoStock != null) ...[
                      _buildAviso(_avisoStock!),
                      const SizedBox(height: 16),
                    ],
                    _Seccion(
                      titulo: 'Garrafa a entregar (stock del camión)',
                      child: _buildSelector(),
                    ),
                    const SizedBox(height: 20),
                    _Seccion(
                      titulo: 'Descripción del daño (obligatorio)',
                      child: _buildDanio(),
                    ),
                    const SizedBox(height: 16),
                    _buildNotaOffline(),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: PrimaryButton(
                text: 'Guardar canje',
                isLoading: _guardando,
                onPressed: _puedeGuardar ? _guardar : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelector() {
    if (_cargandoCatalogo) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: SizedBox(
            height: 26,
            width: 26,
            child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.orange),
          ),
        ),
      );
    }
    return SelectorSkuCanje(
      productos: _catalogo,
      seleccionadoId: _producto?.idProducto,
      enabled: !_guardando,
      onSeleccionar: (p) => setState(() => _producto = p),
    );
  }

  Widget _buildAviso(String mensaje) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.badgeAmber.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.badgeAmber.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 18, color: AppColors.badgeAmber),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              mensaje,
              style: AppTextStyles.footer.copyWith(color: AppColors.graphiteGray),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDanio() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.inputBorder, width: 1.2),
          ),
          child: TextField(
            controller: _danioCtrl,
            enabled: !_guardando,
            maxLines: 3,
            style: AppTextStyles.input,
            cursorColor: AppColors.steelBlue,
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.all(14),
              hintText: 'Ej: válvula defectuosa, fuga en envase, cuerpo abollado…',
              hintStyle: AppTextStyles.hint,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final s in _sugerenciasDanio)
              _ChipSugerencia(
                etiqueta: s,
                onTap: _guardando ? null : () => setState(() => _danioCtrl.text = s),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildNotaOffline() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.steelBlue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.save_outlined, size: 18, color: AppColors.steelBlue),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Si no hay señal, el canje se guarda en el dispositivo y se sincroniza automáticamente al recuperar conexión.',
              style: AppTextStyles.footer.copyWith(color: AppColors.graphiteGray),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipSugerencia extends StatelessWidget {
  final String etiqueta;
  final VoidCallback? onTap;

  const _ChipSugerencia({required this.etiqueta, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.orange.withOpacity(0.45)),
        ),
        child: Text(
          etiqueta,
          style: AppTextStyles.label.copyWith(fontSize: 12.5, color: AppColors.orange),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final String nombreCliente;

  const _TopBar({required this.nombreCliente});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 16, 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.steelBlue),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Canjear Garrafa Dañada',
                  style: AppTextStyles.title.copyWith(fontSize: 18),
                ),
                Text(
                  nombreCliente,
                  style: AppTextStyles.link.copyWith(fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Seccion extends StatelessWidget {
  final String titulo;
  final Widget child;

  const _Seccion({required this.titulo, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo.toUpperCase(),
          style: AppTextStyles.footer.copyWith(
            letterSpacing: 0.5,
            fontWeight: FontWeight.w700,
            color: AppColors.graphiteGray,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
