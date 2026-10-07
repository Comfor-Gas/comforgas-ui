import 'package:flutter/material.dart';
import '../../../models/venta_draft.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

class ResumenSocialBar extends StatelessWidget {
  final VentaDraft venta;

  const ResumenSocialBar({super.key, required this.venta});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.steelBlue.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.steelBlue.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.volunteer_activism_outlined, size: 18, color: AppColors.steelBlue),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Venta Social: ${venta.totalGarrafasSociales} '
                '${venta.totalGarrafasSociales == 1 ? 'garrafa' : 'garrafas'} a dejar en el punto. '
                'La visita queda pausada y se liquida al volver.',
                style: AppTextStyles.footer.copyWith(color: AppColors.graphiteGray),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
