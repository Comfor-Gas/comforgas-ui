import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

class FaltanteBadge extends StatelessWidget {
  final int faltante;
  final int sobrante;
  final bool compacto;

  const FaltanteBadge({
    super.key,
    required this.faltante,
    this.sobrante = 0,
    this.compacto = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color color;
    final IconData icon;
    final String texto;

    if (faltante > 0) {
      color = AppColors.badgeRed;
      icon = Icons.warning_amber_rounded;
      texto = '-$faltante faltante${faltante == 1 ? '' : 's'}';
    } else if (sobrante > 0) {
      color = AppColors.badgeAmber;
      icon = Icons.info_outline;
      texto = '+$sobrante sobrante${sobrante == 1 ? '' : 's'}';
    } else {
      color = AppColors.badgeGreen;
      icon = Icons.check_circle_outline;
      texto = 'Sin faltante';
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compacto ? 8 : 11,
        vertical: compacto ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compacto ? 13 : 15, color: color),
          SizedBox(width: compacto ? 4 : 6),
          Text(
            texto,
            style: AppTextStyles.label.copyWith(
              fontSize: compacto ? 11.5 : 12.5,
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
