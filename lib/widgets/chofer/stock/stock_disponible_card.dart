import 'package:flutter/material.dart';
import '../../../models/stock_rodante_chofer.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

class StockDisponibleCard extends StatelessWidget {
  final List<StockRodanteProducto> productos;

  const StockDisponibleCard({super.key, required this.productos});

  @override
  Widget build(BuildContext context) {
    final totalLlenos = productos.fold(0, (a, p) => a + p.disponiblesParaVenta);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.orange.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.local_shipping_outlined, size: 20, color: AppColors.orange),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Disponible para vender / canjear',
                  style: AppTextStyles.label.copyWith(fontSize: 15, color: AppColors.orange),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Garrafas llenas cargadas en tu camión en este momento.',
            style: AppTextStyles.footer.copyWith(color: AppColors.graphiteGray),
          ),
          const SizedBox(height: 14),
          if (productos.isEmpty)
            Text(
              'No hay stock cargado en tu camión.',
              style: AppTextStyles.input.copyWith(color: AppColors.graphiteGray),
            )
          else
            for (final p in productos) _fila(p),
          const SizedBox(height: 6),
          const Divider(height: 20, color: AppColors.inputBorder),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Total llenos disponibles',
                  style: AppTextStyles.label.copyWith(fontSize: 14),
                ),
              ),
              Text(
                '$totalLlenos',
                style: AppTextStyles.title.copyWith(fontSize: 22, color: AppColors.orange),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _fila(StockRodanteProducto p) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          const Icon(Icons.propane_tank_rounded, size: 20, color: AppColors.steelBlue),
          const SizedBox(width: 10),
          Expanded(
            child: Text(p.etiqueta, style: AppTextStyles.label.copyWith(fontSize: 14.5)),
          ),
          _Chip(valor: p.disponiblesParaVenta, etiqueta: 'llenos', color: AppColors.orange),
          const SizedBox(width: 8),
          _Chip(valor: p.vaciosEnCamion, etiqueta: 'vacíos', color: AppColors.steelBlue),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final int valor;
  final String etiqueta;
  final Color color;

  const _Chip({required this.valor, required this.etiqueta, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text('$valor', style: AppTextStyles.label.copyWith(fontSize: 15, color: color)),
          Text(
            etiqueta,
            style: AppTextStyles.footer.copyWith(color: color, fontSize: 10.5),
          ),
        ],
      ),
    );
  }
}
