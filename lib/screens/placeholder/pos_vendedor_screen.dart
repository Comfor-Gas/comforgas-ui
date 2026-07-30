import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';


enum VendedorSection {
  ventas('Ventas', Icons.point_of_sale_outlined),
  pedidos('Pedidos', Icons.receipt_long_outlined),
  comodato('Comodato', Icons.handshake_outlined),
  cierreCaja('Cierre de Caja', Icons.savings_outlined);

  const VendedorSection(this.label, this.icon);

  final String label;
  final IconData icon;
}

class PosVendedorScreen extends StatefulWidget {
  const PosVendedorScreen({super.key});

  @override
  State<PosVendedorScreen> createState() => _PosVendedorScreenState();
}

class _PosVendedorScreenState extends State<PosVendedorScreen> {
  VendedorSection _section = VendedorSection.ventas;

  void _selectSection(VendedorSection section) {
    setState(() => _section = section);
    Navigator.of(context).pop();
  }

  Future<void> _logout() async {
    final auth = context.read<AuthProvider>();
    Navigator.of(context).pop();
    await auth.logout();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.steelBlue,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.white),
        title: Text(
          _section.label,
          style: AppTextStyles.title.copyWith(
            color: AppColors.white,
            fontSize: 18,
          ),
        ),
      ),
      drawer: _VendedorDrawer(
        current: _section,
        onSelect: _selectSection,
        onLogout: _logout,
      ),
      body: _SectionBody(section: _section),
    );
  }
}

class _VendedorDrawer extends StatelessWidget {
  final VendedorSection current;
  final ValueChanged<VendedorSection> onSelect;
  final Future<void> Function() onLogout;

  const _VendedorDrawer({
    required this.current,
    required this.onSelect,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Drawer(
      backgroundColor: AppColors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              color: AppColors.steelBlue,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppColors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Image.asset(
                          'assets/images/logomolecula.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              auth.user?.fullName?.isNotEmpty == true
                                  ? auth.user!.fullName!
                                  : 'Vendedor Local',
                              style: AppTextStyles.title.copyWith(
                                color: AppColors.white,
                                fontSize: 17,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Vendedor Local',
                              style: AppTextStyles.footer.copyWith(
                                color: AppColors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    auth.user?.email ?? '—',
                    style: AppTextStyles.input.copyWith(color: AppColors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            for (final section in VendedorSection.values)
              _DrawerItem(
                section: section,
                selected: section == current,
                onTap: () => onSelect(section),
              ),
            const Spacer(),
            const Divider(height: 1, color: AppColors.inputBorder),
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.error),
              title: Text(
                'Cerrar sesión',
                style: AppTextStyles.label.copyWith(color: AppColors.error),
              ),
              onTap: onLogout,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final VendedorSection section;
  final bool selected;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.section,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color color = selected ? AppColors.orange : AppColors.steelBlue;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color:
            selected ? AppColors.orange.withOpacity(0.10) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(section.icon, color: color),
        title: Text(
          section.label,
          style: AppTextStyles.label.copyWith(color: color),
        ),
        selected: selected,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        onTap: onTap,
      ),
    );
  }
}

class _SectionBody extends StatelessWidget {
  final VendedorSection section;

  const _SectionBody({required this.section});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(section.icon, size: 56, color: AppColors.steelBlue),
                const SizedBox(height: 16),
                Text(
                  section.label,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.title.copyWith(fontSize: 22),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sección en construcción.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.link.copyWith(
                    color: AppColors.graphiteGray,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
