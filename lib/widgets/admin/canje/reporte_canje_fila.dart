import 'package:flutter/material.dart';
import '../../../models/canje_reporte.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import 'badge_cantidad_canje.dart';
import 'canje_formato.dart';
import 'detalle_canje_grupo.dart';

class ReporteCanjeFila extends StatefulWidget {
  final CanjeReporteGrupo grupo;
  final bool par;

  const ReporteCanjeFila({
    super.key,
    required this.grupo,
    required this.par,
  });

  @override
  State<ReporteCanjeFila> createState() => _ReporteCanjeFilaState();
}

class _ReporteCanjeFilaState extends State<ReporteCanjeFila> {
  bool _expandido = false;

  @override
  Widget build(BuildContext context) {
    final g = widget.grupo;
    final fondo = widget.par ? AppColors.white : AppColors.background.withOpacity(0.5);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () => setState(() => _expandido = !_expandido),
          child: Container(
            color: fondo,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                Expanded(flex: 4, child: _texto(g.nombreChofer, bold: true)),
                Expanded(flex: 3, child: _texto(g.etiquetaMovil)),
                Expanded(
                  flex: 2,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: BadgeCantidadCanje(cantidad: g.totalDevoluciones),
                  ),
                ),
                Expanded(flex: 3, child: _texto(fechaHoraCanje(g.ultimoCanje))),
                SizedBox(
                  width: 32,
                  child: Icon(
                    _expandido ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.graphiteGray,
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_expandido) DetalleCanjeGrupo(grupo: g),
        Container(height: 1, color: AppColors.inputBorder.withOpacity(0.6)),
      ],
    );
  }

  Widget _texto(String t, {bool bold = false}) {
    return Text(
      t,
      style: bold
          ? AppTextStyles.label.copyWith(fontSize: 13.5)
          : AppTextStyles.input.copyWith(fontSize: 13.5, color: AppColors.graphiteGray),
      overflow: TextOverflow.ellipsis,
    );
  }
}
