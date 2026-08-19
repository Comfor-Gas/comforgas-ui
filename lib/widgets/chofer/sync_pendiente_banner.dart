import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// Banner compacto que avisa cuántos eventos (check-in/check-out/fotos)
/// quedaron guardados localmente por falta de conexión, con un botón para
/// forzar un reintento manual de sincronización.
class SyncPendienteBanner extends StatelessWidget {
  final int cantidadPendiente;
  final bool sincronizando;
  final VoidCallback onReintentar;
  final VoidCallback? onDescartar;

  const SyncPendienteBanner({
    super.key,
    required this.cantidadPendiente,
    required this.sincronizando,
    required this.onReintentar,
    this.onDescartar,
  });

  @override
  Widget build(BuildContext context) {
    if (cantidadPendiente == 0 && !sincronizando) {
      return const SizedBox.shrink();
    }

    final texto = sincronizando
        ? 'Sincronizando cambios guardados...'
        : cantidadPendiente == 1
            ? '1 cambio guardado sin conexión, pendiente de enviar'
            : '$cantidadPendiente cambios guardados sin conexión, pendientes de enviar';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.badgeAmber.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.badgeAmber.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          if (sincronizando)
            const SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.badgeAmber),
            )
          else
            const Icon(Icons.cloud_off_outlined, size: 18, color: AppColors.badgeAmber),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texto,
              style: AppTextStyles.link.copyWith(fontSize: 12.5, color: AppColors.graphiteGray),
            ),
          ),
          if (!sincronizando) ...[
            TextButton(
              onPressed: onReintentar,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Reintentar',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.orange,
                ),
              ),
            ),
            if (onDescartar != null)
              TextButton(
                onPressed: onDescartar,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Descartar',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.graphiteGray,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
