import 'package:flutter/material.dart';
import '../../../models/control_comodato.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import 'faltante_badge.dart';

class AuditoriaComodatoFila extends StatefulWidget {
  final ControlComodato control;
  final bool par;
  final String? nombreCliente;

  const AuditoriaComodatoFila({
    super.key,
    required this.control,
    required this.par,
    this.nombreCliente,
  });

  @override
  State<AuditoriaComodatoFila> createState() => _AuditoriaComodatoFilaState();
}

class _AuditoriaComodatoFilaState extends State<AuditoriaComodatoFila> {
  bool _expandido = false;

  bool get _tieneObs =>
      widget.control.observaciones != null &&
      widget.control.observaciones!.trim().isNotEmpty;

  String _fecha(DateTime? f) {
    if (f == null) return '—';
    final l = f.toLocal();
    final dd = l.day.toString().padLeft(2, '0');
    final mm = l.month.toString().padLeft(2, '0');
    return '$dd/$mm/${l.year}';
  }

  String _cliente() {
    final nombre = widget.nombreCliente?.trim();
    if (nombre != null && nombre.isNotEmpty) return nombre;
    final nombreControl = widget.control.nombreCliente?.trim();
    if (nombreControl != null && nombreControl.isNotEmpty) return nombreControl;
    final id = widget.control.idClienteExt;
    return id == null ? 'Cliente s/d' : 'Cliente #$id';
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.control;
    final fondo = widget.par ? AppColors.white : AppColors.background.withOpacity(0.5);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: _tieneObs ? () => setState(() => _expandido = !_expandido) : null,
          child: Container(
            color: fondo,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                Expanded(flex: 3, child: _texto(c.nombreChofer ?? 'Sin asignar', bold: true)),
                Expanded(flex: 3, child: _texto(_cliente())),
                Expanded(flex: 2, child: _texto(_fecha(c.timestampControl))),
                Expanded(flex: 2, child: _texto('${c.cantidadContratada}')),
                Expanded(flex: 2, child: _texto('${c.cantidadFisicaActual}')),
                Expanded(
                  flex: 3,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FaltanteBadge(
                      faltante: c.faltante,
                      sobrante: c.sobrante,
                      compacto: true,
                    ),
                  ),
                ),
                SizedBox(
                  width: 32,
                  child: _tieneObs
                      ? Icon(
                          _expandido ? Icons.expand_less : Icons.expand_more,
                          color: AppColors.graphiteGray,
                          size: 22,
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
        if (_expandido && _tieneObs) _buildDetalle(c),
        Container(height: 1, color: AppColors.inputBorder.withOpacity(0.6)),
      ],
    );
  }

  Widget _buildDetalle(ControlComodato c) {
    return Container(
      width: double.infinity,
      color: AppColors.background,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.inputBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'OBSERVACIONES',
              style: AppTextStyles.footer.copyWith(
                letterSpacing: 0.4,
                fontWeight: FontWeight.w700,
                color: AppColors.graphiteGray,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              c.observaciones!.trim(),
              style: AppTextStyles.input.copyWith(fontSize: 13.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _texto(String t, {bool bold = false}) {
    return Text(
      t,
      style: bold
          ? AppTextStyles.label.copyWith(fontSize: 13.5)
          : AppTextStyles.input.copyWith(fontSize: 13.5, color: AppColors.graphiteGray),
      overflow: TextOverflow.ellipsis,
    );
  }
}
