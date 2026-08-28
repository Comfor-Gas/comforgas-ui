import 'package:flutter/material.dart';
import '../../../models/metodo_pago.dart';
import '../../../theme/app_colors.dart';

class MetodoPagoSelector extends StatelessWidget {
  final MetodoPago seleccionado;
  final ValueChanged<MetodoPago> onChanged;

  const MetodoPagoSelector({
    super.key,
    required this.seleccionado,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final metodo in MetodoPago.values)
          _MetodoChip(
            metodo: metodo,
            activo: metodo == seleccionado,
            onTap: () => onChanged(metodo),
          ),
      ],
    );
  }
}

class _MetodoChip extends StatelessWidget {
  final MetodoPago metodo;
  final bool activo;
  final VoidCallback onTap;

  const _MetodoChip({
    required this.metodo,
    required this.activo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = activo ? AppColors.orange : AppColors.inputBorder;
    final contenido = activo ? AppColors.orange : AppColors.graphiteGray;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: activo ? AppColors.orange.withOpacity(0.08) : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: activo ? 1.6 : 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(metodo.icono, size: 18, color: contenido),
            const SizedBox(width: 8),
            Text(
              metodo.etiqueta,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: activo ? AppColors.steelBlue : AppColors.graphiteGray,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
