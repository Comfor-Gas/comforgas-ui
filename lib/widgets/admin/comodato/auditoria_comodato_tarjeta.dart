import 'package:flutter/material.dart';
import '../../../models/control_comodato.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import 'comodato_formato.dart';
import 'faltante_badge.dart';
import 'foto_control_comodato.dart';

class AuditoriaComodatoTarjeta extends StatefulWidget {
  final ControlComodato control;
  final String? nombreCliente;

  const AuditoriaComodatoTarjeta({
    super.key,
    required this.control,
    this.nombreCliente,
  });

  @override
  State<AuditoriaComodatoTarjeta> createState() => _AuditoriaComodatoTarjetaState();
}

class _AuditoriaComodatoTarjetaState extends State<AuditoriaComodatoTarjeta> {
  bool _expandido = false;

  bool get _tieneObs =>
      widget.control.observaciones != null &&
      widget.control.observaciones!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final c = widget.control;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: c.tieneFaltante ? AppColors.badgeRed.withValues(alpha: 0.45) : AppColors.inputBorder,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.nombreChofer ?? 'Sin asignar',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.label.copyWith(fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        clienteControlComodato(c, widget.nombreCliente),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.input.copyWith(
                          fontSize: 13,
                          color: AppColors.graphiteGray,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        fechaControlComodato(c.timestampControl),
                        style: AppTextStyles.footer.copyWith(color: AppColors.graphiteGray),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                FotoControlComodato(control: c),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _Dato(etiqueta: 'Contratadas', valor: '${c.cantidadContratada}'),
                _Dato(etiqueta: 'Físicas', valor: '${c.cantidadFisicaActual}'),
                FaltanteBadge(
                  faltante: c.faltante,
                  sobrante: c.sobrante,
                  compacto: true,
                ),
              ],
            ),
          ),
          if (_tieneObs) ...[
            Container(height: 1, color: AppColors.inputBorder.withValues(alpha: 0.6)),
            InkWell(
              onTap: () => setState(() => _expandido = !_expandido),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    const Icon(Icons.notes_outlined, size: 16, color: AppColors.graphiteGray),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Observaciones',
                        style: AppTextStyles.footer.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.steelBlue,
                        ),
                      ),
                    ),
                    Icon(
                      _expandido ? Icons.expand_less : Icons.expand_more,
                      color: AppColors.graphiteGray,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            if (_expandido)
              Container(
                color: AppColors.background,
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                child: Text(
                  c.observaciones!.trim(),
                  style: AppTextStyles.input.copyWith(fontSize: 13.5),
                ),
              ),
          ],
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(etiqueta, style: AppTextStyles.footer.copyWith(color: AppColors.graphiteGray)),
          const SizedBox(width: 6),
          Text(
            valor,
            style: AppTextStyles.label.copyWith(fontSize: 13.5, color: AppColors.steelBlue),
          ),
        ],
      ),
    );
  }
}
