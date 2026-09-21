import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../utils/formato.dart';

class VentaTotalBar extends StatelessWidget {
  final int total;
  final int cantidadItems;
  final bool habilitado;
  final bool cargando;
  final bool hayInconsistencias;
  final String textoBoton;
  final VoidCallback onGuardar;

  const VentaTotalBar({
    super.key,
    required this.total,
    required this.cantidadItems,
    required this.habilitado,
    required this.cargando,
    required this.hayInconsistencias,
    required this.textoBoton,
    required this.onGuardar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hayInconsistencias) ...[
              _AvisoInconsistencia(),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total de la venta', style: AppTextStyles.footer),
                    const SizedBox(height: 2),
                    Text(
                      formatMoneda(total),
                      style: AppTextStyles.title.copyWith(fontSize: 24),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  cantidadItems == 1 ? '1 producto' : '$cantidadItems productos',
                  style: AppTextStyles.link.copyWith(fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (habilitado && !cargando) ? onGuardar : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  disabledBackgroundColor: AppColors.inputBorder,
                  foregroundColor: Colors.white,
                  disabledForegroundColor: AppColors.inputHint,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: AppTextStyles.button,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: cargando
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          valueColor: AlwaysStoppedAnimation(AppColors.white),
                        ),
                      )
                    : Text(textoBoton),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvisoInconsistencia extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.badgeAmber.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.badgeAmber.withOpacity(0.45)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.badgeAmber, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Hay productos con cantidades inconsistentes. Se registran igual, marcados para revisión del administrador.',
              style: AppTextStyles.footer.copyWith(fontSize: 13, color: AppColors.graphiteGray),
            ),
          ),
        ],
      ),
    );
  }
}
