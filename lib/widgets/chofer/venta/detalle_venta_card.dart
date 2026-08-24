import 'package:flutter/material.dart';
import '../../../models/detalle_venta_draft.dart';
import '../../../models/tipo_operacion_venta.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../utils/formato.dart';

class DetalleVentaCard extends StatelessWidget {
  final DetalleVentaDraft detalle;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  const DetalleVentaCard({
    super.key,
    required this.detalle,
    required this.onEditar,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    final info = detalle.tipoOperacion.info;
    final valido = detalle.esValido;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: valido ? AppColors.inputBorder : AppColors.error,
          width: valido ? 1 : 1.4,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      detalle.producto.descripcion,
                      style: AppTextStyles.label.copyWith(fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(info.icono, size: 14, color: detalle.tipoOperacion.color),
                        const SizedBox(width: 5),
                        Text(
                          info.label,
                          style: AppTextStyles.footer.copyWith(
                            color: detalle.tipoOperacion.color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _IconAction(icono: Icons.edit_outlined, color: AppColors.steelBlue, onTap: onEditar),
              const SizedBox(width: 4),
              _IconAction(icono: Icons.delete_outline, color: AppColors.error, onTap: onEliminar),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _Chip(
                label: 'Entregados',
                valor: '${detalle.cantidadEntregada}',
                color: AppColors.orange,
              ),
              if (detalle.tipoOperacion.usaRecibidos) ...[
                const SizedBox(width: 8),
                _Chip(
                  label: 'Recibidos',
                  valor: '${detalle.cantidadRecibida}',
                  color: AppColors.steelBlue,
                ),
              ],
              const Spacer(),
              Text(
                formatMoneda(detalle.subtotal),
                style: AppTextStyles.title.copyWith(fontSize: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final String valor;
  final Color color;

  const _Chip({required this.label, required this.valor, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$label: $valor',
        style: AppTextStyles.footer.copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  final IconData icono;
  final Color color;
  final VoidCallback onTap;

  const _IconAction({required this.icono, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icono, size: 20, color: color),
      ),
    );
  }
}
