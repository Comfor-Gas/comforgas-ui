import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

class BadgeCantidadCanje extends StatelessWidget {
  final int cantidad;
  final bool compacto;

  const BadgeCantidadCanje({super.key, required this.cantidad, this.compacto = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compacto ? 9 : 11, vertical: compacto ? 4 : 6),
      decoration: BoxDecoration(
        color: AppColors.orange.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.orange.withOpacity(0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.assignment_return_outlined, size: compacto ? 13 : 15, color: AppColors.orange),
          SizedBox(width: compacto ? 5 : 6),
          Text(
            '$cantidad',
            style: TextStyle(
              fontSize: compacto ? 12 : 13.5,
              fontWeight: FontWeight.w800,
              color: AppColors.orange,
            ),
          ),
        ],
      ),
    );
  }
}
