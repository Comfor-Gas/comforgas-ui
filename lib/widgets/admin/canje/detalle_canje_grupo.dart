import 'package:flutter/material.dart';
import '../../../models/canje_reporte.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import 'badge_cantidad_canje.dart';

class DetalleCanjeGrupo extends StatelessWidget {
  final CanjeReporteGrupo grupo;
  final bool compacto;

  const DetalleCanjeGrupo({super.key, required this.grupo, this.compacto = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.background,
      padding: compacto
          ? const EdgeInsets.fromLTRB(12, 12, 12, 12)
          : const EdgeInsets.fromLTRB(20, 12, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DETALLE POR PRODUCTO Y MOTIVO DE DAÑO',
            style: AppTextStyles.footer.copyWith(
              letterSpacing: 0.5,
              fontWeight: FontWeight.w700,
              color: AppColors.graphiteGray,
            ),
          ),
          const SizedBox(height: 10),
          for (final d in grupo.detalles)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.inputBorder),
              ),
              child: compacto ? _itemCompacto(d) : _itemFila(d),
            ),
        ],
      ),
    );
  }

  String _danio(CanjeReporte d) =>
      d.descripcionDanio.trim().isEmpty ? 'Sin descripción' : d.descripcionDanio.trim();

  Widget _producto(CanjeReporte d) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(d.etiquetaProducto, style: AppTextStyles.label.copyWith(fontSize: 13.5)),
        if (d.sku.trim().isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            d.sku,
            style: AppTextStyles.footer.copyWith(color: AppColors.graphiteGray),
          ),
        ],
      ],
    );
  }

  Widget _itemFila(CanjeReporte d) {
    return Row(
      children: [
        const Icon(Icons.propane_tank_rounded, size: 18, color: AppColors.orange),
        const SizedBox(width: 10),
        Expanded(flex: 4, child: _producto(d)),
        Expanded(
          flex: 5,
          child: Text(
            _danio(d),
            style: AppTextStyles.input.copyWith(fontSize: 13, color: AppColors.graphiteGray),
          ),
        ),
        BadgeCantidadCanje(cantidad: d.cantidad, compacto: true),
      ],
    );
  }

  Widget _itemCompacto(CanjeReporte d) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 1),
              child: Icon(Icons.propane_tank_rounded, size: 18, color: AppColors.orange),
            ),
            const SizedBox(width: 8),
            Expanded(child: _producto(d)),
            const SizedBox(width: 8),
            BadgeCantidadCanje(cantidad: d.cantidad, compacto: true),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          _danio(d),
          style: AppTextStyles.input.copyWith(fontSize: 13, color: AppColors.graphiteGray),
        ),
      ],
    );
  }
}
