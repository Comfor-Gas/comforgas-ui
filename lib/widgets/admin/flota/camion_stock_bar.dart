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
    this.cupo = 0,
    this.compacto = false,
  });

  @override
  Widget build(BuildContext context) {
    final hayReferencia = cupo > 0;
    final progreso = hayReferencia ? (llenos / cupo).clamp(0.0, 1.0) : 0.0;
    final colorBarra = progreso >= 0.5
        ? AppColors.badgeGreen
        : (progreso >= 0.25 ? AppColors.badgeAmber : AppColors.error);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text(
              hayReferencia ? '$llenos/$cupo Llenos' : '$llenos Llenos',
              style: TextStyle(
                fontSize: compacto ? 12.5 : 13.5,
                fontWeight: FontWeight.w800,
                color: AppColors.orange,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '$vacios Vacíos',
              style: TextStyle(
                fontSize: compacto ? 11.5 : 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.graphiteGray,
              ),
            ),
          ],
        ),
        if (hayReferencia) ...[
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
                      color: colorBarra,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
