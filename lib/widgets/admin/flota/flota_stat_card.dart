import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

class FlotaStatCard extends StatelessWidget {
  final IconData icon;
  final String etiqueta;
  final String valor;
  final Color? acento;

  const FlotaStatCard({
    super.key,
    required this.icon,
    required this.etiqueta,
    required this.valor,
    this.acento,
  });

  @override
  Widget build(BuildContext context) {
    final color = acento ?? AppColors.steelBlue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  etiqueta,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.graphiteGray,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  valor,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.steelBlue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
