import 'package:flutter/material.dart';

import '../../models/visita_model.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'visita_cliente_card.dart';

class VisitasPausadasSection extends StatelessWidget {
  final List<VisitaModel> pausadas;
  final bool expandido;
  final ValueChanged<bool> onToggle;
  final String Function(VisitaModel) nombreCliente;
  final String Function(VisitaModel) direccionCliente;
  final void Function(VisitaModel) onTapVisita;

  const VisitasPausadasSection({
    super.key,
    required this.pausadas,
    required this.expandido,
    required this.onToggle,
    required this.nombreCliente,
    required this.direccionCliente,
    required this.onTapVisita,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.steelBlue.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => onToggle(!expandido),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  const Icon(Icons.pause_circle_outline, size: 18, color: AppColors.steelBlue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Venta Social - Pausadas (${pausadas.length})',
                      style: AppTextStyles.label.copyWith(color: AppColors.steelBlue),
                    ),
                  ),
                  AnimatedRotation(
                    turns: expandido ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: const Icon(Icons.keyboard_arrow_down, color: AppColors.steelBlue),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 180),
            crossFadeState: expandido ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            firstChild: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                children: pausadas
                    .map(
                      (v) => VisitaClienteCard(
                        visita: v,
                        nombreCliente: nombreCliente(v),
                        direccionCliente: direccionCliente(v),
                        esSiguiente: false,
                        onTap: () => onTapVisita(v),
                      ),
                    )
                    .toList(),
              ),
            ),
            secondChild: const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}
