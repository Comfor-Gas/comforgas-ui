import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/responsive.dart';
import '../../../models/cuenta_corriente_resumen.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../utils/formato.dart';
import '../../common/filtros/filtros.dart';

class LimiteElegido {
  final int idCliente;
  final String nombreCliente;
  final int limiteCredito;

  const LimiteElegido({
    required this.idCliente,
    required this.nombreCliente,
    required this.limiteCredito,
  });
}

class EditarLimiteDialog extends StatefulWidget {
  final CuentaCorrienteResumen? cliente;
  final List<OpcionFiltro> clientesCatalogo;
  final Map<int, CuentaCorrienteResumen> cuentasExistentes;

  const EditarLimiteDialog({
    super.key,
    this.cliente,
    this.clientesCatalogo = const [],
    this.cuentasExistentes = const {},
  });

  static Future<LimiteElegido?> mostrar(
    BuildContext context, {
    CuentaCorrienteResumen? cliente,
    List<OpcionFiltro> clientesCatalogo = const [],
    Map<int, CuentaCorrienteResumen> cuentasExistentes = const {},
  }) {
    return showDialog<LimiteElegido>(
      context: context,
      builder: (_) => EditarLimiteDialog(
        cliente: cliente,
        clientesCatalogo: clientesCatalogo,
        cuentasExistentes: cuentasExistentes,
      ),
    );
  }

  @override
  State<EditarLimiteDialog> createState() => _EditarLimiteDialogState();
}

class _EditarLimiteDialogState extends State<EditarLimiteDialog> {
  static const List<int> _sugeridos = [50000, 100000, 200000, 500000];

  final _limiteCtrl = TextEditingController();
  String? _idSeleccionado;

  bool get _modoNuevo => widget.cliente == null;

  CuentaCorrienteResumen? get _cuentaActual {
    final fija = widget.cliente;
    if (fija != null) return fija;
    final id = int.tryParse(_idSeleccionado ?? '');
    return id == null ? null : widget.cuentasExistentes[id];
  }

  int? get _idCliente => widget.cliente?.idCliente ?? int.tryParse(_idSeleccionado ?? '');

  String get _nombreCliente {
    final fija = widget.cliente;
    if (fija != null) return fija.nombreMostrado;
    for (final o in widget.clientesCatalogo) {
      if (o.id == _idSeleccionado) return o.etiqueta;
    }
    return '';
  }

  int get _saldoUsado => _cuentaActual?.saldoUsado ?? 0;
  int? get _limite => int.tryParse(_limiteCtrl.text.trim());

  @override
  void initState() {
    super.initState();
    final actual = widget.cliente;
    if (actual != null) _limiteCtrl.text = '${actual.limiteCredito}';
  }

  @override
  void dispose() {
    _limiteCtrl.dispose();
    super.dispose();
  }

  void _seleccionar(String? id) {
    setState(() {
      _idSeleccionado = id;
      final existente = _cuentaActual;
      _limiteCtrl.text = existente == null ? '' : '${existente.limiteCredito}';
    });
  }

  void _usarSugerido(int monto) {
    setState(() {
      _limiteCtrl.value = TextEditingValue(
        text: '$monto',
        selection: TextSelection.collapsed(offset: '$monto'.length),
      );
    });
  }

  String? get _error {
    final limite = _limite;
    if (limite == null) return null;
    if (limite < _saldoUsado) {
      return 'No puede ser menor a lo que el cliente ya debe (${formatMoneda(_saldoUsado)}).';
    }
    return null;
  }

  bool get _valido {
    final limite = _limite;
    if (_idCliente == null || limite == null || _error != null) return false;
    final actual = _cuentaActual;
    return actual == null || actual.limiteCredito != limite;
  }

  void _confirmar() {
    final id = _idCliente;
    final limite = _limite;
    if (!_valido || id == null || limite == null) return;
    Navigator.of(context).pop(LimiteElegido(
      idCliente: id,
      nombreCliente: _nombreCliente,
      limiteCredito: limite,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final actual = _cuentaActual;
    final limite = _limite;
    final disponible = limite == null ? null : limite - _saldoUsado;
    final hayCliente = _idCliente != null;
    final movil = Responsive.isMobileContext(context);
    final ancho = movil ? math.min(420.0, MediaQuery.sizeOf(context).width - 64) : 420.0;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: movil
          ? const EdgeInsets.symmetric(horizontal: 16, vertical: 24)
          : const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      titlePadding: movil ? const EdgeInsets.fromLTRB(16, 20, 16, 0) : const EdgeInsets.fromLTRB(24, 22, 24, 0),
      contentPadding: movil ? const EdgeInsets.fromLTRB(16, 16, 16, 12) : null,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.orange.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.tune_rounded, size: 20, color: AppColors.orange),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _modoNuevo ? 'Asignar límite de crédito' : 'Editar límite de crédito',
              style: AppTextStyles.title.copyWith(fontSize: movil ? 17 : 18),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: ancho,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_modoNuevo) ...[
                const SizedBox(height: 4),
                FiltroBuscable(
                  etiqueta: 'Cliente',
                  icono: Icons.person_pin_circle_outlined,
                  opciones: widget.clientesCatalogo,
                  seleccion: _idSeleccionado,
                  hint: 'Elegí un cliente',
                  obligatorio: true,
                  ancho: ancho,
                  habilitado: widget.clientesCatalogo.isNotEmpty,
                  onCambio: _seleccionar,
                ),
                if (widget.clientesCatalogo.isEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'No se pudo cargar el listado de clientes.',
                    style: AppTextStyles.footer.copyWith(color: AppColors.error),
                  ),
                ],
              ] else
                Text(
                  widget.cliente!.nombreMostrado,
                  style: AppTextStyles.label.copyWith(fontSize: 15),
                ),
              if (hayCliente) ...[
                const SizedBox(height: 14),
                _ResumenActual(cuenta: actual),
              ],
              const SizedBox(height: 16),
              TextField(
                controller: _limiteCtrl,
                enabled: hayCliente,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _confirmar(),
                cursorColor: AppColors.orange,
                style: AppTextStyles.title.copyWith(fontSize: 22),
                decoration: InputDecoration(
                  labelText: 'Nuevo límite',
                  prefixText: '\$ ',
                  isDense: true,
                  errorText: _error,
                  errorMaxLines: 2,
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.inputBorder),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.orange),
                  ),
                  floatingLabelStyle: const TextStyle(color: AppColors.orange),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final monto in _sugeridos)
                    ChoiceChip(
                      label: Text(formatMoneda(monto)),
                      selected: limite == monto,
                      onSelected: hayCliente && monto >= _saldoUsado ? (_) => _usarSugerido(monto) : null,
                      selectedColor: AppColors.orange.withOpacity(0.16),
                      backgroundColor: AppColors.background,
                      side: BorderSide(
                        color: limite == monto ? AppColors.orange : AppColors.inputBorder,
                      ),
                      labelStyle: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: limite == monto ? AppColors.orange : AppColors.steelBlue,
                      ),
                      showCheckmark: false,
                    ),
                ],
              ),
              if (disponible != null && _error == null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.steelBlue.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.account_balance_wallet_outlined, size: 18, color: AppColors.steelBlue),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          limite == 0
                              ? 'Con límite \$0 el chofer no va a poder cargar nada en Cuenta Corriente.'
                              : 'El chofer va a poder cargar hasta ${formatMoneda(disponible)} en Cuenta Corriente.',
                          style: AppTextStyles.link.copyWith(fontSize: 12.5, color: AppColors.steelBlue),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
            'Guardar límite',
            style: AppTextStyles.button.copyWith(
              color: _valido ? AppColors.orange : AppColors.badgeGray,
            ),
          ),
        ),
      ],
    );
  }
}

class _ResumenActual extends StatelessWidget {
  final CuentaCorrienteResumen? cuenta;

  const _ResumenActual({required this.cuenta});

  @override
  Widget build(BuildContext context) {
    final c = cuenta;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: c == null
          ? Text(
              'Este cliente todavía no tiene cuenta corriente: se abre con el límite que definas.',
              style: AppTextStyles.link.copyWith(fontSize: 12.5),
            )
          : Row(
              children: [
                Expanded(child: _Dato(etiqueta: 'Límite actual', valor: formatMoneda(c.limiteCredito))),
                const SizedBox(width: 8),
                Expanded(child: _Dato(etiqueta: 'Debe', valor: formatMoneda(c.saldoUsado))),
                const SizedBox(width: 8),
                Expanded(
                  child: _Dato(
                    etiqueta: 'Disponible',
                    valor: formatMoneda(c.limiteCredito - c.saldoUsado),
                    acento: c.limiteCredito - c.saldoUsado > 0 ? AppColors.badgeGreen : AppColors.error,
                  ),
                ),
              ],
            ),
    );
  }
}

class _Dato extends StatelessWidget {
  final String etiqueta;
  final String valor;
  final Color? acento;

  const _Dato({required this.etiqueta, required this.valor, this.acento});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(etiqueta, style: const TextStyle(fontSize: 10.5, color: AppColors.graphiteGray)),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            valor,
            maxLines: 1,
            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: acento ?? AppColors.steelBlue),
          ),
        ),
      ],
    );
  }
}
