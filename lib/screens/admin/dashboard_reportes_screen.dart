import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/feedback/app_feedback.dart';
import '../../core/responsive.dart';
import '../../models/dashboard/dashboard_filtros.dart';
import '../../models/dashboard/dashboard_kpis.dart';
import '../../models/dashboard/tendencia_punto.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/catalogo_repository.dart';
import '../../repositories/dashboard_repository.dart';
import '../../repositories/network_exception.dart';
import '../../repositories/reporte_export_repository.dart';
import '../../services/descarga_archivo.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/admin/dashboard/cobertura_rutas_chart_card.dart';
import '../../widgets/admin/dashboard/dashboard_filtros_panel.dart';
import '../../widgets/admin/dashboard/desglose_choferes_tabla.dart';
import '../../widgets/admin/dashboard/exportar_botones.dart';
import '../../widgets/common/carga/zona_carga.dart';
import '../../widgets/common/filtros/filtro_buscable.dart';
import '../../widgets/admin/dashboard/kpi_cards_grid.dart';
import '../../widgets/admin/dashboard/tendencia_chart_card.dart';
import '../../widgets/admin/dashboard/ventas_sucursal_card.dart';

class DashboardReportesScreen extends StatefulWidget {
  const DashboardReportesScreen({super.key});

  @override
  State<DashboardReportesScreen> createState() => _DashboardReportesScreenState();
}

class _DashboardReportesScreenState extends State<DashboardReportesScreen> {
  static const int _maxDiasExport = 366;

  late final DashboardRepository _repo;
  late final ReporteExportRepository _exportRepo;
  late final CatalogoRepository _catalogoRepo;

  DashboardFiltros _filtros = DashboardFiltros.inicial();
  DashboardKpis? _kpis;
  List<TendenciaPunto> _tendencia = const [];
  bool _cargandoKpis = true;
  bool _cargandoTendencia = true;
  String? _errorKpis;
  String? _errorTendencia;
  bool _exportando = false;
  int _solicitud = 0;

  List<OpcionFiltro> _choferes = const [];
  List<OpcionFiltro> _rutas = const [];
  List<OpcionFiltro> _sucursales = const [];
  bool _cargandoCatalogos = true;
  String? _errorCatalogos;

  @override
  void initState() {
    super.initState();
    final client = context.read<AuthProvider>().apiClient;
    _repo = DashboardRepository(client);
    _exportRepo = ReporteExportRepository(client);
    _catalogoRepo = CatalogoRepository(client);
    _cargarCatalogos();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _cargar();
    });
  }

  Future<void> _cargarCatalogos() async {
    try {
      final (usuarios, rutas, clientes) = await (
        _catalogoRepo.listarUsuarios(rol: 'CHOFER'),
        _catalogoRepo.listarRutas(),
        _catalogoRepo.listarClientes(),
      ).wait;
      if (!mounted) return;
      int ordenar(OpcionFiltro a, OpcionFiltro b) =>
          a.etiqueta.toLowerCase().compareTo(b.etiqueta.toLowerCase());
      setState(() {
        _choferes = [
          for (final u in usuarios)
            OpcionFiltro(u.id, u.fullName.trim().isNotEmpty ? u.fullName : u.email),
        ]..sort(ordenar);
        _rutas = [
          for (final r in rutas) OpcionFiltro('${r.idRuta}', r.nombre),
        ]..sort(ordenar);
        _sucursales = [
          for (final c in clientes)
            if (c.idSucursal > 0) OpcionFiltro('${c.idSucursal}', c.nombre),
        ]..sort(ordenar);
        _cargandoCatalogos = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _cargandoCatalogos = false;
        _errorCatalogos =
            'No se pudieron cargar las listas de choferes, rutas y clientes. Los indicadores se muestran sin esos filtros.';
      });
    }
  }

  Future<void> _cargar() async {
    final solicitud = ++_solicitud;
    final filtros = _filtros;
    setState(() {
      _cargandoKpis = true;
      _cargandoTendencia = true;
      _errorKpis = null;
      _errorTendencia = null;
    });

    try {
      final resultado = await _repo.obtener(filtros);
      if (!mounted || solicitud != _solicitud) return;
      setState(() {
        _kpis = resultado.kpis;
        _cargandoKpis = false;
      });
      final serie = resultado.serieBackend;
      if (serie != null) {
        setState(() {
          _tendencia = serie;
          _cargandoTendencia = false;
        });
        return;
      }
    } catch (e) {
      if (!mounted || solicitud != _solicitud) return;
      setState(() {
        _errorKpis = _mensaje(e, 'No se pudieron cargar los indicadores.');
        _cargandoKpis = false;
        _cargandoTendencia = false;
      });
      if (_kpis != null) AppFeedback.error(_errorKpis!);
      return;
    }

    await _cargarTendencia(solicitud, filtros);
  }

  Future<void> _cargarTendencia(int solicitud, DashboardFiltros filtros) async {
    if (filtros.cantidadDias < 2) {
      setState(() {
        _tendencia = const [];
        _cargandoTendencia = false;
      });
      return;
    }
    try {
      final puntos = await _repo.tendencia(filtros);
      if (!mounted || solicitud != _solicitud) return;
      setState(() {
        _tendencia = puntos;
        _cargandoTendencia = false;
      });
    } catch (e) {
      if (!mounted || solicitud != _solicitud) return;
      setState(() {
        _errorTendencia = _mensaje(e, 'No se pudo cargar la tendencia.');
        _tendencia = const [];
        _cargandoTendencia = false;
      });
    }
  }

  String _mensaje(Object e, String porDefecto) {
    if (e is NetworkException) return 'No se pudo conectar con el servidor. Revisá tu conexión.';
    if (e is DashboardRepositoryException) return e.message;
    if (e is ReporteExportException) return e.message;
    return porDefecto;
  }

  void _cambiarFiltros(DashboardFiltros nuevos) {
    setState(() => _filtros = nuevos);
    _cargar();
  }

  Future<void> _exportarExcel(TipoReporteExport tipo) async {
    if (!descargaDisponible) {
      AppFeedback.advertencia('La exportación a Excel está disponible desde la versión web.');
      return;
    }
    if (_filtros.cantidadDias > _maxDiasExport) {
      AppFeedback.advertencia('Para exportar, elegí un rango de hasta $_maxDiasExport días.');
      return;
    }
    setState(() => _exportando = true);
    AppFeedback.info(
      'La descarga empieza sola cuando el archivo esté listo.',
      titulo: 'Generando ${tipo.etiqueta}',
    );
    try {
      final archivo = await _exportRepo.exportar(
        tipo: tipo,
        formato: FormatoReporte.xlsx,
        filtros: _filtros,
      );
      await descargarArchivo(archivo.bytes, archivo.nombre, archivo.mimeType);
      if (!mounted) return;
      AppFeedback.exito('Se descargó ${archivo.nombre}.', titulo: 'Excel descargado');
    } catch (e) {
      AppFeedback.error(_mensaje(e, 'No se pudo generar el Excel.'), titulo: 'No se pudo exportar');
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  void _filtrarPorSucursal(VentaSucursal s) {
    if (s.idSucursal == null) return;
    _cambiarFiltros(_filtros.conSucursal(s.idSucursal));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final ancho = constraints.maxWidth;
        final padding = ancho >= 900 ? 28.0 : 16.0;
        final anchoContenido = ancho - padding * 2;
        return SingleChildScrollView(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Cabecera(exportando: _exportando, onExcel: _exportarExcel),
              const SizedBox(height: 18),
              DashboardFiltrosPanel(
                filtros: _filtros,
                choferes: _choferes,
                rutas: _rutas,
                sucursales: _sucursales,
                catalogosCargando: _cargandoCatalogos,
                catalogosError: _errorCatalogos,
                refrescando: _cargandoKpis,
                onCambio: _cambiarFiltros,
                onRefrescar: _cargar,
              ),
              const SizedBox(height: 18),
              ReportarCarga(cargando: _cargandoKpis || _cargandoTendencia || _exportando),
              ..._contenido(anchoContenido),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _contenido(double ancho) {
    final kpis = _kpis;
    if (kpis == null) {
      if (_errorKpis != null) {
        return [_ErrorCarga(mensaje: _errorKpis!, onReintentar: _cargar)];
      }
      return const [SizedBox(height: 320)];
    }

    const separador = SizedBox(height: 18, width: 18);
    final tendencia = TendenciaChartCard(
      puntos: _tendencia,
      cargando: _cargandoTendencia,
      error: _errorTendencia,
      onReintentar: _cargar,
    );
    final sucursales = VentasSucursalCard(
      sucursales: kpis.ventasPorSucursal,
      cargando: _cargandoKpis,
      onSeleccionar: _filtros.idSucursal == null ? _filtrarPorSucursal : null,
    );
    final cobertura = CoberturaRutasChartCard(rutas: kpis.rutas, cargando: _cargandoKpis);
    final amplio = ancho >= 1100;

    return [
      AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: _cargandoKpis ? 0.55 : 1,
        child: KpiCardsGrid(kpis: kpis),
      ),
      separador,
      if (amplio)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: cobertura),
            separador,
            Expanded(flex: 2, child: sucursales),
          ],
        )
      else ...[
        cobertura,
        separador,
        sucursales,
      ],
      separador,
      tendencia,
      separador,
      DesgloseChoferesTabla(choferes: kpis.choferes, cargando: _cargandoKpis),
    ];
  }
}

class _Cabecera extends StatelessWidget {
  final bool exportando;
  final ValueChanged<TipoReporteExport> onExcel;

  const _Cabecera({required this.exportando, required this.onExcel});

  @override
  Widget build(BuildContext context) {
    final movil = Responsive.isMobileContext(context);
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 14,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Dashboard / Reportes',
              style: movil ? AppTextStyles.desktopTitle.copyWith(fontSize: 22) : AppTextStyles.desktopTitle,
            ),
            const SizedBox(height: 4),
            Text(
              'Indicadores comerciales, cobertura de rutas y control de comodatos.',
              style: movil ? AppTextStyles.desktopSubtitle.copyWith(fontSize: 13) : AppTextStyles.desktopSubtitle,
            ),
          ],
        ),
        ExportarBotones(exportando: exportando, onExcel: onExcel),
      ],
    );
  }
}

class _ErrorCarga extends StatelessWidget {
  final String mensaje;
  final VoidCallback onReintentar;

  const _ErrorCarga({required this.mensaje, required this.onReintentar});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: Responsive.isMobileContext(context) ? 32 : 48,
        horizontal: Responsive.isMobileContext(context) ? 16 : 20,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_outlined, size: 40, color: AppColors.badgeGray),
          const SizedBox(height: 12),
          Text(mensaje, textAlign: TextAlign.center, style: AppTextStyles.input),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: onReintentar,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.steelBlue,
              side: const BorderSide(color: AppColors.steelBlue),
            ),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
