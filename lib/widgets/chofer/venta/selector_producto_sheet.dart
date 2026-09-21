import 'package:flutter/material.dart';
import '../../../models/producto_sku.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../utils/formato.dart';

Future<ProductoSku?> mostrarSelectorProducto(
  BuildContext context, {
  required List<ProductoSku> productos,
  required String titulo,
}) {
  return showModalBottomSheet<ProductoSku>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _SelectorProductoSheet(productos: productos, titulo: titulo),
  );
}

class _SelectorProductoSheet extends StatelessWidget {
  final List<ProductoSku> productos;
  final String titulo;

  const _SelectorProductoSheet({required this.productos, required this.titulo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.inputBorder,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 18),
            Text(titulo, style: AppTextStyles.title.copyWith(fontSize: 18)),
            const SizedBox(height: 18),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final p in productos) _FilaProducto(producto: p),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.graphiteGray,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  'Cancelar',
                  style: AppTextStyles.label.copyWith(color: AppColors.graphiteGray),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilaProducto extends StatelessWidget {
  final ProductoSku producto;

  const _FilaProducto({required this.producto});

  @override
  Widget build(BuildContext context) {
    final nombre = producto.descripcion.isNotEmpty
        ? producto.descripcion
        : (producto.kg > 0 ? 'Garrafa ${producto.kg} kg' : producto.sku);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => Navigator.of(context).pop(producto),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.inputBorder, width: 1.4),
          ),
          child: Row(
            children: [
              const Icon(Icons.propane_tank_rounded, size: 20, color: AppColors.steelBlue),
              const SizedBox(width: 14),
              Expanded(
                child: Text(nombre, style: AppTextStyles.label.copyWith(fontSize: 15)),
              ),
              Text(
                formatMoneda(producto.precioUnitario),
                style: AppTextStyles.footer.copyWith(color: AppColors.graphiteGray),
              ),
              if (producto.stockDisponible != null) ...[
                const SizedBox(width: 8),
                Text(
                  'Stock ${producto.stockDisponible}',
                  style: AppTextStyles.footer.copyWith(color: AppColors.badgeGreen),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
