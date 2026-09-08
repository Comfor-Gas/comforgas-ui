import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

class DiscrepanciaIndicator extends StatelessWidget {
  final bool sinContrato;
  final int faltanteTotal;
  final int sobranteTotal;

  const DiscrepanciaIndicator({
    super.key,
    required this.faltanteTotal,
    this.sobranteTotal = 0,
    this.sinContrato = false,
  });

  @override
  Widget build(BuildContext context) {
    if (sinContrato) {
      return _Banner(
        color: AppColors.badgeGray,
        icon: Icons.help_outline,
        titulo: 'Sin contrato de referencia',
        detalle: 'No se pudo cargar el contrato de comodato del cliente.',
      );
    }

    if (faltanteTotal > 0) {
      final unidad = faltanteTotal == 1 ? 'cilindro' : 'cilindros';
      return _Banner(
        color: AppColors.badgeRed,
        icon: Icons.warning_amber_rounded,
        titulo: 'Discrepancia detectada: -$faltanteTotal $unidad',
        detalle: 'Faltante respecto al contrato original.',
      );
    }

    if (sobranteTotal > 0) {
      final unidad = sobranteTotal == 1 ? 'cilindro' : 'cilindros';
      return _Banner(
        color: AppColors.badgeAmber,
        icon: Icons.info_outline,
        titulo: 'Sobrante detectado: +$sobranteTotal $unidad',
        detalle: 'Hay más envases que los contratados en sistema.',
      );
    }

    return _Banner(
      color: AppColors.badgeGreen,
      icon: Icons.check_circle_outline,
      titulo: 'Sin discrepancias',
      detalle: 'El conteo físico coincide con el contrato registrado.',
    );
  }
}

class _Banner extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String titulo;
  final String detalle;

  const _Banner({
    required this.color,
    required this.icon,
    required this.titulo,
    required this.detalle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: AppTextStyles.label.copyWith(color: color, fontSize: 13.5),
                ),
                const SizedBox(height: 2),
                Text(
                  detalle,
                  style: AppTextStyles.footer.copyWith(color: AppColors.graphiteGray),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
