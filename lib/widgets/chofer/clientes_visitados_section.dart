import 'package:flutter/material.dart';

import '../../models/visita_model.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'visita_cliente_card.dart';

/// Sección desplegable con las visitas ya completadas del día. Al finalizar
/// una visita, la tarjeta correspondiente se "mueve" acá automáticamente
/// (la agenda simplemente deja de renderizarla en la lista de pendientes).
class ClientesVisitadosSection extends StatelessWidget {
  final List<VisitaModel> visitados;
  final bool expandido;
  final ValueChanged<bool> onToggle;
  final String Function(VisitaModel) nombreCliente;
  final String Function(VisitaModel) direccionCliente;
  final void Function(VisitaModel) onTapVisita;

  const ClientesVisitadosSection({
    super.key,
    required this.visitados,
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
        border: Border.all(color: AppColors.inputBorder),
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
                  Expanded(
                    child: Text(
                      'Clientes Visitados (${visitados.length})',
                      style: AppTextStyles.label,
                    ),
                  ),
                  AnimatedRotation(
                    turns: expandido ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: const Icon(Icons.keyboard_arrow_down, color: AppColors.graphiteGray),
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
                children: visitados
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
