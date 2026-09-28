import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

class DashboardPaleta {
  DashboardPaleta._();

  static const Color serieNaranja = Color(0xFFE8671A);
  static const Color serieAzul = Color(0xFF3A7BD5);
  static const Color grilla = Color(0xFFE6EAEF);
  static const Color eje = AppColors.graphiteGray;
  static const Color tooltipFondo = Color(0xFF2E3F52);
  static const Color superficie = AppColors.white;

  static const TextStyle ejeTexto = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.graphiteGray,
  );

  static const TextStyle tooltipValor = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w800,
    color: Colors.white,
  );

  static const TextStyle tooltipEtiqueta = TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.w500,
    color: Color(0xFFD5DCE4),
  );
}
