import 'package:flutter/material.dart';

import '../../models/cliente_ficha.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/date_format_utils.dart';
import 'comodato_badge.dart';
import 'ultima_bajada_indicator.dart';
import 'visita_estado_chip.dart';
import '../../models/visita_estado.dart';

/// Tarjeta con los datos del cliente de la visita activa y, una vez hecho
/// el check-in, la hora en la que se registró.
class VisitaCheckinCard extends StatelessWidget {
  final String nombreCliente;
  final String direccionCliente;
  final VisitaEstado estado;
  final DateTime? horaCheckIn;
  final ClienteFicha? ficha;
  final int? comodatoTotal;

  const VisitaCheckinCard({
    super.key,
    required this.nombreCliente,
    required this.direccionCliente,
    required this.estado,
    this.horaCheckIn,
    this.ficha,
    this.comodatoTotal,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.inputBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.steelBlue.withOpacity(0.1),
                child: const Icon(Icons.storefront_outlined, color: AppColors.steelBlue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            nombreCliente,
                            style: AppTextStyles.label.copyWith(fontSize: 16),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (ficha != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.steelBlue.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'ID ${ficha!.clienteId}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.steelBlue,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      direccionCliente,
                      style: AppTextStyles.link.copyWith(fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (ficha != null && ficha!.tieneBarrio) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Barrio ${ficha!.barrio}',
                        style: AppTextStyles.link.copyWith(fontSize: 12.5),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (ficha != null && ficha!.tieneTelefono) ...[
                      const SizedBox(height: 2),
                      Text(
                        ficha!.telefono,
                        style: AppTextStyles.link.copyWith(fontSize: 12.5),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        VisitaEstadoChip(estado: estado),
                        if (ficha != null && ficha!.tieneComodatoActivo)
                          ComodatoBadge(total: comodatoTotal, compacto: true),
                      ],
                    ),
                    if (ficha != null) ...[
                      const SizedBox(height: 8),
                      UltimaBajadaIndicator(fecha: ficha!.ultimaBajada, compacto: true),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        if (horaCheckIn != null) ...[
          const SizedBox(height: 14),
          Center(
            child: Text(
              'Check-in: ${formatHora12(horaCheckIn!)}',
              style: AppTextStyles.title.copyWith(fontSize: 16),
            ),
          ),
        ],
      ],
    );
  }
}
