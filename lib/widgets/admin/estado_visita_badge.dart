import 'package:flutter/material.dart';
import '../../models/visita_estado.dart';
import '../../theme/app_colors.dart';

class EstadoVisitaBadge extends StatelessWidget {
  final VisitaEstado estado;
  final bool esBorrador;

  const EstadoVisitaBadge({
    super.key,
    required this.estado,
    this.esBorrador = false,
  });

  @override
  Widget build(BuildContext context) {
    final data = _dataFor(estado, esBorrador);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: data.$1.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        data.$2,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: data.$1,
        ),
      ),
    );
  }

  (Color, String) _dataFor(VisitaEstado estado, bool esBorrador) {
    if (esBorrador) return (AppColors.badgeGray, 'Borrador');
    switch (estado) {
      case VisitaEstado.pendiente:
        return (AppColors.badgeBlue, 'Asignado');
      case VisitaEstado.enCurso:
        return (AppColors.badgeAmber, 'En curso');
      case VisitaEstado.visitado:
        return (AppColors.badgeGreen, 'Visitado');
      case VisitaEstado.completada:
        return (AppColors.badgeGreen, 'Completada');
      case VisitaEstado.cancelada:
        return (AppColors.badgeRed, 'Cancelada');
      case VisitaEstado.noAsistio:
        return (AppColors.badgeRed, 'No asistió');
      case VisitaEstado.inactivo:
        return (AppColors.badgeGray, 'Inactivo');
      case VisitaEstado.unknown:
        return (AppColors.badgeGray, 'Desconocido');
    }
  }
}
