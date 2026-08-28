import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

class CreditoEstadoBadge extends StatelessWidget {
  final bool moroso;

  const CreditoEstadoBadge({super.key, required this.moroso});

  @override
  Widget build(BuildContext context) {
    final color = moroso ? AppColors.error : AppColors.badgeGreen;
    final texto = moroso ? 'Moroso' : 'Al día';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}
