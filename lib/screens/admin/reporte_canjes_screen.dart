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

  Future<void> _elegirFecha({required bool desde}) async {
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    final firstDate = desde ? DateTime(ahora.year - 2) : (_desde ?? DateTime(ahora.year - 2));
    final lastDate = desde ? (_hasta ?? hoy) : hoy;
    var inicial = (desde ? _desde : _hasta) ?? hoy;
    if (inicial.isBefore(firstDate)) inicial = firstDate;
    if (inicial.isAfter(lastDate)) inicial = lastDate;
    final elegida = await showDatePicker(
      context: context,
      initialDate: inicial,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        final base = Theme.of(context);
        return Theme(
          data: base.copyWith(
            colorScheme: base.colorScheme.copyWith(
              primary: AppColors.orange,
              onPrimary: AppColors.white,
              onSurface: AppColors.steelBlue,
              surface: AppColors.white,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: AppColors.orange),
            ),
          ),
          child: child!,
        );
      },
    );
    if (elegida == null) return;
    setState(() {
      if (desde) {
        _desde = elegida;
      } else {
        _hasta = elegida;
      }
    });
    _cargar();
  }

  void _limpiarFechas() {
    setState(() {
      _desde = null;
      _hasta = null;
    });
    _cargar();
  }

  void _hoy() {
    final ahora = DateTime.now();
    setState(() {
      _desde = DateTime(ahora.year, ahora.month, ahora.day);
      _hasta = DateTime(ahora.year, ahora.month, ahora.day);
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
                onElegirDesde: () => _elegirFecha(desde: true),
                onElegirHasta: () => _elegirFecha(desde: false),
                onLimpiarFechas: _limpiarFechas,
                onHoy: _hoy,
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
      contenido = const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(child: CircularProgressIndicator(color: AppColors.orange)),
      );
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
  final VoidCallback onElegirDesde;
  final VoidCallback onElegirHasta;
  final VoidCallback onLimpiarFechas;
  final VoidCallback onHoy;
  final VoidCallback onRefrescar;

  const _Filtros({
    required this.filtroCtrl,
    required this.desde,
    required this.hasta,
    required this.onElegirDesde,
    required this.onElegirHasta,
    required this.onLimpiarFechas,
    required this.onHoy,
    required this.onRefrescar,
  });

  String _fecha(DateTime? f) {
    if (f == null) return '';
    final dd = f.day.toString().padLeft(2, '0');
    final mm = f.month.toString().padLeft(2, '0');
    return '$dd/$mm/${f.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 280,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.inputBorder),
              ),
              child: TextField(
                controller: filtroCtrl,
                style: AppTextStyles.input,
                cursorColor: AppColors.steelBlue,
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  hintText: 'Buscar por chofer, móvil, producto o daño',
                  hintStyle: AppTextStyles.hint,
                  prefixIcon: Icon(Icons.search, color: AppColors.inputHint, size: 20),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
            ),
          ),
          _ChipFecha(
            etiqueta: desde == null ? 'Desde' : 'Desde ${_fecha(desde)}',
            activo: desde != null,
            onTap: onElegirDesde,
          ),
          _ChipFecha(
            etiqueta: hasta == null ? 'Hasta' : 'Hasta ${_fecha(hasta)}',
            activo: hasta != null,
            onTap: onElegirHasta,
          ),
          _BotonChip(etiqueta: 'Hoy', icon: Icons.today_outlined, onTap: onHoy),
          if (desde != null || hasta != null)
            TextButton.icon(
              onPressed: onLimpiarFechas,
              icon: const Icon(Icons.close, size: 16, color: AppColors.graphiteGray),
              label: const Text(
                'Limpiar fechas',
                style: TextStyle(fontSize: 12.5, color: AppColors.graphiteGray, fontWeight: FontWeight.w600),
              ),
            ),
          OutlinedButton.icon(
            onPressed: onRefrescar,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Refrescar'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.steelBlue,
              side: const BorderSide(color: AppColors.inputBorder),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }
}

class _BotonChip extends StatelessWidget {
  final String etiqueta;
  final IconData icon;
  final VoidCallback onTap;

  const _BotonChip({required this.etiqueta, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.inputBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: AppColors.steelBlue),
            const SizedBox(width: 8),
            Text(
              etiqueta,
              style: AppTextStyles.label.copyWith(fontSize: 12.5, color: AppColors.steelBlue),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChipFecha extends StatelessWidget {
  final String etiqueta;
  final bool activo;
  final VoidCallback onTap;

  const _ChipFecha({required this.etiqueta, required this.activo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = activo ? AppColors.orange : AppColors.graphiteGray;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: activo ? AppColors.orange.withOpacity(0.1) : AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: activo ? AppColors.orange.withOpacity(0.5) : AppColors.inputBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today_outlined, size: 15, color: color),
            const SizedBox(width: 8),
            Text(
              etiqueta,
              style: AppTextStyles.label.copyWith(fontSize: 12.5, color: color),
            ),
          ],
        ),
      ),
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
