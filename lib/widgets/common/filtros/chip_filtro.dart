import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

class ChipFiltro extends StatelessWidget {
  final String etiqueta;
  final bool activo;
  final IconData? icono;
  final VoidCallback? onTap;

  const ChipFiltro({
    super.key,
    required this.etiqueta,
    required this.activo,
    required this.onTap,
    this.icono,
  });

  @override
  Widget build(BuildContext context) {
    final color = activo ? AppColors.orange : AppColors.steelBlue;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: activo ? AppColors.orange.withOpacity(0.1) : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: activo ? AppColors.orange.withOpacity(0.6) : AppColors.inputBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (activo && icono == null) ...[
              const Icon(Icons.check, size: 15, color: AppColors.orange),
              const SizedBox(width: 5),
            ],
            if (icono != null) ...[
              Icon(icono, size: 15, color: color),
              const SizedBox(width: 6),
            ],
            Text(
              etiqueta,
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
