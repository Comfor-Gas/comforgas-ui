import 'package:flutter/material.dart';
import '../../../models/canje_garrafa.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

class CanjeGarrafaCard extends StatelessWidget {
  final List<CanjeGarrafaDraft> canjes;
  final bool pendienteSync;
  final VoidCallback? onCanjear;

  const CanjeGarrafaCard({
    super.key,
    required this.canjes,
    required this.pendienteSync,
    required this.onCanjear,
  });

  bool get _hayCanjes => canjes.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _hayCanjes ? AppColors.badgeGreen.withOpacity(0.5) : AppColors.inputBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.sync_problem_outlined, size: 20, color: AppColors.orange),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Canje de Garrafas Dañadas',
                  style: AppTextStyles.label.copyWith(fontSize: 15),
                ),
              ),
              if (_hayCanjes) _buildContador(),
            ],
          ),
          if (_hayCanjes) ...[
            const SizedBox(height: 12),
            _buildResumen(),
          ],
          const SizedBox(height: 14),
          _buildBoton(),
        ],
      ),
    );
  }

  Widget _buildContador() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.badgeGreen.withOpacity(0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        canjes.length == 1 ? '1 canje' : '${canjes.length} canjes',
        style: AppTextStyles.label.copyWith(
          fontSize: 12,
          color: AppColors.badgeGreen,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildResumen() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'GARRAFAS CANJEADAS EN ESTA PARADA',
            style: AppTextStyles.footer.copyWith(letterSpacing: 0.4),
          ),
          const SizedBox(height: 8),
          for (final c in canjes) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.propane_tank_rounded, size: 16, color: AppColors.orange),
                  const SizedBox(width: 6),
                  Text(
                    c.etiquetaSku,
                    style: AppTextStyles.label.copyWith(fontSize: 13.5),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      c.descripcionDanio,
                      style: AppTextStyles.input.copyWith(fontSize: 13, color: AppColors.graphiteGray),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (pendienteSync) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.orange.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.orange.withOpacity(0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.sync, size: 14, color: AppColors.orange),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Guardado local (Pendiente sincronización)',
                      style: AppTextStyles.footer.copyWith(
                        color: AppColors.orange,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 2),
            Text(
              'Sincronizado con el servidor.',
              style: AppTextStyles.footer.copyWith(color: AppColors.graphiteGray),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBoton() {
    return Material(
      color: AppColors.orange,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onCanjear,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.published_with_changes_outlined, size: 22, color: AppColors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _hayCanjes ? 'CANJEAR OTRA GARRAFA' : 'CANJEAR GARRAFA DAÑADA',
                      style: AppTextStyles.button.copyWith(fontSize: 13, letterSpacing: 0.4),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Reemplazo de envase dañado, sin cobranza',
                      style: AppTextStyles.footer.copyWith(
                        color: AppColors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.white, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
