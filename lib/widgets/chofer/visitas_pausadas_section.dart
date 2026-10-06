import 'package:flutter/material.dart';

import '../../models/visita_model.dart';
import '../../theme/app_colors.dart';
import 'agenda/seccion_visitas_desplegable.dart';
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
    return SeccionVisitasDesplegable(
      titulo: 'Venta social - pausadas',
      icono: Icons.pause_circle_outline,
      acento: AppColors.steelBlue,
      visitas: pausadas,
      expandido: expandido,
      onToggle: onToggle,
      itemBuilder: (v) => VisitaClienteCard(
        key: ValueKey('pausada-${v.idAgendaItem}-${v.idVisita}'),
        visita: v,
        nombreCliente: nombreCliente(v),
        direccionCliente: direccionCliente(v),
        esSiguiente: false,
        onTap: () => onTapVisita(v),
      ),
    );
  }
}
