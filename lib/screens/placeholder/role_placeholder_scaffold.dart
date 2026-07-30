import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../login_screen.dart';

class RolePlaceholderScaffold extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;

  const RolePlaceholderScaffold({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.steelBlue,
        elevation: 0,
        titleSpacing: 8,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Image.asset(
            'assets/images/logomolecula.png',
            width: 28,
            height: 28,
            fit: BoxFit.contain,
          ),
        ),
        title: Text(
          title,
          style: AppTextStyles.title.copyWith(
            color: AppColors.white,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(icon, size: 48, color: AppColors.steelBlue),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.title.copyWith(fontSize: 20),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.link.copyWith(color: AppColors.graphiteGray),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Vista pendiente de diseño',
                        style: AppTextStyles.footer,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sesión activa', style: AppTextStyles.label),
                    const SizedBox(height: 6),
                    Text(
                      auth.user?.email ?? '—',
                      style: AppTextStyles.input.copyWith(color: AppColors.graphiteGray),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Rol: ${auth.role.name}',
                      style: AppTextStyles.input.copyWith(color: AppColors.graphiteGray),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              OutlinedButton(
                onPressed: () async {
                  await context.read<AuthProvider>().logout();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.steelBlue,
                  side: const BorderSide(color: AppColors.steelBlue, width: 1.4),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Cerrar sesión',
                  style: AppTextStyles.button.copyWith(color: AppColors.steelBlue),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
