import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

class StockAvisoBanner extends StatelessWidget {
  final String mensaje;
  final IconData icono;

  const StockAvisoBanner({
    super.key,
    required this.mensaje,
    this.icono = Icons.info_outline,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.badgeAmber.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.badgeAmber.withOpacity(0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 16, color: AppColors.badgeAmber),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              mensaje,
              style: const TextStyle(fontSize: 12, color: AppColors.graphiteGray),
            ),
          ),
        ],
      ),
    );
  }
}
