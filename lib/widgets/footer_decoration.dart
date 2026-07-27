import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class FooterDecoration extends StatelessWidget {
  const FooterDecoration({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Ayuda', style: AppTextStyles.footer),
            _dot(),
            Text('Soporte', style: AppTextStyles.footer),
            _dot(),
            Text('Versión 2.4.1', style: AppTextStyles.footer),
          ],
        ),
        const SizedBox(height: 14),
        Text('App Móvil de Campo', style: AppTextStyles.footer),
        const SizedBox(height: 12),
        Container(
          height: 8,
          width: double.infinity,
          color: AppColors.orange,
        ),
      ],
    );
  }

  Widget _dot() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Container(
        height: 12,
        width: 1,
        color: AppColors.inputBorder,
      ),
    );
  }
}
