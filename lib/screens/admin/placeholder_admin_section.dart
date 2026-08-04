import 'package:flutter/material.dart';
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
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: AppColors.inputHint),
          const SizedBox(height: 16),
          Text(title, style: AppTextStyles.desktopTitle),
          const SizedBox(height: 8),
          Text(
            'Sección en construcción',
            style: AppTextStyles.desktopSubtitle,
          ),
        ],
      ),
    );
  }
}
