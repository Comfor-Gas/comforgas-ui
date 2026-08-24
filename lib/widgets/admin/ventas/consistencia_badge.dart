import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

class ConsistenciaBadge extends StatelessWidget {
  final bool consistente;

  const ConsistenciaBadge({super.key, required this.consistente});

  @override
  Widget build(BuildContext context) {
    final color = consistente ? AppColors.badgeGreen : AppColors.badgeRed;
    final texto = consistente ? 'CONSISTENTE' : 'INCONSISTENTE';
    final icono = consistente ? Icons.check_circle : Icons.error_outline;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.35), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            texto,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
