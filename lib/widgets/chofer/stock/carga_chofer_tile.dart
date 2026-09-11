import 'package:flutter/material.dart';
import '../../../models/carga_chofer.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../utils/date_format_utils.dart';

class CargaChoferTile extends StatelessWidget {
  final CargaChofer carga;

  const CargaChoferTile({super.key, required this.carga});

  @override
  Widget build(BuildContext context) {
    final fecha = carga.fecha;
    final fechaTexto = fecha != null
        ? '${formatFechaCorta(fecha)} · ${formatHora12(fecha)}'
        : 'Sin fecha';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(fechaTexto, style: AppTextStyles.footer.copyWith(color: AppColors.graphiteGray)),
              ),
              Text(
                '+${carga.total}',
                style: AppTextStyles.label.copyWith(fontSize: 15, color: AppColors.orange),
              ),
            ],
          ),
          if (carga.folio != null && carga.folio!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text('Folio ${carga.folio}', style: AppTextStyles.footer.copyWith(color: AppColors.graphiteGray)),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final l in carga.lineas)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.inputBorder),
                  ),
                  child: Text(
                    '${l.etiqueta}: ${l.cantidad}',
                    style: AppTextStyles.label.copyWith(fontSize: 12.5, color: AppColors.steelBlue),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
