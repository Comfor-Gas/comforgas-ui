import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

class CamionStockBar extends StatelessWidget {
  final int llenos;
  final int vacios;
  final int cupo;
  final bool compacto;

  const CamionStockBar({
    super.key,
    required this.llenos,
    required this.vacios,
    required this.cupo,
    this.compacto = false,
  });

  @override
  Widget build(BuildContext context) {
    final progreso = cupo <= 0 ? 0.0 : (llenos / cupo).clamp(0.0, 1.0);
    final color = progreso >= 0.5
        ? AppColors.badgeGreen
        : (progreso >= 0.25 ? AppColors.badgeAmber : AppColors.error);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text(
              '$llenos/$cupo Llenos',
              style: TextStyle(
                fontSize: compacto ? 11.5 : 12.5,
                fontWeight: FontWeight.w800,
                color: AppColors.steelBlue,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$vacios Vacíos',
              style: TextStyle(
                fontSize: compacto ? 11 : 12,
                fontWeight: FontWeight.w600,
                color: AppColors.graphiteGray,
              ),
            ),
          ],
        ),
        SizedBox(height: compacto ? 5 : 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Stack(
            children: [
              Container(
                height: compacto ? 7 : 9,
                decoration: BoxDecoration(
                  color: AppColors.inputBorder.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progreso == 0 ? 0.02 : progreso,
                child: Container(
                  height: compacto ? 7 : 9,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
