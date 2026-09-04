import 'package:flutter/material.dart';
import '../../../models/producto_sku.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../utils/formato.dart';

class SkuCatalogoCard extends StatelessWidget {
  final ProductoSku producto;
  final bool agregado;
  final VoidCallback onTap;

  const SkuCatalogoCard({
    super.key,
    required this.producto,
    required this.agregado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: agregado ? AppColors.orange : AppColors.inputBorder,
          width: agregado ? 1.6 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
              child: Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.orange.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.propane_tank_outlined,
                  color: AppColors.orange,
                  size: 24,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      producto.descripcion,
                      style: AppTextStyles.label.copyWith(fontSize: 15),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${formatMoneda(producto.precioUnitario)} c/u',
                      style: AppTextStyles.link.copyWith(fontSize: 13),
                    ),
                    if (producto.stockDisponible != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.inventory_2_outlined,
                            size: 13,
                            color: AppColors.steelBlue,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Disponibles en el camión: ${producto.stockDisponible}',
                            style: AppTextStyles.footer.copyWith(
                              color: AppColors.steelBlue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (agregado) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            size: 14,
                            color: AppColors.orange,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Agregado al detalle',
                            style: AppTextStyles.footer.copyWith(
                              color: AppColors.orange,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            InkWell(
              onTap: onTap,
              borderRadius: const BorderRadius.horizontal(
                right: Radius.circular(16),
              ),
              child: Container(
                width: 52,
                decoration: const BoxDecoration(
                  color: AppColors.orange,
                  borderRadius: BorderRadius.horizontal(
                    right: Radius.circular(16),
                  ),
                ),
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
