import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/app_lock_controller.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/chofer/chofer_nav_bar.dart';
import 'agenda_chofer_screen.dart';
import 'inicio/inicio_chofer_screen.dart';
import 'rendicion/rendicion_ruta_screen.dart';
import 'stock/stock_chofer_screen.dart';
import '../../core/feedback/app_feedback.dart';

class ChoferHomeScreen extends StatefulWidget {
  const ChoferHomeScreen({super.key});

  @override
  State<ChoferHomeScreen> createState() => _ChoferHomeScreenState();
}

class _ChoferHomeScreenState extends State<ChoferHomeScreen> {
  static const int _tabInicio = 0;
  static const int _tabAgenda = 1;
  static const int _tabRendicion = 3;

  int _index = _tabInicio;

  void _irA(int i) {
    if (i == _index) return;
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _index,
        children: [
          InicioChoferScreen(
            visible: _index == _tabInicio,
            onIrAgenda: () => _irA(_tabAgenda),
          ),
          const AgendaChoferScreen(),
          const StockChoferScreen(),
          RendicionRutaScreen(visible: _index == _tabRendicion),
          const _ChoferPerfilTab(),
        ],
      ),
      bottomNavigationBar: ChoferNavBar(
        indice: _index,
        onCambio: _irA,
      ),
    );
  }
}

class _ChoferPerfilTab extends StatefulWidget {
  const _ChoferPerfilTab();

  @override
  State<_ChoferPerfilTab> createState() => _ChoferPerfilTabState();
}

class _ChoferPerfilTabState extends State<_ChoferPerfilTab> {
  bool _loadingBiometric = true;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  bool _togglingBiometric = false;

  @override
  void initState() {
    super.initState();
    _loadBiometricState();
  }

  Future<void> _loadBiometricState() async {
    final auth = context.read<AuthProvider>();
    final available = await auth.isBiometricAvailable;
    final enabled = await auth.isBiometricEnabled;
    if (!mounted) return;
    setState(() {
      _biometricAvailable = available;
      _biometricEnabled = enabled && available;
      _loadingBiometric = false;
    });
  }

  Future<void> _onBiometricToggle(bool value) async {
    final auth = context.read<AuthProvider>();
    setState(() => _togglingBiometric = true);

    if (value) {
      final confirmed = await auth.verifyBiometrics();
      if (confirmed) {
        await auth.enableBiometrics();
        if (mounted) setState(() => _biometricEnabled = true);
      } else if (mounted) {
        AppFeedback.error('No se pudo confirmar la huella/PIN. Intentá de nuevo.');
      }
    } else {
      await auth.disableBiometrics();
      if (mounted) setState(() => _biometricEnabled = false);
    }

    if (!mounted) return;
    await context.read<AppLockController>().refreshFromStorage(userEmail: auth.user?.email);
    if (!mounted) return;
    setState(() => _togglingBiometric = false);
  }

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
            if (_loadingBiometric)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.orange),
                  ),
                ),
              )
            else if (_biometricAvailable)
              Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.inputBorder),
                ),
                child: SwitchListTile.adaptive(
                  value: _biometricEnabled,
                  onChanged: _togglingBiometric ? null : _onBiometricToggle,
                  activeColor: AppColors.orange,
                  title: const Text('Ingreso con huella o PIN', style: AppTextStyles.label),
                  subtitle: const Text(
                    'Usá tu huella, rostro o el código del celular para entrar más rápido.',
                    style: AppTextStyles.footer,
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.inputBorder),
                ),
                child: const Text(
                  'Este dispositivo no tiene huella, rostro o código de seguridad configurado.',
                  style: AppTextStyles.footer,
                ),
              ),
            const SizedBox(height: 24),
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
