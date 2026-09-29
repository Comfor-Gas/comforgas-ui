import 'package:flutter/material.dart';
import '../../../models/cuadre_rendicion.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import 'justificacion_diferencias_panel.dart';

class AjustesConciliacionPanel extends StatelessWidget {
  final List<MapEntry<ConceptoAjuste, int>> pendientes;
  final List<AjusteCuadre> ajustes;

  const AjustesConciliacionPanel({super.key, required this.pendientes, required this.ajustes});

  @override
  Widget build(BuildContext context) {
    if (pendientes.isEmpty && ajustes.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (pendientes.isNotEmpty) ...[
            const _Titulo(icono: Icons.balance_outlined, texto: 'DIFERENCIAS PENDIENTES'),
            const SizedBox(height: 8),
            for (final p in pendientes)
              _Fila(
                etiqueta: p.key.etiqueta,
                valor: '${p.value < 0 ? 'Falta' : 'Sobra'} ${formatSaldoConcepto(p.key, p.value)}',
                color: p.value < 0 ? AppColors.error : AppColors.badgeGreen,
              ),
          ],
          if (pendientes.isNotEmpty && ajustes.isNotEmpty) const SizedBox(height: 12),
          if (ajustes.isNotEmpty) ...[
            const _Titulo(icono: Icons.history, texto: 'AJUSTES REGISTRADOS'),
            const SizedBox(height: 8),
            for (final a in ajustes)
              _Fila(
                etiqueta: '${a.concepto.etiqueta} · ${a.tipo.etiqueta}',
                detalle: a.observacion,
                valor: formatSaldoConcepto(a.concepto, a.valor),
                color: AppColors.steelBlue,
              ),
          ],
        ],
      ),
    );
  }
}

class _Titulo extends StatelessWidget {
  final IconData icono;
  final String texto;

  const _Titulo({required this.icono, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icono, size: 15, color: AppColors.steelBlue),
        const SizedBox(width: 6),
        Text(
          texto,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
            color: AppColors.steelBlue,
          ),
        ),
      ],
    );
  }
}

class _Fila extends StatelessWidget {
  final String etiqueta;
  final String? detalle;
  final String valor;
  final Color color;

  const _Fila({required this.etiqueta, required this.valor, required this.color, this.detalle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(etiqueta, style: AppTextStyles.label.copyWith(fontSize: 13)),
                if (detalle != null && detalle!.trim().isNotEmpty)
                  Text(
                    detalle!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.footer.copyWith(color: AppColors.graphiteGray),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(valor, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }
}
