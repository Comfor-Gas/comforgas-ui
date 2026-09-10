import 'package:flutter/material.dart';
import '../../../models/producto_sku.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

class SelectorSkuCanje extends StatelessWidget {
  final List<ProductoSku> productos;
  final String? seleccionadoId;
  final ValueChanged<ProductoSku> onSeleccionar;
  final bool enabled;

  const SelectorSkuCanje({
    super.key,
    required this.productos,
    required this.seleccionadoId,
    required this.onSeleccionar,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (productos.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.inputBorder, width: 1.2),
        ),
        child: Text(
          'No hay garrafas llenas disponibles en el camión para canjear.',
          style: AppTextStyles.input.copyWith(color: AppColors.graphiteGray),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final p in productos)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _TileProducto(
              producto: p,
              activo: seleccionadoId == p.idProducto,
              onTap: enabled ? () => onSeleccionar(p) : null,
            ),
          ),
      ],
    );
  }
}

class _TileProducto extends StatelessWidget {
  final ProductoSku producto;
  final bool activo;
  final VoidCallback? onTap;

  const _TileProducto({required this.producto, required this.activo, this.onTap});

  @override
  Widget build(BuildContext context) {
    final Color borde = activo ? AppColors.orange : AppColors.inputBorder;
    final Color fondo = activo ? AppColors.orange.withOpacity(0.08) : AppColors.white;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: fondo,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borde, width: activo ? 1.6 : 1.2),
        ),
        child: Row(
          children: [
            Icon(
              Icons.propane_tank_rounded,
              size: 22,
              color: activo ? AppColors.orange : AppColors.steelBlue,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    producto.descripcion,
                    style: AppTextStyles.label.copyWith(fontSize: 14.5),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Disponible en camión: ${producto.stockDisponible ?? 0}',
                    style: AppTextStyles.footer.copyWith(color: AppColors.graphiteGray),
                  ),
                ],
              ),
            ),
            Icon(
              activo ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              size: 22,
              color: activo ? AppColors.orange : AppColors.inputBorder,
            ),
          ],
        ),
      ),
    );
  }
}
