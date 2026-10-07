import 'package:flutter/material.dart';
import '../../../models/dashboard/dashboard_kpis.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/formato.dart';
import '../../../utils/formato_dashboard.dart';

class ChoferResumenTile extends StatelessWidget {
  final KpiChofer chofer;
  final bool alterna;

  const ChoferResumenTile({super.key, required this.chofer, this.alterna = false});

  @override
  Widget build(BuildContext context) {
    final c = chofer;
    const fuerte = TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.steelBlue);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: alterna ? AppColors.background.withValues(alpha: 0.5) : AppColors.white,
        border: const Border(bottom: BorderSide(color: AppColors.inputBorder, width: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  c.nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: fuerte,
                ),
              ),
              const SizedBox(width: 10),
              Text(formatMoneda(c.montoTotal), style: fuerte),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _Dato(
                  etiqueta: 'Visitas',
                  valor: '${formatEntero(c.realizadas)} / ${formatEntero(c.programadas)}',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Dato(etiqueta: 'Cumplimiento', valor: formatPorcentaje(c.porcentajeCumplimiento)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _Dato(etiqueta: 'Efect. venta', valor: formatPorcentaje(c.efectividadVenta)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Dato(etiqueta: 'Recupero', valor: formatPorcentaje(c.tasaRecupero)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  final String etiqueta;
  final String valor;

  const _Dato({required this.etiqueta, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          etiqueta.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: AppColors.graphiteGray,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          valor,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.steelBlue),
        ),
      ],
    );
  }
}
