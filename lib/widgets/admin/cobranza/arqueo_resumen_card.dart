import 'package:flutter/material.dart';

import '../../../models/arqueo_caja.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../utils/formato.dart';
import '../flota/flota_form_controls.dart';
import 'arqueo_tabla.dart';

class ArqueoResumenCard extends StatelessWidget {
  final List<ArqueoMetodoTotal> totales;
  final int totalGeneral;
  final bool cerrado;
  final bool cerrando;
  final VoidCallback onCerrar;

  const ArqueoResumenCard({
    super.key,
    required this.totales,
    required this.totalGeneral,
    required this.onCerrar,
    this.cerrado = false,
    this.cerrando = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Resumen del Día', style: AppTextStyles.label.copyWith(fontSize: 15)),
          const SizedBox(height: 14),
          for (final t in totales) ...[
            _LineaMetodo(etiqueta: etiquetaMetodo(t.metodoPago), valor: t.total),
            const SizedBox(height: 10),
          ],
          const Divider(height: 20, color: AppColors.inputBorder),
          Row(
            children: [
              Expanded(
                child: Text('Total General', style: AppTextStyles.label.copyWith(fontSize: 15)),
              ),
              Text(
                formatMoneda(totalGeneral),
                style: AppTextStyles.title.copyWith(fontSize: 20, color: AppColors.orange),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (cerrado)
            const _ArqueoCerradoAviso()
          else
            FlotaBotonPrimario(
              texto: 'Cerrar Arqueo Auditado',
              icono: Icons.verified_outlined,
              cargando: cerrando,
              onTap: cerrando ? null : onCerrar,
            ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.receipt_long_outlined, size: 15, color: AppColors.graphiteGray),
              const SizedBox(width: 6),
            ],
          ),
        ],
      ),
    );
  }
}

class _LineaMetodo extends StatelessWidget {
  final String etiqueta;
  final int valor;

  const _LineaMetodo({required this.etiqueta, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text('Total $etiqueta', style: AppTextStyles.link.copyWith(fontSize: 13.5)),
        ),
        Text(
          formatMoneda(valor),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.steelBlue),
        ),
      ],
    );
  }
}

class _ArqueoCerradoAviso extends StatelessWidget {
  const _ArqueoCerradoAviso();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.badgeGreen.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.badgeGreen.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, size: 18, color: AppColors.badgeGreen),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Arqueo cerrado y auditado.',
              style: AppTextStyles.link.copyWith(fontSize: 12.5, color: AppColors.graphiteGray),
            ),
          ),
        ],
      ),
    );
  }
}
