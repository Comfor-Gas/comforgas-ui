import 'package:flutter/material.dart';
import '../../../models/tipo_operacion_venta.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

Future<TipoOperacionVenta?> mostrarTipoOperacionSheet(BuildContext context) {
  return showModalBottomSheet<TipoOperacionVenta>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => const _TipoOperacionSheet(),
  );
}

class _TipoOperacionSheet extends StatelessWidget {
  const _TipoOperacionSheet();

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
            Text(
              'Seleccionar Tipo de Operación',
              style: AppTextStyles.title.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 18),
            _OpcionOperacion(
              tipo: TipoOperacionVenta.vacioXLleno,
              destacado: true,
              onTap: () =>
                  Navigator.of(context).pop(TipoOperacionVenta.vacioXLleno),
            ),
            const SizedBox(height: 12),
            _OpcionOperacion(
              tipo: TipoOperacionVenta.prestamo,
              onTap: () =>
                  Navigator.of(context).pop(TipoOperacionVenta.prestamo),
            ),
            const SizedBox(height: 12),
            _OpcionOperacion(
              tipo: TipoOperacionVenta.envaseSolo,
              onTap: () =>
                  Navigator.of(context).pop(TipoOperacionVenta.envaseSolo),
            ),
            const SizedBox(height: 12),
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
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.graphiteGray,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OpcionOperacion extends StatelessWidget {
  final TipoOperacionVenta tipo;
  final bool destacado;
  final VoidCallback onTap;

  const _OpcionOperacion({
    required this.tipo,
    required this.onTap,
    this.destacado = false,
  });

  @override
  Widget build(BuildContext context) {
    final info = tipo.info;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: destacado ? AppColors.orange : AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: destacado ? AppColors.orange : AppColors.inputBorder,
            width: 1.4,
          ),
        ),
        child: Row(
          children: [
            Icon(
              info.icono,
              color: destacado ? AppColors.white : AppColors.steelBlue,
              size: 22,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    info.label,
                    style: AppTextStyles.label.copyWith(
                      fontSize: 15,
                      color: destacado ? AppColors.white : AppColors.steelBlue,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    info.descripcion,
                    style: AppTextStyles.footer.copyWith(
                      color: destacado
                          ? AppColors.white.withOpacity(0.9)
                          : AppColors.graphiteGray,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
