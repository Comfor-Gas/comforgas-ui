import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';


class DesktopSidePanel extends StatelessWidget {
  const DesktopSidePanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: AppColors.steelBlue,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 48),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: double.infinity,
                  child: Text(
                    'Panel de Control',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.panelTitle,
                  ),
                ),
                const SizedBox(height: 36),
                AspectRatio(
                  aspectRatio: 1.15,
                  child: _DashboardIllustration(),
                ),
                const SizedBox(height: 36),
                const Text(
                  'Optimiza tu operación con control y gestión de rutas en '
                  'tiempo real, agiliza el cierre y la conciliación diaria '
                  'de forma exacta, y toma decisiones estratégicas al '
                  'instante con reportes y KPIs gerenciales.',
                  style: AppTextStyles.panelBody,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardIllustration extends StatelessWidget {
  const _DashboardIllustration();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/dashboard_illustration.png',
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.15)),
        ),
        alignment: Alignment.center,
        child: Icon(
          Icons.dashboard_customize_outlined,
          size: 88,
          color: Colors.white.withOpacity(0.5),
        ),
      ),
    );
  }
}
