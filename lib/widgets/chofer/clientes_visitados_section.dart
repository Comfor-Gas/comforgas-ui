import 'package:flutter/material.dart';

import '../../models/visita_estado.dart';
import '../../models/visita_model.dart';
import '../../theme/app_colors.dart';
import 'agenda/seccion_visitas_desplegable.dart';
import 'visita_cliente_card.dart';

class ClientesVisitadosSection extends StatelessWidget {
  final List<VisitaModel> visitados;
  final bool expandido;
  final ValueChanged<bool> onToggle;
  final String Function(VisitaModel) nombreCliente;
  final String Function(VisitaModel) direccionCliente;
  final void Function(VisitaModel) onTapVisita;
  final void Function(VisitaModel)? onVerComprobante;

  const ClientesVisitadosSection({
    super.key,
    required this.visitados,
    required this.expandido,
    required this.onToggle,
    required this.nombreCliente,
    required this.direccionCliente,
    required this.onTapVisita,
    this.onVerComprobante,
  });

  @override
  Widget build(BuildContext context) {
    return SeccionVisitasDesplegable(
      titulo: 'Clientes visitados',
      icono: Icons.check_circle_outline,
      acento: AppColors.graphiteGray,
      visitas: visitados,
      expandido: expandido,
      onToggle: onToggle,
      mensajeVacio: 'Ningún cliente visitado coincide con la búsqueda.',
      itemBuilder: (v) => VisitaClienteCard(
        key: ValueKey('visitado-${v.idAgendaItem}-${v.idVisita}'),
        visita: v,
        nombreCliente: nombreCliente(v),
        direccionCliente: direccionCliente(v),
        esSiguiente: false,
        onTap: () => onTapVisita(v),
        onVerComprobante: onVerComprobante == null || !VisitaEstadoMapper.tieneComprobante(v.estadoVisita)
            ? null
            : () => onVerComprobante!(v),
      ),
    );
  }
}
