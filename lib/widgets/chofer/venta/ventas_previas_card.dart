import 'package:flutter/material.dart';
import '../../../models/venta_previa_resumen.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../utils/formato.dart';

class VentasPreviasCard extends StatelessWidget {
  final List<VentaPreviaResumen> ventas;

  const VentasPreviasCard({super.key, required this.ventas});

  @override
  Widget build(BuildContext context) {
    final total = ventas.fold(0, (a, v) => a + v.monto);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.steelBlue.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.steelBlue.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long_outlined, size: 18, color: AppColors.steelBlue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  ventas.length == 1
                      ? 'Ya registraste 1 venta en esta visita'
                      : 'Ya registraste ${ventas.length} ventas en esta visita',
                  style: AppTextStyles.label.copyWith(fontSize: 13.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final v in ventas)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          v.etiqueta,
                          style: AppTextStyles.link.copyWith(fontSize: 13),
                        ),
                      ),
                      Text(
                        formatMoneda(v.monto),
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.steelBlue,
                        ),
                      ),
                    ],
                  ),
                  if (v.detalle != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.propane_tank_outlined, size: 13, color: AppColors.inputHint),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            v.detalle!,
                            style: AppTextStyles.footer.copyWith(
                              fontSize: 12,
                              color: AppColors.graphiteGray,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          const Divider(height: 8, color: AppColors.inputBorder),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Total ya registrado',
                  style: AppTextStyles.footer.copyWith(
                    color: AppColors.graphiteGray,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                formatMoneda(total),
                style: AppTextStyles.title.copyWith(fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Lo que cargues acá se suma como una venta nueva.',
            style: AppTextStyles.footer.copyWith(
              color: AppColors.graphiteGray,
              fontStyle: FontStyle.italic,
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }
}
