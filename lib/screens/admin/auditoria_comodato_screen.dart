import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/responsive.dart';
import '../../models/control_comodato.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/catalogo_repository.dart';
import '../../repositories/comodato_repository.dart';
import '../../repositories/network_exception.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/admin/comodato/auditoria_comodato_fila.dart';
import '../../widgets/common/carga/zona_carga.dart';
import '../../widgets/common/filtros/filtros.dart';

class AuditoriaComodatoAdminScreen extends StatefulWidget {
  const AuditoriaComodatoAdminScreen({super.key});

  @override
  State<AuditoriaComodatoAdminScreen> createState() => _AuditoriaComodatoAdminScreenState();
}

class _AuditoriaComodatoAdminScreenState extends State<AuditoriaComodatoAdminScreen> {
  late final ComodatoRepository _repo;
  late final CatalogoRepository _catalogoRepo;

  bool _loading = true;
  String? _error;
  List<ControlComodato> _controles = [];
  Map<int, String> _nombrePorCliente = {};

  bool _soloFaltantes = true;
  DateTime? _desde;
  DateTime? _hasta;
  final _filtroCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final apiClient = context.read<AuthProvider>().apiClient;
    _repo = ComodatoRepository(apiClient);
    _catalogoRepo = CatalogoRepository(apiClient);
    _filtroCtrl.addListener(() => setState(() {}));
    _cargarClientes();
    _cargar();
  }

  Future<void> _cargarClientes() async {
    try {
      final clientes = await _catalogoRepo.listarClientes();
      if (!mounted) return;
      setState(() {
        _nombrePorCliente = {
          for (final c in clientes)
            if (c.idClienteExt != null && c.nombre.trim().isNotEmpty)
              c.idClienteExt!: c.nombre.trim(),
        };
      });
    } catch (_) {}
  }

  String _nombreDe(ControlComodato c) {
    final id = c.idClienteExt;
    if (id != null) {
      final nombre = _nombrePorCliente[id];
      if (nombre != null && nombre.isNotEmpty) return nombre;
    }
    return '';
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
      final data = await _repo.buscarAuditoria(
        desde: _desde,
        hasta: _hasta,
        soloFaltantes: _soloFaltantes,
      );
      if (!mounted) return;
      setState(() {
        _controles = data;
        _loading = false;
      });
    } on NetworkException {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo conectar con el servidor. Revisá tu conexión.';
        _loading = false;
      });
    } on ComodatoRepositoryException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo cargar la auditoría de comodato.';
        _loading = false;
      });
    }
  }

  List<ControlComodato> get _filtrados {
    final q = _filtroCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return _controles;
    return _controles.where((c) {
      final chofer = (c.nombreChofer ?? '').toLowerCase();
      final nombre = _nombreDe(c).toLowerCase();
      final cliente = '$nombre cliente #${c.idClienteExt ?? ''}'.toLowerCase();
      final obs = (c.observaciones ?? '').toLowerCase();
      return chofer.contains(q) || cliente.contains(q) || obs.contains(q);
    }).toList();
  }

  int get _totalFaltantes =>
      _filtrados.fold(0, (a, c) => a + c.faltante);

  int get _conAlerta => _filtrados.where((c) => c.tieneFaltante).length;

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
                total: _filtrados.length,
                conAlerta: _conAlerta,
                cilindrosFaltantes: _totalFaltantes,
              ),
              const SizedBox(height: 18),
              _Filtros(
                filtroCtrl: _filtroCtrl,
                soloFaltantes: _soloFaltantes,
                desde: _desde,
                hasta: _hasta,
                onToggleFaltantes: (v) {
                  setState(() => _soloFaltantes = v);
                  _cargar();
                },
                cargando: _loading,
                onCambioRango: _cambiarRango,
                onRefrescar: _cargar,
              ),
              const SizedBox(height: 18),
              _buildTabla(constraints.maxWidth - (padding.horizontal)),
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
    } else if (_filtrados.isEmpty) {
      contenido = Padding(
        padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
        child: Center(
          child: Text(
            _soloFaltantes
                ? 'No hay controles con faltantes para los filtros elegidos.'
                : 'No hay controles de comodato para los filtros elegidos.',
            textAlign: TextAlign.center,
            style: AppTextStyles.link,
          ),
        ),
      );
    } else {
      contenido = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < _filtrados.length; i++)
            AuditoriaComodatoFila(
              control: _filtrados[i],
              par: i.isEven,
              nombreCliente: _nombreDe(_filtrados[i]),
            ),
        ],
      );
    }

    final anchoTabla = anchoDisponible < 860 ? 860.0 : anchoDisponible;

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
        Text('Auditoría de Comodato', style: AppTextStyles.desktopTitle),
        const SizedBox(height: 4),
        Text(
          'Controles físicos de envases realizados por los choferes, con foco en faltantes.',
          style: AppTextStyles.desktopSubtitle,
        ),
      ],
    );
  }
}

class _Stats extends StatelessWidget {
  final int total;
  final int conAlerta;
  final int cilindrosFaltantes;

  const _Stats({
    required this.total,
    required this.conAlerta,
    required this.cilindrosFaltantes,
  });

  @override
  Widget build(BuildContext context) {
    final cards = [
      _StatCard(
        etiqueta: 'Controles',
        valor: '$total',
        color: AppColors.steelBlue,
        icon: Icons.fact_check_outlined,
      ),
      _StatCard(
        etiqueta: 'Con faltante',
        valor: '$conAlerta',
        color: AppColors.badgeRed,
        icon: Icons.warning_amber_rounded,
      ),
      _StatCard(
        etiqueta: 'Cilindros faltantes',
        valor: '$cilindrosFaltantes',
        color: AppColors.orange,
        icon: Icons.propane_tank_rounded,
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
  final bool soloFaltantes;
  final DateTime? desde;
  final DateTime? hasta;
  final bool cargando;
  final ValueChanged<bool> onToggleFaltantes;
  final void Function(DateTime? desde, DateTime? hasta) onCambioRango;
  final VoidCallback onRefrescar;

  const _Filtros({
    required this.filtroCtrl,
    required this.soloFaltantes,
    required this.desde,
    required this.hasta,
    required this.cargando,
    required this.onToggleFaltantes,
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
              hint: 'Chofer, cliente u observación',
              icono: Icons.search,
              ancho: 300,
            ),
            ChipFiltro(
              etiqueta: 'Solo faltantes',
              activo: soloFaltantes,
              icono: soloFaltantes ? Icons.check_box_outlined : Icons.check_box_outline_blank,
              onTap: () => onToggleFaltantes(!soloFaltantes),
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
          Expanded(flex: 3, child: _Th('Chofer')),
          Expanded(flex: 3, child: _Th('Cliente')),
          Expanded(flex: 2, child: _Th('Fecha')),
          Expanded(flex: 2, child: _Th('Contratadas')),
          Expanded(flex: 2, child: _Th('Físicas')),
          Expanded(flex: 3, child: _Th('Estado')),
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