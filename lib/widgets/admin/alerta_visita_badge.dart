import 'package:flutter/material.dart';
import '../../models/visita_alerta.dart';
import '../../theme/app_colors.dart';

class AlertaVisitaBadge extends StatelessWidget {
  final VisitaAlertaTipo tipo;
  final bool compact;

  const AlertaVisitaBadge({
    super.key,
    required this.tipo,
    this.compact = false,
  });

  (Color, IconData)? get _data {
    switch (tipo) {
      case VisitaAlertaTipo.gpsDesvio:
        return (AppColors.badgeRed, Icons.gpp_maybe_outlined);
      case VisitaAlertaTipo.fueraDeHorario:
        return (AppColors.orange, Icons.schedule_outlined);
      case VisitaAlertaTipo.clienteSalteado:
        return (AppColors.orange, Icons.person_off_outlined);
      case VisitaAlertaTipo.ninguna:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    if (data == null) return const SizedBox.shrink();
    final (color, icon) = data;
    final label = VisitaAlertaMapper.label(tipo);

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
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
