import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../models/producto_sku.dart';
import '../../../models/venta_social.dart';
import '../../../models/visita_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../repositories/network_exception.dart';
import '../../../repositories/stock_repository.dart';
import '../../../services/catalogo_garrafas_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../utils/formato.dart';
import '../../../widgets/chofer/comodato/contador_envases.dart';
import '../../../widgets/primary_button.dart';

typedef GuardarPausaSocial = Future<bool> Function(PausaSocialDraft draft);

class IniciarVentaSocialScreen extends StatefulWidget {
  final VisitaModel visita;
  final String nombreCliente;
  final GuardarPausaSocial onConfirmar;

  const IniciarVentaSocialScreen({
    super.key,
    required this.visita,
    required this.nombreCliente,
    required this.onConfirmar,
  });

  @override
  State<IniciarVentaSocialScreen> createState() => _IniciarVentaSocialScreenState();
}

class _IniciarVentaSocialScreenState extends State<IniciarVentaSocialScreen> {
  static const _catalogoService = CatalogoGarrafasService();
  static const _uuid = Uuid();

  List<ProductoSku> _catalogo = const [];
  final Map<String, int> _cantidades = {};
  bool _cargando = true;
  bool _guardando = false;
  String? _aviso;

  @override
  void initState() {
    super.initState();
    _cargarCatalogo();
  }

  Future<void> _cargarCatalogo() async {
    final apiClient = context.read<AuthProvider>().apiClient;
    List<ProductoSku> catalogo;
    try {
      final stock = await StockRepository(apiClient).getStockMiCamion();
      catalogo = _catalogoService.desdeStock(widget.visita, stock);
    } on StockRepositoryException catch (e) {
      catalogo = const [];
      _aviso = e.message;
    } on NetworkException {
      catalogo = const [];
      _aviso = 'Sin conexión: no se pudo cargar el stock del camión.';
    } catch (_) {
      catalogo = const [];
      _aviso = 'No se pudo cargar el stock del camión.';
    }
    if (!mounted) return;
    setState(() {
      _catalogo = catalogo;
      for (final p in catalogo) {
        _cantidades.putIfAbsent(p.idProducto, () => 0);
      }
      _cargando = false;
    });
  }

  int get _totalEnvases =>
      _cantidades.values.fold(0, (a, v) => a + v);

  bool get _valido => _totalEnvases > 0 && !_guardando;

  Future<void> _confirmar() async {
    if (!_valido) return;
    setState(() => _guardando = true);
    final items = <EnvaseSocialEntregado>[];
    for (final p in _catalogo) {
      final cant = _cantidades[p.idProducto] ?? 0;
      if (cant > 0) {
        items.add(EnvaseSocialEntregado(
          idProducto: p.idProducto,
          sku: p.sku,
          descripcion: p.descripcion,
          kg: p.kg,
          cantidadEntregada: cant,
          precioUnitario: p.precioUnitario,
        ));
      }
    }
    final draft = PausaSocialDraft(
      items: items,
      uuidOffline: _uuid.v4(),
      timestamp: DateTime.now(),
    );
    final ok = await widget.onConfirmar(draft);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.steelBlue,
        foregroundColor: AppColors.white,
        elevation: 0,
        title: const Text('Iniciar Venta Social'),
      ),
      body: SafeArea(
        child: _cargando
            ? const Center(child: CircularProgressIndicator(color: AppColors.orange))
            : Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _Encabezado(nombreCliente: widget.nombreCliente),
                          const SizedBox(height: 14),
                          Text(
                            'ENVASES LLENOS DESCARGADOS EN EL PUNTO',
                            style: AppTextStyles.footer.copyWith(
                              letterSpacing: 0.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.graphiteGray,
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (_catalogo.isEmpty)
                            _AvisoSinStock(mensaje: _aviso)
                          else
                            for (final p in _catalogo) _filaProducto(p),
                        ],
                      ),
                    ),
                  ),
                  _BarraTotal(total: _totalEnvases),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: PrimaryButton(
                      text: 'Pausar y dejar en el punto',
                      isLoading: _guardando,
                      onPressed: _valido ? _confirmar : null,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _filaProducto(ProductoSku p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.propane_tank_rounded, size: 18, color: AppColors.orange),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  p.descripcion.isNotEmpty ? p.descripcion : (p.kg > 0 ? 'Garrafa ${p.kg} kg' : p.sku),
                  style: AppTextStyles.label.copyWith(fontSize: 14),
                ),
              ),
              Text(
                formatMoneda(p.precioUnitario),
                style: AppTextStyles.footer.copyWith(color: AppColors.graphiteGray),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ContadorEnvases(
            value: _cantidades[p.idProducto] ?? 0,
            enabled: !_guardando,
            onChanged: (v) => setState(() => _cantidades[p.idProducto] = v),
          ),
        ],
      ),
    );
  }
}

class _Encabezado extends StatelessWidget {
  final String nombreCliente;

  const _Encabezado({required this.nombreCliente});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.steelBlue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.volunteer_activism_outlined, size: 20, color: AppColors.steelBlue),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nombreCliente, style: AppTextStyles.label.copyWith(fontSize: 14.5)),
                const SizedBox(height: 2),
                Text(
                  'Indicá cuántas garrafas llenas dejás en el punto. Al pausar, la visita queda en Venta Social y podés seguir con otros clientes.',
                  style: AppTextStyles.footer.copyWith(color: AppColors.graphiteGray),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BarraTotal extends StatelessWidget {
  final int total;

  const _BarraTotal({required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppColors.white,
      child: Row(
        children: [
          Expanded(
            child: Text('Total descargado', style: AppTextStyles.label.copyWith(fontSize: 15)),
          ),
          Text(
            total == 1 ? '1 garrafa' : '$total garrafas',
            style: AppTextStyles.title.copyWith(fontSize: 18, color: AppColors.orange),
          ),
        ],
      ),
    );
  }
}

class _AvisoSinStock extends StatelessWidget {
  final String? mensaje;

  const _AvisoSinStock({this.mensaje});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.badgeAmber.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.badgeAmber.withOpacity(0.4)),
      ),
      child: Text(
        mensaje ?? 'No hay stock disponible en el camión para descargar.',
        style: AppTextStyles.footer.copyWith(color: AppColors.graphiteGray),
      ),
    );
  }
}
