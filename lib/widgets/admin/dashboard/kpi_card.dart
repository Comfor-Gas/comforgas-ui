import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

class KpiCard extends StatelessWidget {
  final IconData icono;
  final Color acento;
  final String titulo;
  final String valor;
  final String detalle;
  final double? progreso;
  final List<KpiDatoSecundario> secundarios;

  const KpiCard({
    super.key,
    required this.icono,
    required this.acento,
    required this.titulo,
    required this.valor,
    required this.detalle,
    this.progreso,
    this.secundarios = const [],
  });

  @override
  Widget build(BuildContext context) {
    final progresoAcotado = progreso?.clamp(0.0, 1.0).toDouble();
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: acento.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icono, color: acento, size: 19),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  titulo,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.footer.copyWith(
                    color: AppColors.graphiteGray,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              valor,
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: AppColors.steelBlue,
                height: 1.05,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            detalle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.footer.copyWith(color: AppColors.graphiteGray),
          ),
          if (progresoAcotado != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progresoAcotado,
                minHeight: 6,
                color: acento,
                backgroundColor: AppColors.background,
              ),
            ),
          ],
          if (secundarios.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.inputBorder),
            const SizedBox(height: 10),
            Wrap(
              spacing: 16,
              runSpacing: 6,
              children: [for (final s in secundarios) s],
            ),
          ],
        ],
      ),
    );
  }
}

class KpiDatoSecundario extends StatelessWidget {
  final String etiqueta;
  final String valor;

  const KpiDatoSecundario({super.key, required this.etiqueta, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: valor,
            style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.steelBlue),
          ),
          TextSpan(text: ' $etiqueta'),
        ],
      ),
      style: AppTextStyles.footer.copyWith(color: AppColors.graphiteGray, fontSize: 12),
    );
  }
}
