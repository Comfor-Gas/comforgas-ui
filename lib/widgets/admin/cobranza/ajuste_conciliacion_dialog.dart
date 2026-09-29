import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/cuadre_rendicion.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../utils/formato.dart';

class AjusteConciliacionResultado {
  final ConceptoAjuste concepto;
  final TipoAjuste tipo;
  final int valor;
  final String observacion;

  const AjusteConciliacionResultado({
    required this.concepto,
    required this.tipo,
    required this.valor,
    required this.observacion,
  });
}

Future<AjusteConciliacionResultado?> mostrarAjusteConciliacionDialog(
  BuildContext context, {
  required Map<ConceptoAjuste, int> saldos,
}) {
  return showDialog<AjusteConciliacionResultado>(
    context: context,
    builder: (_) => _AjusteConciliacionDialog(saldos: saldos),
  );
}

String formatSaldoConcepto(ConceptoAjuste concepto, int valor) {
  final abs = valor.abs();
  return concepto.esDinero ? formatMoneda(abs) : '$abs ${abs == 1 ? 'garrafa' : 'garrafas'}';
}

TipoAjuste? tipoQueCompensa(int saldo) {
  if (saldo < 0) return TipoAjuste.faltanteCobrado;
  if (saldo > 0) return TipoAjuste.sobranteAceptado;
  return null;
}

class _AjusteConciliacionDialog extends StatefulWidget {
  final Map<ConceptoAjuste, int> saldos;

  const _AjusteConciliacionDialog({required this.saldos});

  @override
  State<_AjusteConciliacionDialog> createState() => _AjusteConciliacionDialogState();
}

class _AjusteConciliacionDialogState extends State<_AjusteConciliacionDialog> {
  final _valor = TextEditingController();
  final _observacion = TextEditingController();
  late ConceptoAjuste _concepto;
  TipoAjuste? _tipo;

  List<ConceptoAjuste> get _conPendiente => [
        for (final c in ConceptoAjuste.values)
          if ((widget.saldos[c] ?? 0) != 0) c,
      ];

  int get _saldo => widget.saldos[_concepto] ?? 0;

  @override
  void initState() {
    super.initState();
    final pendientes = _conPendiente;
    _concepto = pendientes.isNotEmpty ? pendientes.first : ConceptoAjuste.efectivo;
    _elegirConcepto(_concepto);
    _valor.addListener(() => setState(() {}));
    _observacion.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _valor.dispose();
    _observacion.dispose();
    super.dispose();
  }

  void _elegirConcepto(ConceptoAjuste c) {
    _concepto = c;
    final saldo = widget.saldos[c] ?? 0;
    _tipo = tipoQueCompensa(saldo);
    _valor.text = saldo == 0 ? '' : '${saldo.abs()}';
  }

  int get _valorIngresado => int.tryParse(_valor.text.trim()) ?? 0;

  String? get _error {
    if (_tipo == null) return 'Este concepto no tiene diferencia para ajustar.';
    if (tipoQueCompensa(_saldo) != _tipo) {
      return _saldo < 0
          ? 'Hay un faltante: el ajuste tiene que ser de tipo Faltante.'
          : 'Hay un sobrante: el ajuste tiene que ser de tipo Sobrante.';
    }
    if (_valorIngresado <= 0) return 'Ingresá un valor mayor a cero.';
    if (_valorIngresado > _saldo.abs()) {
      return 'No puede superar la diferencia (${formatSaldoConcepto(_concepto, _saldo)}).';
    }
    return null;
  }

  bool get _valido => _error == null && _observacion.text.trim().isNotEmpty;

  void _confirmar() {
    final tipo = _tipo;
    if (!_valido || tipo == null) return;
    Navigator.of(context).pop(AjusteConciliacionResultado(
      concepto: _concepto,
      tipo: tipo,
      valor: _valorIngresado,
      observacion: _observacion.text.trim(),
    ));
  }

  InputDecoration _decoracion(String etiqueta, {String? sufijo, String? prefijo}) {
    return InputDecoration(
      labelText: etiqueta,
      isDense: true,
      prefixText: prefijo,
      suffixText: sufijo,
      enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppColors.inputBorder)),
      focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppColors.orange)),
      floatingLabelStyle: const TextStyle(color: AppColors.orange),
    );
  }

  @override
  Widget build(BuildContext context) {
    final error = _valor.text.isEmpty && _tipo != null ? null : _error;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Ajustar diferencia', style: AppTextStyles.title),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Elegí qué querés ajustar. El ajuste compensa la diferencia entre lo que rindió el chofer y lo que registró el sistema.',
                style: AppTextStyles.link.copyWith(fontSize: 12.5),
              ),
              const SizedBox(height: 14),
              Text('QUÉ SE AJUSTA', style: _etiquetaSeccion),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in ConceptoAjuste.values)
                    _ChipConcepto(
                      concepto: c,
                      saldo: widget.saldos[c] ?? 0,
                      seleccionado: c == _concepto,
                      onTap: () => setState(() => _elegirConcepto(c)),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text('TIPO', style: _etiquetaSeccion),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (final t in TipoAjuste.values) ...[
                    Expanded(
                      child: _OpcionTipo(
                        tipo: t,
                        seleccionado: _tipo == t,
                        habilitado: tipoQueCompensa(_saldo) == t,
                        onTap: () => setState(() => _tipo = t),
                      ),
                    ),
                    if (t != TipoAjuste.values.last) const SizedBox(width: 10),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _valor,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                cursorColor: AppColors.orange,
                decoration: _decoracion(
                  _concepto.esDinero ? 'Importe' : 'Cantidad',
                  prefijo: _concepto.esDinero ? '\$ ' : null,
                  sufijo: _concepto.esDinero ? null : 'garrafas',
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: 6),
                Text(error, style: AppTextStyles.errorText),
              ],
              const SizedBox(height: 14),
              TextField(
                controller: _observacion,
                maxLines: 3,
                cursorColor: AppColors.orange,
                decoration: _decoracion('Motivo del ajuste (obligatorio)'),
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
          onPressed: _valido ? _confirmar : null,
          child: Text(
            'Registrar ajuste',
            style: AppTextStyles.button.copyWith(color: _valido ? AppColors.orange : AppColors.badgeGray),
          ),
        ),
      ],
    );
  }
}

const TextStyle _etiquetaSeccion = TextStyle(
  fontSize: 11.5,
  fontWeight: FontWeight.w800,
  letterSpacing: 0.6,
  color: AppColors.graphiteGray,
);

class _ChipConcepto extends StatelessWidget {
  final ConceptoAjuste concepto;
  final int saldo;
  final bool seleccionado;
  final VoidCallback onTap;

  const _ChipConcepto({
    required this.concepto,
    required this.saldo,
    required this.seleccionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = seleccionado ? AppColors.orange : AppColors.steelBlue;
    final detalle = saldo == 0
        ? 'Sin diferencia'
        : '${saldo < 0 ? 'Falta' : 'Sobra'} ${formatSaldoConcepto(concepto, saldo)}';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 128,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: seleccionado ? AppColors.orange.withOpacity(0.1) : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: seleccionado ? AppColors.orange.withOpacity(0.6) : AppColors.inputBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              concepto.etiqueta,
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              detalle,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: saldo == 0 ? AppColors.inputHint : (saldo < 0 ? AppColors.error : AppColors.badgeGreen),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OpcionTipo extends StatelessWidget {
  final TipoAjuste tipo;
  final bool seleccionado;
  final bool habilitado;
  final VoidCallback onTap;

  const _OpcionTipo({
    required this.tipo,
    required this.seleccionado,
    required this.habilitado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final descripcion = tipo == TipoAjuste.faltanteCobrado
        ? 'Falta plata o garrafas: se le cobra / descuenta al chofer.'
        : 'Sobra plata o garrafas: se acepta el excedente.';
    final color = !habilitado
        ? AppColors.inputHint
        : (seleccionado ? AppColors.orange : AppColors.steelBlue);
    return Opacity(
      opacity: habilitado ? 1 : 0.55,
      child: InkWell(
        onTap: habilitado ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: seleccionado ? AppColors.orange.withOpacity(0.1) : AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: seleccionado ? AppColors.orange.withOpacity(0.6) : AppColors.inputBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    seleccionado ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    size: 16,
                    color: color,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      tipo.etiqueta,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(descripcion, style: AppTextStyles.footer.copyWith(color: AppColors.graphiteGray, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}
