import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

class FilaComparativaMovil extends StatelessWidget {
  final String concepto;
  final String sistema;
  final String declarado;
  final Widget diferencia;
  final String etiquetaSistema;
  final String etiquetaDeclarado;
  final bool destacado;
  final EdgeInsetsGeometry padding;

  const FilaComparativaMovil({
    super.key,
    required this.concepto,
    required this.sistema,
    required this.declarado,
    required this.diferencia,
    this.etiquetaSistema = 'Sistema',
    this.etiquetaDeclarado = 'Declarado',
    this.destacado = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  concepto,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.label.copyWith(fontSize: destacado ? 13.5 : 13),
                ),
              ),
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 150),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: diferencia,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _DatoComparativo(
                  etiqueta: etiquetaSistema,
                  valor: sistema,
                  color: AppColors.graphiteGray,
                  peso: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DatoComparativo(
                  etiqueta: etiquetaDeclarado,
                  valor: declarado,
                  color: AppColors.steelBlue,
                  peso: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DatoComparativo extends StatelessWidget {
  final String etiqueta;
  final String valor;
  final Color color;
  final FontWeight peso;

  const _DatoComparativo({
    required this.etiqueta,
    required this.valor,
    required this.color,
    required this.peso,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          etiqueta.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
            color: AppColors.graphiteGray,
          ),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            valor,
            maxLines: 1,
            style: TextStyle(fontSize: 13, fontWeight: peso, color: color),
          ),
        ),
      ],
    );
  }
}
