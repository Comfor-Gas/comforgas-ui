import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../utils/date_format_utils.dart';

class UltimaBajadaIndicator extends StatelessWidget {
  final DateTime? fecha;
  final bool compacto;

  const UltimaBajadaIndicator({
    super.key,
    required this.fecha,
    this.compacto = false,
  });

  @override
  Widget build(BuildContext context) {
    final valor = fecha != null ? formatFechaCorta(fecha!) : 'Sin registro';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.event_available_outlined,
          size: compacto ? 13 : 14,
          color: AppColors.steelBlue,
        ),
        const SizedBox(width: 5),
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: compacto ? 11.5 : 12.5,
              color: AppColors.graphiteGray,
              fontWeight: FontWeight.w500,
            ),
            children: [
              const TextSpan(text: 'Última bajada: '),
              TextSpan(
                text: valor,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.steelBlue,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
