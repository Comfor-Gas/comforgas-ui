import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

class DesgloseTipoItem {
  final String etiqueta;
  final int cantidad;

  const DesgloseTipoItem({required this.etiqueta, required this.cantidad});
}

class DesgloseTipoCard extends StatelessWidget {
  final List<DesgloseTipoItem> items;
  final int total;
  final String mensajeVacio;

  const DesgloseTipoCard({
    super.key,
    required this.items,
    required this.total,
    required this.mensajeVacio,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: items.isEmpty
          ? Text(
              mensajeVacio,
              style: AppTextStyles.footer.copyWith(color: AppColors.graphiteGray),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final it in items)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.inputBorder),
                        ),
                        child: Text(
                          '${it.etiqueta}: ${it.cantidad}',
                          style: AppTextStyles.label.copyWith(fontSize: 12.5, color: AppColors.steelBlue),
                        ),
                      ),
                  ],
                ),
                const Divider(height: 18, color: AppColors.inputBorder),
                Row(
                  children: [
                    Expanded(
                      child: Text('Total', style: AppTextStyles.label.copyWith(fontSize: 13.5)),
                    ),
                    Text(
                      '$total',
                      style: AppTextStyles.label.copyWith(fontSize: 16, color: AppColors.orange),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
