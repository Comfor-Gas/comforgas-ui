import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class ComodatoBadge extends StatelessWidget {
  final int? total;
  final bool compacto;

  const ComodatoBadge({
    super.key,
    this.total,
    this.compacto = false,
  });

  @override
  Widget build(BuildContext context) {
    final mostrarTotal = total != null && total! > 0;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compacto ? 9 : 11,
        vertical: compacto ? 5 : 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.orange.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.orange.withOpacity(0.55), width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.propane_tank_rounded,
            size: compacto ? 13 : 15,
            color: AppColors.orange,
          ),
          SizedBox(width: compacto ? 5 : 6),
          Text(
            mostrarTotal ? 'Comodato' : 'Comodato Activo',
            style: TextStyle(
              fontSize: compacto ? 11 : 12,
              fontWeight: FontWeight.w800,
              color: AppColors.orange,
              letterSpacing: 0.2,
            ),
          ),
          if (mostrarTotal) ...[
            SizedBox(width: compacto ? 5 : 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.orange,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$total',
                style: TextStyle(
                  fontSize: compacto ? 10 : 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.white,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
