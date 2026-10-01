import 'package:flutter/material.dart';
import 'package:sidebarx/sidebarx.dart';
import '../../core/responsive.dart';
import '../../theme/app_colors.dart';
import '../../widgets/admin/admin_barra_movil.dart';
import '../../widgets/admin/admin_sidebar.dart';
import '../../widgets/common/carga/zona_carga.dart';
import 'arqueo_caja_screen.dart';
import 'auditoria_comodato_screen.dart';
import 'consola_ventas_screen.dart';
import 'cuentas_corrientes_screen.dart';
import 'dashboard_reportes_screen.dart';
import 'gestion_choferes_screen.dart';
import 'gestion_flota_screen.dart';
import 'placeholder_admin_section.dart';
import 'planificacion_visitas_screen.dart';
import 'reporte_canjes_screen.dart';
import 'seguimiento_tiempo_real_screen.dart';
import 'tablero_hoja_ruta_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final _sidebar = SidebarXController(selectedIndex: 1, extended: true);
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool? _eraEscritorio;
  bool _esMovil = false;
  int _indiceAnterior = 1;

  int get _selectedIndex => _sidebar.selectedIndex;

  @override
  void initState() {
    super.initState();
    _sidebar.addListener(_alCambiarSidebar);
  }

  @override
  void dispose() {
    _sidebar.removeListener(_alCambiarSidebar);
    _sidebar.dispose();
    super.dispose();
  }

  void _alCambiarSidebar() {
    if (!mounted) return;
    final cambioSeccion = _sidebar.selectedIndex != _indiceAnterior;
    _indiceAnterior = _sidebar.selectedIndex;
    if (cambioSeccion && _esMovil && (_scaffoldKey.currentState?.isDrawerOpen ?? false)) {
      _scaffoldKey.currentState?.closeDrawer();
    }
    setState(() {});
  }

  void _ajustarAncho(bool esEscritorio, bool esMovil) {
    _esMovil = esMovil;
    final extendido = esEscritorio || esMovil;
    final cambioModo = _eraEscritorio != extendido;
    _eraEscritorio = extendido;
    if ((cambioModo || esMovil) && _sidebar.extended != extendido) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _sidebar.setExtended(extendido);
      });
    }
  }

  Widget get _contenido => ZonaCarga(
        child: KeyedSubtree(
          key: ValueKey(_selectedIndex),
          child: _body,
        ),
      );

  Widget get _body {
    switch (_selectedIndex) {
      case 0:
        return const DashboardReportesScreen();
      case 1:
        return const PlanificacionVisitasScreen();
      case 2:
        return const SeguimientoTiempoRealScreen();
      case 3:
        return const TableroHojaRutaScreen();
      case 4:
        return const GestionFlotaScreen();
      case 5:
        return const ArqueoCajaScreen();
      case 6:
        return const CuentasCorrientesScreen();
      case 7:
        return const ConsolaVentasScreen();
      case 8:
        return const AuditoriaComodatoAdminScreen();
      case 9:
        return const ReporteCanjesScreen();
      case 10:
        return const GestionChoferesScreen();
      default:
        return const PlaceholderAdminSection(
          title: 'Configuración',
          icon: Icons.settings_outlined,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final esMovil = Responsive.isMobile(constraints);
        _ajustarAncho(Responsive.isDesktop(constraints), esMovil);
        if (esMovil) {
          return Scaffold(
            key: _scaffoldKey,
            backgroundColor: AppColors.background,
            drawerEdgeDragWidth: 24,
            drawerScrimColor: Colors.black.withOpacity(0.45),
            drawer: Drawer(
              width: AdminSidebar.anchoExpandido + 12,
              backgroundColor: SidebarPaleta.lienzo,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.horizontal(right: Radius.circular(20)),
              ),
              child: SafeArea(
                child: AdminSidebar(controller: _sidebar, enDrawer: true),
              ),
            ),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AdminBarraMovil(
                  indice: _selectedIndex,
                  onMenu: () => _scaffoldKey.currentState?.openDrawer(),
                ),
                Expanded(
                  child: SafeArea(top: false, child: _contenido),
                ),
              ],
            ),
          );
        }
        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: AppColors.background,
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SafeArea(
                right: false,
                child: AdminSidebar(controller: _sidebar),
              ),
              Expanded(
                child: SafeArea(
                  left: false,
                  child: _contenido,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
