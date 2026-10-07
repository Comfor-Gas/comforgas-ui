import 'package:flutter/material.dart';
import '../../../models/canje_reporte.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import 'badge_cantidad_canje.dart';
import 'canje_formato.dart';
import 'detalle_canje_grupo.dart';

class ReporteCanjeTarjeta extends StatefulWidget {
  final CanjeReporteGrupo grupo;

  const ReporteCanjeTarjeta({super.key, required this.grupo});

  @override
  State<ReporteCanjeTarjeta> createState() => _ReporteCanjeTarjetaState();
}

class _ReporteCanjeTarjetaState extends State<ReporteCanjeTarjeta> {
  bool _expandido = false;

  @override
  Widget build(BuildContext context) {
    final g = widget.grupo;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.inputBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => setState(() => _expandido = !_expandido),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          g.nombreChofer,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.label.copyWith(fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 10,
                          runSpacing: 2,
                          children: [
                            _Dato(icono: Icons.local_shipping_outlined, texto: g.etiquetaMovil),
                            _Dato(icono: Icons.schedule, texto: fechaHoraCanje(g.ultimoCanje)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  BadgeCantidadCanje(cantidad: g.totalDevoluciones),
                  Icon(
                    _expandido ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.graphiteGray,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
          if (_expandido) ...[
            Container(height: 1, color: AppColors.inputBorder.withValues(alpha: 0.6)),
            DetalleCanjeGrupo(grupo: g, compacto: true),
          ],
        ],
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  final IconData icono;
  final String texto;

  const _Dato({required this.icono, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icono, size: 14, color: AppColors.graphiteGray),
        const SizedBox(width: 4),
        Text(
          texto,
          style: AppTextStyles.input.copyWith(fontSize: 12.5, color: AppColors.graphiteGray),
        ),
      ],
    );
  }
}
