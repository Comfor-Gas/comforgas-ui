import 'package:flutter/material.dart';
import '../../../models/cuadre_rendicion.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import 'ajuste_conciliacion_dialog.dart';

class AprobacionConciliacion {
  final String observacion;
  final bool aceptarDiferencias;

  const AprobacionConciliacion({required this.observacion, required this.aceptarDiferencias});
}

Future<AprobacionConciliacion?> mostrarAprobarConciliacionDialog(
  BuildContext context, {
  required List<MapEntry<ConceptoAjuste, int>> diferencias,
  bool forzarDiferencias = false,
}) {
  return showDialog<AprobacionConciliacion>(
    context: context,
    builder: (_) => _AprobarConciliacionDialog(
      diferencias: diferencias,
      forzarDiferencias: forzarDiferencias,
    ),
  );
}

class _AprobarConciliacionDialog extends StatefulWidget {
  final List<MapEntry<ConceptoAjuste, int>> diferencias;
  final bool forzarDiferencias;

  const _AprobarConciliacionDialog({required this.diferencias, this.forzarDiferencias = false});

  @override
  State<_AprobarConciliacionDialog> createState() => _AprobarConciliacionDialogState();
}

class _AprobarConciliacionDialogState extends State<_AprobarConciliacionDialog> {
  final _motivo = TextEditingController();

  bool get _conDiferencias => widget.diferencias.isNotEmpty || widget.forzarDiferencias;

  bool get _valido => !_conDiferencias || _motivo.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _motivo.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _motivo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        _conDiferencias ? 'Aprobar con diferencias' : 'Aprobar rendición',
        style: AppTextStyles.title,
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _conDiferencias
                    ? 'Quedan diferencias sin ajustar. Si aprobás, se registran como diferencia aceptada con el motivo que indiques.'
                    : 'La rendición cuadra. Al aprobarla, la ruta del chofer queda cerrada y podés pasar al arqueo de caja.',
                style: AppTextStyles.link.copyWith(fontSize: 12.5),
              ),
              if (widget.diferencias.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.badgeAmber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.badgeAmber.withOpacity(0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final d in widget.diferencias)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  d.key.etiqueta,
                                  style: AppTextStyles.footer.copyWith(color: AppColors.graphiteGray),
                                ),
                              ),
                              Text(
                                '${d.value < 0 ? 'Falta' : 'Sobra'} ${formatSaldoConcepto(d.key, d.value)}',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: d.value < 0 ? AppColors.error : AppColors.badgeGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),
              TextField(
                controller: _motivo,
                maxLines: 3,
                cursorColor: AppColors.orange,
                decoration: InputDecoration(
                  labelText: _conDiferencias ? 'Motivo (obligatorio)' : 'Observación (opcional)',
                  isDense: true,
                  enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppColors.inputBorder)),
                  focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppColors.orange)),
                  floatingLabelStyle: const TextStyle(color: AppColors.orange),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancelar', style: AppTextStyles.button.copyWith(color: AppColors.graphiteGray)),
        ),
        TextButton(
          onPressed: _valido
              ? () => Navigator.of(context).pop(AprobacionConciliacion(
                    observacion: _motivo.text.trim(),
                    aceptarDiferencias: _conDiferencias,
                  ))
              : null,
          child: Text(
            _conDiferencias ? 'Aprobar con diferencias' : 'Aprobar',
            style: AppTextStyles.button.copyWith(color: _valido ? AppColors.badgeGreen : AppColors.badgeGray),
          ),
        ),
      ],
    );
  }
}
