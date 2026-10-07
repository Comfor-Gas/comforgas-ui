import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

const TextStyle estiloTextoFiltro = TextStyle(
  fontSize: 13.5,
  fontWeight: FontWeight.w400,
  color: AppColors.steelBlue,
);

InputDecoration decoracionFiltro({
  required String etiqueta,
  required IconData icono,
  required bool activo,
  String hint = 'Todos',
  Widget? sufijo,
}) {
  OutlineInputBorder borde(Color color, [double ancho = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: color, width: ancho),
      );

  return InputDecoration(
    isDense: true,
    labelText: etiqueta,
    hintText: hint,
    floatingLabelBehavior: FloatingLabelBehavior.always,
    labelStyle: TextStyle(
      fontSize: 13,
      color: activo ? AppColors.orange : AppColors.graphiteGray,
      fontWeight: FontWeight.w600,
    ),
    hintStyle: AppTextStyles.hint.copyWith(fontSize: 13.5),
    prefixIcon: Icon(icono, size: 18, color: activo ? AppColors.orange : AppColors.inputHint),
    suffixIcon: sufijo,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    filled: true,
    fillColor: activo ? AppColors.orange.withValues(alpha: 0.06) : AppColors.background,
    border: borde(AppColors.inputBorder),
    enabledBorder: borde(activo ? AppColors.orange.withValues(alpha: 0.5) : AppColors.inputBorder),
    disabledBorder: borde(AppColors.inputBorder),
    focusedBorder: borde(AppColors.orange, 1.4),
  );
}
