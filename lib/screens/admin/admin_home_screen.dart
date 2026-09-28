import 'package:flutter/material.dart';
import '../../core/responsive.dart';
import '../../theme/app_colors.dart';
import '../../widgets/admin/admin_sidebar.dart';
import '../../widgets/admin/admin_topbar.dart';
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
  int _selectedIndex = 1;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

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
        final isDesktop = Responsive.isDesktop(constraints);

        if (isDesktop) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 240,
                  child: AdminSidebar(
                    selectedIndex: _selectedIndex,
                    onSelect: (i) => setState(() => _selectedIndex = i),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const AdminTopbar(),
                      Expanded(child: ZonaCarga(child: _body)),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: AppColors.background,
          drawer: Drawer(
            child: SafeArea(
              child: AdminSidebar(
                selectedIndex: _selectedIndex,
                onSelect: (i) {
                  setState(() => _selectedIndex = i);
                  Navigator.of(context).pop();
                },
              ),
            ),
          ),
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(
              64 + MediaQuery.of(context).padding.top,
            ),
            child: SafeArea(
              bottom: false,
              child: AdminTopbar(
                onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
              ),
            ),
          ),
          body: SafeArea(
            top: false,
            child: ZonaCarga(child: _body),
          ),
        );
      },
    );
  }
}
