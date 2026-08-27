import 'package:flutter/material.dart';

import '../../../models/deposito_camion.dart';
import '../../../theme/app_colors.dart';

class EstadoCamionBadge extends StatelessWidget {
  final EstadoCamion estado;

  const EstadoCamionBadge({super.key, required this.estado});

  @override
  Widget build(BuildContext context) {
    final (texto, color) = switch (estado) {
      EstadoCamion.enRuta => ('EN RUTA', AppColors.badgeGreen),
      EstadoCamion.enEspera => ('EN ESPERA', AppColors.badgeAmber),
      EstadoCamion.enDeposito => ('EN DEPÓSITO', AppColors.badgeBlue),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
          color: color,
        ),
      ),
    );
  }
}
