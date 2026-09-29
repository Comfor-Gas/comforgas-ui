import 'package:flutter/material.dart';
import '../../core/responsive.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class PlaceholderAdminSection extends StatelessWidget {
  final String title;
  final IconData icon;

  const PlaceholderAdminSection({
    super.key,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final movil = Responsive.isMobileContext(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: movil ? 48 : 56, color: AppColors.inputHint),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: movil
                  ? AppTextStyles.desktopTitle.copyWith(fontSize: 22)
                  : AppTextStyles.desktopTitle,
            ),
            const SizedBox(height: 8),
            Text(
              'Sección en construcción',
              textAlign: TextAlign.center,
              style: AppTextStyles.desktopSubtitle,
            ),
          ],
        ),
      ),
    );
  }
}
