import 'package:flutter/material.dart';
import '../../../models/venta_monitoreo.dart';
import '../../../theme/app_colors.dart';

class VentaEstadoBadge extends StatelessWidget {
  final EstadoVentaMonitoreo estado;

  const VentaEstadoBadge({super.key, required this.estado});

  @override
  Widget build(BuildContext context) {
    final color = colorPara(estado);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        estado.label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  static Color colorPara(EstadoVentaMonitoreo estado) {
    switch (estado) {
      case EstadoVentaMonitoreo.efectuada:
        return AppColors.badgeGreen;
      case EstadoVentaMonitoreo.pendiente:
        return AppColors.badgeAmber;
      case EstadoVentaMonitoreo.cancelada:
        return AppColors.badgeRed;
      case EstadoVentaMonitoreo.desconocido:
        return AppColors.badgeGray;
    }
  }
}
