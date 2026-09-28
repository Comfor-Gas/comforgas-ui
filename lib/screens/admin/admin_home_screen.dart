import 'package:flutter/material.dart';
import 'package:sidebarx/sidebarx.dart';
import '../../core/responsive.dart';
import '../../theme/app_colors.dart';
import '../../widgets/admin/admin_sidebar.dart';
import '../../widgets/common/carga/zona_carga.dart';
import 'arqueo_caja_screen.dart';
import 'auditoria_comodato_screen.dart';
import 'consola_ventas_screen.dart';
import 'cuentas_corrientes_screen.dart';
import 'dashboard_reportes_screen.dart';
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
  bool? _eraEscritorio;

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
    if (mounted) setState(() {});
  }

  void _ajustarAncho(bool esEscritorio) {
    if (_eraEscritorio == esEscritorio) return;
    _eraEscritorio = esEscritorio;
    if (_sidebar.extended != esEscritorio) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _sidebar.setExtended(esEscritorio);
      });
    }
  }

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
        _ajustarAncho(Responsive.isDesktop(constraints));
        return Scaffold(
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
                  child: ZonaCarga(
                    child: KeyedSubtree(
                      key: ValueKey(_selectedIndex),
                      child: _body,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
