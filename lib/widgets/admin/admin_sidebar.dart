import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sidebarx/sidebarx.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';

class AdminNavItem {
  final IconData icon;
  final String label;

  const AdminNavItem({required this.icon, required this.label});
}

const List<AdminNavItem> adminNavItems = [
  AdminNavItem(icon: Icons.dashboard_outlined, label: 'Dashboard'),
  AdminNavItem(icon: Icons.event_note_outlined, label: 'Planificación'),
  AdminNavItem(icon: Icons.location_on_outlined, label: 'Seguimiento'),
  AdminNavItem(icon: Icons.alt_route_outlined, label: 'Rutas'),
  AdminNavItem(icon: Icons.local_shipping_outlined, label: 'Flota'),
  AdminNavItem(icon: Icons.savings_outlined, label: 'Cobranzas'),
  AdminNavItem(icon: Icons.account_balance_outlined, label: 'Cuentas Ctes'),
  AdminNavItem(icon: Icons.point_of_sale_outlined, label: 'Ventas'),
  AdminNavItem(icon: Icons.assignment_outlined, label: 'Comodato'),
  AdminNavItem(icon: Icons.assignment_return_outlined, label: 'Devoluciones'),
  AdminNavItem(icon: Icons.admin_panel_settings_outlined, label: 'Administradores'),
  AdminNavItem(icon: Icons.settings_outlined, label: 'Configuración'),
];

class SidebarPaleta {
  SidebarPaleta._();

  static const Color lienzo = AppColors.sidebarBackground;
  static const Color lienzoAcento = Color(0xFF3D5470);
  static const Color hover = Color(0xFF3A4E66);
  static final Color texto = Colors.white.withValues(alpha: 0.72);
  static final Divider divisor = Divider(color: Colors.white.withValues(alpha: 0.14), height: 1);
}

class AdminSidebar extends StatelessWidget {
  final SidebarXController controller;
  final bool enDrawer;

  const AdminSidebar({super.key, required this.controller, this.enDrawer = false});

  static const double anchoColapsado = 70;
  static const double anchoExpandido = 240;

  @override
  Widget build(BuildContext context) {
    return SidebarX(
      controller: controller,
      animationDuration: const Duration(milliseconds: 220),
      showToggleButton: false,
      theme: SidebarXTheme(
        width: anchoColapsado,
        margin: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: SidebarPaleta.lienzo,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.steelBlue.withValues(alpha: 0.18),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        hoverColor: SidebarPaleta.hover,
        textStyle: TextStyle(color: SidebarPaleta.texto, fontSize: 13.5, fontWeight: FontWeight.w500),
        selectedTextStyle: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w700),
        hoverTextStyle: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600),
        itemTextPadding: const EdgeInsets.only(left: 26),
        selectedItemTextPadding: const EdgeInsets.only(left: 26),
        itemMargin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        selectedItemMargin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        itemPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        selectedItemPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        itemDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: SidebarPaleta.lienzo),
        ),
        selectedItemDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.orange.withValues(alpha: 0.45)),
          gradient: const LinearGradient(
            colors: [SidebarPaleta.lienzoAcento, SidebarPaleta.lienzo],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.28),
              blurRadius: 30,
            ),
          ],
        ),
        iconTheme: IconThemeData(color: SidebarPaleta.texto, size: 20),
        hoverIconTheme: const IconThemeData(color: Colors.white, size: 20),
        selectedIconTheme: const IconThemeData(color: AppColors.orange, size: 20),
      ),
      extendedTheme: const SidebarXTheme(
        width: anchoExpandido,
        margin: EdgeInsets.zero,
        decoration: BoxDecoration(color: SidebarPaleta.lienzo),
      ),
      footerDivider: SidebarPaleta.divisor,
      headerBuilder: (context, extendido) => _Encabezado(extendido: extendido),
      footerBuilder: (context, extendido) =>
          _Pie(extendido: extendido, controller: controller, mostrarPlegar: !enDrawer),
      items: [
        for (final item in adminNavItems) SidebarXItem(icon: item.icon, label: item.label),
      ],
    );
  }
}

class _Encabezado extends StatelessWidget {
  final bool extendido;

  const _Encabezado({required this.extendido});

  @override
  Widget build(BuildContext context) {
    if (!extendido) {
      return const SizedBox(
        height: 100,
        child: Center(child: _LogoCircular(tamanio: 42)),
      );
    }
    return const _AnchoExpandido(
      child: SizedBox(
        height: 132,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LogoCircular(tamanio: 58),
            SizedBox(height: 10),
            Text(
              'COMFOR GAS',
              maxLines: 1,
              overflow: TextOverflow.clip,
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogoCircular extends StatelessWidget {
  final double tamanio;

  const _LogoCircular({required this.tamanio});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: tamanio,
      height: tamanio,
      padding: EdgeInsets.all(tamanio * 0.16),
      decoration: BoxDecoration(
        color: AppColors.white,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.orange, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.orange.withValues(alpha: 0.35),
            blurRadius: 12,
          ),
        ],
      ),
      child: Image.asset('assets/images/logomolecula.png', fit: BoxFit.contain),
    );
  }
}

class _AnchoExpandido extends StatelessWidget {
  final Widget child;

  const _AnchoExpandido({required this.child});

  @override
  Widget build(BuildContext context) {
    return UnconstrainedBox(
      alignment: Alignment.topLeft,
      constrainedAxis: Axis.vertical,
      clipBehavior: Clip.hardEdge,
      child: SizedBox(width: AdminSidebar.anchoExpandido, child: child),
    );
  }
}

class _CerrarSesion extends StatefulWidget {
  final bool extendido;

  const _CerrarSesion({required this.extendido});

  @override
  State<_CerrarSesion> createState() => _CerrarSesionState();
}

class _CerrarSesionState extends State<_CerrarSesion> {
  bool _hover = false;
  bool _saliendo = false;

  Future<void> _confirmar() async {
    if (_saliendo) return;
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '¿Cerrar sesión?',
          style: TextStyle(color: AppColors.steelBlue, fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Vas a salir del panel de administración.',
          style: TextStyle(color: AppColors.graphiteGray),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.graphiteGray)),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Cerrar sesión',
              style: TextStyle(color: AppColors.orange, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
    if (confirmado != true || !mounted) return;
    setState(() => _saliendo = true);
    await context.read<AuthProvider>().logout();
    if (mounted) setState(() => _saliendo = false);
  }

  @override
  Widget build(BuildContext context) {
    final color = _hover ? AppColors.orange : SidebarPaleta.texto;
    final icono = _saliendo
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.orange),
          )
        : Icon(Icons.logout_rounded, size: 20, color: color);

    final contenido = MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _confirmar,
        child: Container(
          margin: const EdgeInsets.fromLTRB(6, 8, 6, 2),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: _hover ? SidebarPaleta.hover : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: widget.extendido ? MainAxisAlignment.start : MainAxisAlignment.center,
            children: [
              icono,
              if (widget.extendido) ...[
                const SizedBox(width: 26),
                Flexible(
                  child: Text(
                    'Cerrar sesión',
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                    style: TextStyle(
                      color: color,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if (widget.extendido) return contenido;
    return Tooltip(message: 'Cerrar sesión', child: contenido);
  }
}

class _Pie extends StatelessWidget {
  final bool extendido;
  final SidebarXController controller;
  final bool mostrarPlegar;

  const _Pie({required this.extendido, required this.controller, this.mostrarPlegar = true});

  @override
  Widget build(BuildContext context) {
    final plegar = _BotonPlegar(extendido: extendido, onTap: controller.toggleExtended);
    if (!extendido) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _CerrarSesion(extendido: false),
            plegar,
          ],
        ),
      );
    }
    return _AnchoExpandido(
      child: Padding(
        padding: const EdgeInsets.only(right: 8, bottom: 6),
        child: Row(
          children: [
            const Expanded(child: _CerrarSesion(extendido: true)),
            if (mostrarPlegar) plegar,
          ],
        ),
      ),
    );
  }
}

class _BotonPlegar extends StatelessWidget {
  final bool extendido;
  final VoidCallback onTap;

  const _BotonPlegar({required this.extendido, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: extendido ? 'Contraer menú' : 'Expandir menú',
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          hoverColor: SidebarPaleta.hover,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(
              extendido ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
              color: SidebarPaleta.texto,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}
