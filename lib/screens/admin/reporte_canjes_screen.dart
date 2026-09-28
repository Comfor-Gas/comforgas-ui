import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/responsive.dart';
import '../../models/canje_reporte.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/canje_reporte_repository.dart';
import '../../repositories/network_exception.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/admin/canje/reporte_canje_fila.dart';
import '../../widgets/common/carga/zona_carga.dart';
import '../../widgets/common/filtros/filtros.dart';

class ReporteCanjesScreen extends StatefulWidget {
  const ReporteCanjesScreen({super.key});

  @override
  State<ReporteCanjesScreen> createState() => _ReporteCanjesScreenState();
}

class _ReporteCanjesScreenState extends State<ReporteCanjesScreen> {
  late final CanjeReporteRepository _repo;

  bool _loading = true;
  String? _error;
  List<CanjeReporte> _filas = [];

  DateTime? _desde;
  DateTime? _hasta;
  final _filtroCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _repo = CanjeReporteRepository(context.read<AuthProvider>().apiClient);
    final ahora = DateTime.now();
    _desde = DateTime(ahora.year, ahora.month, ahora.day);
    _hasta = DateTime(ahora.year, ahora.month, ahora.day);
    _filtroCtrl.addListener(() => setState(() {}));
    _cargar();
  }

  @override
  void dispose() {
    _filtroCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _repo.buscarReporte(desde: _desde, hasta: _hasta);
      if (!mounted) return;
      setState(() {
        _filas = data;
        _loading = false;
      });
    } on NetworkException {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo conectar con el servidor. Revisá tu conexión.';
        _loading = false;
      });
    } on CanjeReporteRepositoryException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo cargar el reporte de devoluciones.';
        _loading = false;
      });
    }
  }

  List<CanjeReporte> get _filtrados {
    final q = _filtroCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return _filas;
    return _filas.where((f) {
      final chofer = f.nombreChofer.toLowerCase();
      final movil = 'movil ${f.movil ?? ''}'.toLowerCase();
      final sku = f.sku.toLowerCase();
      final prod = f.descripcionProducto.toLowerCase();
      final danio = f.descripcionDanio.toLowerCase();
      return chofer.contains(q) ||
          movil.contains(q) ||
          sku.contains(q) ||
          prod.contains(q) ||
          danio.contains(q);
    }).toList();
  }

  List<CanjeReporteGrupo> get _grupos => CanjeReporte.agrupar(_filtrados);

  int get _totalDevoluciones => _filtrados.fold(0, (a, f) => a + f.cantidad);

  int get _choferesConDevolucion {
    final set = <String>{};
    for (final f in _filtrados) {
      set.add(f.choferId ?? f.nombreChofer);
    }
    return set.length;
  }

  int get _vehiculosConDevolucion {
    final set = <int>{};
    for (final f in _filtrados) {
      if (f.movil != null) set.add(f.movil!);
    }
    return set.length;
  }

  void _cambiarRango(DateTime? desde, DateTime? hasta) {
    setState(() {
      _desde = desde;
      _hasta = hasta;
    });
    _cargar();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = Responsive.isDesktop(constraints);
        final padding = EdgeInsets.all(isDesktop ? 28 : 16);
        return SingleChildScrollView(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ReportarCarga(cargando: _loading),
              const _Cabecera(),
              const SizedBox(height: 18),
              _Stats(
                totalDevoluciones: _totalDevoluciones,
                choferes: _choferesConDevolucion,
                vehiculos: _vehiculosConDevolucion,
              ),
              const SizedBox(height: 18),
              _Filtros(
                filtroCtrl: _filtroCtrl,
                desde: _desde,
                hasta: _hasta,
                cargando: _loading,
                onCambioRango: _cambiarRango,
                onRefrescar: _cargar,
              ),
              const SizedBox(height: 18),
              _buildTabla(constraints.maxWidth - padding.horizontal),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabla(double anchoDisponible) {
    Widget contenido;
    if (_loading) {
      contenido = const SizedBox(height: 160);
    } else if (_error != null) {
      contenido = Padding(
        padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 20),
        child: Column(
          children: [
            const Icon(Icons.cloud_off_outlined, size: 40, color: AppColors.badgeGray),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center, style: AppTextStyles.input),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _cargar,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.steelBlue,
                side: const BorderSide(color: AppColors.steelBlue),
              ),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    } else if (_grupos.isEmpty) {
      contenido = Padding(
        padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
        child: Center(
          child: Text(
            'No hay devoluciones por garantía/daño para los filtros elegidos.',
            textAlign: TextAlign.center,
            style: AppTextStyles.link,
          ),
        ),
      );
    } else {
      final grupos = _grupos;
      contenido = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < grupos.length; i++)
            ReporteCanjeFila(grupo: grupos[i], par: i.isEven),
        ],
      );
    }

    final anchoTabla = anchoDisponible < 820 ? 820.0 : anchoDisponible;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.inputBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: anchoTabla,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _EncabezadoTabla(),
              contenido,
            ],
          ),
        ),
      ),
    );
  }
}

class _Cabecera extends StatelessWidget {
  const _Cabecera();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Devoluciones por garantía / daño', style: AppTextStyles.desktopTitle),
        const SizedBox(height: 4),
        Text(
          'Envases dañados canjeados por los choferes, agrupados por chofer y vehículo para el cierre de turno.',
          style: AppTextStyles.desktopSubtitle,
        ),
      ],
    );
  }
}

class _Stats extends StatelessWidget {
  final int totalDevoluciones;
  final int choferes;
  final int vehiculos;

  const _Stats({
    required this.totalDevoluciones,
    required this.choferes,
    required this.vehiculos,
  });

  @override
  Widget build(BuildContext context) {
    final cards = [
      _StatCard(
        etiqueta: 'Devoluciones',
        valor: '$totalDevoluciones',
        color: AppColors.orange,
        icon: Icons.assignment_return_outlined,
      ),
      _StatCard(
        etiqueta: 'Choferes con devoluciones',
        valor: '$choferes',
        color: AppColors.steelBlue,
        icon: Icons.person_outline,
      ),
      _StatCard(
        etiqueta: 'Vehículos con devoluciones',
        valor: '$vehiculos',
        color: AppColors.badgeBlue,
        icon: Icons.local_shipping_outlined,
      ),
    ];
    return Row(
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          Expanded(child: cards[i]),
          if (i < cards.length - 1) const SizedBox(width: 14),
        ],
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String etiqueta;
  final String valor;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.etiqueta,
    required this.valor,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(valor, style: AppTextStyles.title.copyWith(fontSize: 22, color: color)),
                Text(etiqueta, style: AppTextStyles.footer.copyWith(color: AppColors.graphiteGray)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Filtros extends StatelessWidget {
  final TextEditingController filtroCtrl;
  final DateTime? desde;
  final DateTime? hasta;
  final bool cargando;
  final void Function(DateTime? desde, DateTime? hasta) onCambioRango;
  final VoidCallback onRefrescar;

  const _Filtros({
    required this.filtroCtrl,
    required this.desde,
    required this.hasta,
    required this.cargando,
    required this.onCambioRango,
    required this.onRefrescar,
  });

  @override
  Widget build(BuildContext context) {
    return FiltrosPanel(
      filas: [
        SelectorRangoFechas(
          desde: desde,
          hasta: hasta,
          permitirSinRango: true,
          onCambio: onCambioRango,
        ),
        FilaFiltros(
          children: [
            CampoBusquedaFiltro(
              controller: filtroCtrl,
              etiqueta: 'Buscar',
              hint: 'Chofer, móvil, producto o daño',
              icono: Icons.search,
              ancho: 320,
            ),
            if (filtroCtrl.text.trim().isNotEmpty)
              BotonLimpiarFiltros(onPressed: filtroCtrl.clear),
            BotonActualizar(onPressed: onRefrescar, cargando: cargando),
          ],
        ),
      ],
    );
  }
}

class _EncabezadoTabla extends StatelessWidget {
  const _EncabezadoTabla();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.inputBorder)),
      ),
      child: Row(
        children: const [
          Expanded(flex: 4, child: _Th('Chofer')),
          Expanded(flex: 3, child: _Th('Vehículo')),
          Expanded(flex: 2, child: _Th('Devoluciones')),
          Expanded(flex: 3, child: _Th('Último canje')),
          SizedBox(width: 32),
        ],
      ),
    );
  }
}

class _Th extends StatelessWidget {
  final String texto;
  const _Th(this.texto);

  @override
  Widget build(BuildContext context) {
    return Text(
      texto.toUpperCase(),
      style: AppTextStyles.footer.copyWith(
        letterSpacing: 0.5,
        fontWeight: FontWeight.w700,
        color: AppColors.graphiteGray,
      ),
    );
  }
}
