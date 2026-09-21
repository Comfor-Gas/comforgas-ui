import 'package:flutter/material.dart';
import '../../models/visita_alerta.dart';
import '../../theme/app_colors.dart';

class AlertaVisitaBadge extends StatelessWidget {
  final VisitaAlertaTipo? tipo;
  final bool compact;

  const AlertaVisitaBadge({super.key, required this.tipo, this.compact = false});

  (Color, IconData)? get _data {
    final t = tipo;
    if (t == null) return null;
    switch (t) {
      case VisitaAlertaTipo.desvioGeografico:
        return (AppColors.badgeRed, Icons.gps_off);
      case VisitaAlertaTipo.coordenadasInvalidas:
        return (AppColors.badgeRed, Icons.location_off);
      case VisitaAlertaTipo.incidenciaCampo:
        return (AppColors.badgeRed, Icons.report_problem_outlined);
      case VisitaAlertaTipo.desvioTemporal:
        return (AppColors.orange, Icons.schedule_outlined);
      case VisitaAlertaTipo.paradaFueraDeOrden:
        return (AppColors.orange, Icons.low_priority);
      case VisitaAlertaTipo.omisionNoJustificada:
        return (AppColors.orange, Icons.person_off_outlined);
      case VisitaAlertaTipo.coordenadasAusentes:
        return (AppColors.orange, Icons.location_disabled);
      case VisitaAlertaTipo.faltanteGarrafas:
        return (AppColors.badgeRed, Icons.propane_tank_outlined);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    if (data == null) return const SizedBox.shrink();
    final (color, icon) = data;
    final label = VisitaAlertaMapper.label(tipo!);

    if (compact) {
      return Tooltip(
        message: label,
        child: Icon(icon, size: 18, color: color),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
