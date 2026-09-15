import 'package:flutter/material.dart';
import '../../../models/canje_reporte.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

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

  String _fechaHora(DateTime? f) {
    if (f == null) return '—';
    final l = f.toLocal();
    final dd = l.day.toString().padLeft(2, '0');
    final mm = l.month.toString().padLeft(2, '0');
    final hh = l.hour.toString().padLeft(2, '0');
    final min = l.minute.toString().padLeft(2, '0');
    return '$dd/$mm $hh:$min';
  }

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
                    child: _BadgeCantidad(cantidad: g.totalDevoluciones),
                  ),
                ),
                Expanded(flex: 3, child: _texto(_fechaHora(g.ultimoCanje))),
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
        if (_expandido) _buildDetalle(g),
        Container(height: 1, color: AppColors.inputBorder.withOpacity(0.6)),
      ],
    );
  }

  Widget _buildDetalle(CanjeReporteGrupo g) {
    return Container(
      width: double.infinity,
      color: AppColors.background,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
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
          for (final d in g.detalles)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.inputBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.propane_tank_rounded, size: 18, color: AppColors.orange),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 4,
                    child: Column(
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
                    ),
                  ),
                  Expanded(
                    flex: 5,
                    child: Text(
                      d.descripcionDanio.trim().isEmpty ? 'Sin descripción' : d.descripcionDanio.trim(),
                      style: AppTextStyles.input.copyWith(fontSize: 13, color: AppColors.graphiteGray),
                    ),
                  ),
                  _BadgeCantidad(cantidad: d.cantidad, compacto: true),
                ],
              ),
            ),
        ],
      ),
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

class _BadgeCantidad extends StatelessWidget {
  final int cantidad;
  final bool compacto;

  const _BadgeCantidad({required this.cantidad, this.compacto = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compacto ? 9 : 11, vertical: compacto ? 4 : 6),
      decoration: BoxDecoration(
        color: AppColors.orange.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.orange.withOpacity(0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.assignment_return_outlined, size: compacto ? 13 : 15, color: AppColors.orange),
          SizedBox(width: compacto ? 5 : 6),
          Text(
            '$cantidad',
            style: TextStyle(
              fontSize: compacto ? 12 : 13.5,
              fontWeight: FontWeight.w800,
              color: AppColors.orange,
            ),
          ),
        ],
      ),
    );
  }
}
