import 'package:flutter/material.dart';
import '../../models/cliente_ficha.dart';
import '../../models/visita_estado.dart';
import '../../models/visita_model.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'comodato_badge.dart';
import 'visita_estado_chip.dart';

class VisitaClienteCard extends StatelessWidget {
  final VisitaModel visita;
  final String nombreCliente;
  final String direccionCliente;
  final bool esSiguiente;
  final String etiquetaDestacada;
  final VoidCallback onTap;

  const VisitaClienteCard({
    super.key,
    required this.visita,
    required this.nombreCliente,
    required this.direccionCliente,
    required this.esSiguiente,
    required this.onTap,
    this.etiquetaDestacada = 'NEXT',
  });

  @override
  Widget build(BuildContext context) {
    final completada = VisitaEstadoMapper.esTerminadaEnCampo(visita.estadoVisita);
    final ficha = ClienteFicha.fromVisita(
      visita,
      nombreResuelto: nombreCliente,
      domicilioResuelto: direccionCliente,
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: esSiguiente ? AppColors.orange : AppColors.inputBorder,
            width: esSiguiente ? 1.6 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _OrdenIndicator(
                        orden: ficha.orden,
                        completada: completada,
                        esSiguiente: esSiguiente,
                        etiquetaDestacada: etiquetaDestacada,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ficha.nombre,
                              style: AppTextStyles.label.copyWith(fontSize: 15),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            _InfoLinea(
                              icon: Icons.location_on_outlined,
                              texto: ficha.domicilio,
                            ),
                            const SizedBox(height: 9),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                VisitaEstadoChip(estado: visita.estadoVisita),
                                if (ficha.tieneComodatoActivo)
                                  const ComodatoBadge(compacto: true),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                width: 44,
                decoration: const BoxDecoration(
                  color: AppColors.orange,
                  borderRadius: BorderRadius.horizontal(
                    right: Radius.circular(16),
                  ),
                ),
                child: const Icon(
                  Icons.local_fire_department_outlined,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoLinea extends StatelessWidget {
  final IconData icon;
  final String texto;

  const _InfoLinea({required this.icon, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: 14, color: AppColors.inputHint),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            texto,
            style: AppTextStyles.link.copyWith(fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _OrdenIndicator extends StatelessWidget {
  final int orden;
  final bool completada;
  final bool esSiguiente;
  final String etiquetaDestacada;

  const _OrdenIndicator({
    required this.orden,
    required this.completada,
    this.esSiguiente = false,
    this.etiquetaDestacada = 'NEXT',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: completada
                  ? AppColors.badgeGreen
                  : (esSiguiente ? AppColors.orange : AppColors.steelBlue),
              width: 1.6,
            ),
            color: completada
                ? AppColors.badgeGreen.withOpacity(0.08)
                : (esSiguiente ? AppColors.orange : AppColors.steelBlue).withOpacity(0.08),
          ),
          child: completada
              ? const Icon(Icons.check, color: AppColors.badgeGreen, size: 20)
              : Text(
                  '$orden',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: esSiguiente ? AppColors.orange : AppColors.steelBlue,
                  ),
                ),
        ),
        if (esSiguiente && !completada) ...[
          const SizedBox(height: 3),
          Text(
            etiquetaDestacada,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: AppColors.orange,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ],
    );
  }
}
