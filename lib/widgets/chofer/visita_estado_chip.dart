import 'package:flutter/material.dart';
import '../../models/visita_estado.dart';
import '../../theme/app_colors.dart';

class VisitaEstadoChip extends StatelessWidget {
  final VisitaEstado estado;

  const VisitaEstadoChip({super.key, required this.estado});

  @override
  Widget build(BuildContext context) {
    final data = _dataFor(estado);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(data.$1, size: 14, color: data.$2),
        const SizedBox(width: 4),
        Text(
          data.$3,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: data.$2,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  (IconData, Color, String) _dataFor(VisitaEstado estado) {
    switch (estado) {
      case VisitaEstado.completada:
        return (Icons.check_circle, AppColors.badgeGreen, 'COMPLETADA');
      case VisitaEstado.visitado:
        return (Icons.check_circle, AppColors.badgeGreen, 'VISITADO');
      case VisitaEstado.enCurso:
        return (Icons.directions_walk, AppColors.badgeAmber, 'EN CURSO');
      case VisitaEstado.pendiente:
        return (Icons.person_pin_circle_outlined, AppColors.badgeBlue, 'PENDIENTE');
      case VisitaEstado.noAsistio:
        return (Icons.error, AppColors.badgeAmber, 'NO ASISTIÓ');
      case VisitaEstado.cancelada:
        return (Icons.cancel, AppColors.badgeRed, 'CANCELADA');
      case VisitaEstado.inactivo:
        return (Icons.block, AppColors.badgeGray, 'INACTIVA');
      case VisitaEstado.unknown:
        return (Icons.help_outline, AppColors.badgeGray, 'SIN ESTADO');
    }
  }
}
