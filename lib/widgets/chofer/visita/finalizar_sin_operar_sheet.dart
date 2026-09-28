import 'package:flutter/material.dart';
import '../../../models/motivo_sin_operar.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

Future<ResultadoSinOperar?> mostrarFinalizarSinOperarSheet(BuildContext context) {
  return showModalBottomSheet<ResultadoSinOperar>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => const _FinalizarSinOperarSheet(),
  );
}

class _FinalizarSinOperarSheet extends StatefulWidget {
  const _FinalizarSinOperarSheet();

  @override
  State<_FinalizarSinOperarSheet> createState() => _FinalizarSinOperarSheetState();
}

class _FinalizarSinOperarSheetState extends State<_FinalizarSinOperarSheet> {
  final _detalleCtrl = TextEditingController();
  MotivoSinOperar? _motivo;

  @override
  void initState() {
    super.initState();
    _detalleCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _detalleCtrl.dispose();
    super.dispose();
  }

  bool get _valido {
    final motivo = _motivo;
    if (motivo == null) return false;
    return !motivo.requiereDetalle || _detalleCtrl.text.trim().isNotEmpty;
  }

  void _confirmar() {
    final motivo = _motivo;
    if (motivo == null || !_valido) return;
    Navigator.of(context).pop(
      ResultadoSinOperar(motivo: motivo, detalle: _detalleCtrl.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.inputBorder,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text('Cancelar visita', style: AppTextStyles.title.copyWith(fontSize: 18)),
                const SizedBox(height: 6),
                Text(
                  'La visita se finaliza sin operar. Indicá qué pasó para que quede registrado.',
                  style: AppTextStyles.footer.copyWith(color: AppColors.graphiteGray),
                ),
                const SizedBox(height: 16),
                for (final motivo in MotivoSinOperar.opciones)
                  _OpcionMotivo(
                    motivo: motivo,
                    seleccionado: _motivo?.codigo == motivo.codigo,
                    onTap: () => setState(() => _motivo = motivo),
                  ),
                const SizedBox(height: 8),
                TextField(
                  controller: _detalleCtrl,
                  maxLines: 2,
                  style: AppTextStyles.input,
                  decoration: InputDecoration(
                    hintText: (_motivo?.requiereDetalle ?? false)
                        ? 'Contá qué pasó (obligatorio)'
                        : 'Detalle adicional (opcional)',
                    hintStyle: AppTextStyles.hint,
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.inputBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.inputBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.orange),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                ElevatedButton(
                  onPressed: _valido ? _confirmar : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    disabledBackgroundColor: AppColors.inputBorder,
                    foregroundColor: Colors.white,
                    disabledForegroundColor: AppColors.inputHint,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: AppTextStyles.button,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('FINALIZAR SIN OPERAR'),
                ),
                const SizedBox(height: 6),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'VOLVER A LA VISITA',
                    style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.steelBlue),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OpcionMotivo extends StatelessWidget {
  final MotivoSinOperar motivo;
  final bool seleccionado;
  final VoidCallback onTap;

  const _OpcionMotivo({
    required this.motivo,
    required this.seleccionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: seleccionado ? AppColors.orange.withOpacity(0.08) : AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: seleccionado ? AppColors.orange : AppColors.inputBorder,
              width: seleccionado ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                seleccionado ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                size: 20,
                color: seleccionado ? AppColors.orange : AppColors.steelBlue,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  motivo.etiqueta,
                  style: AppTextStyles.label.copyWith(fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
