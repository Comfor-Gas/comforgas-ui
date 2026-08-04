import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'agenda_chofer_screen.dart';

class ChoferHomeScreen extends StatefulWidget {
  const ChoferHomeScreen({super.key});

  @override
  State<ChoferHomeScreen> createState() => _ChoferHomeScreenState();
}

class _ChoferHomeScreenState extends State<ChoferHomeScreen> {
  int _index = 0;

  Widget get _body {
    switch (_index) {
      case 0:
        return const AgendaChoferScreen();
      case 1:
        return const _ChoferPlaceholderTab(
          icon: Icons.receipt_long_outlined,
          title: 'Pedidos',
        );
      case 2:
        return const _ChoferPlaceholderTab(
          icon: Icons.inventory_2_outlined,
          title: 'Comodato',
        );
      default:
        return const _ChoferPerfilTab();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _body,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.orange,
        unselectedItemColor: AppColors.graphiteGray,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.event_note_outlined),
            label: 'Agenda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            label: 'Pedidos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            label: 'Comodato',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

class _ChoferPlaceholderTab extends StatelessWidget {
  final IconData icon;
  final String title;

  const _ChoferPlaceholderTab({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: AppColors.inputHint),
            const SizedBox(height: 16),
            Text(title, style: AppTextStyles.title),
            const SizedBox(height: 8),
            Text('Sección en construcción', style: AppTextStyles.link),
          ],
        ),
      ),
    );
  }
}

class _ChoferPerfilTab extends StatelessWidget {
  const _ChoferPerfilTab();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final nombre = auth.user?.fullName?.trim().isNotEmpty == true
        ? auth.user!.fullName!
        : 'Chofer';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 36,
              backgroundColor: AppColors.steelBlue.withOpacity(0.1),
              child: const Icon(Icons.person, size: 36, color: AppColors.steelBlue),
            ),
            const SizedBox(height: 16),
            Text(nombre, textAlign: TextAlign.center, style: AppTextStyles.title),
            const SizedBox(height: 4),
            Text(
              auth.user?.email ?? '—',
              textAlign: TextAlign.center,
              style: AppTextStyles.link,
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: () => context.read<AuthProvider>().logout(),
              icon: const Icon(Icons.logout),
              label: const Text('Cerrar sesión'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
