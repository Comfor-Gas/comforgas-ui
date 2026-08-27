import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

class CantidadStepper extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final IconData icono;
  final Color acento;
  final int valor;
  final ValueChanged<int> onChanged;
  final int minimo;
  final int maximo;
  final bool editable;

  const CantidadStepper({
    super.key,
    required this.titulo,
    required this.subtitulo,
    required this.icono,
    required this.acento,
    required this.valor,
    required this.onChanged,
    this.minimo = 0,
    this.maximo = 999,
    this.editable = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        children: [
          Text(
            titulo,
            style: AppTextStyles.label.copyWith(fontSize: 13),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StepButton(
                icono: Icons.remove,
                onTap: valor > minimo ? () => onChanged(valor - 1) : null,
              ),
              if (editable)
                Expanded(
                  child: _CampoNumero(
                    valor: valor,
                    minimo: minimo,
                    maximo: maximo,
                    acento: acento,
                    onChanged: onChanged,
                  ),
                )
              else
                Container(
                  width: 52,
                  alignment: Alignment.center,
                  child: Text(
                    '$valor',
                    style: AppTextStyles.title.copyWith(fontSize: 26),
                  ),
                ),
              _StepButton(
                icono: Icons.add,
                acento: acento,
                onTap: valor < maximo ? () => onChanged(valor + 1) : null,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Icon(icono, size: 28, color: acento),
          const SizedBox(height: 4),
          Text(
            subtitulo,
            style: AppTextStyles.footer.copyWith(color: acento, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _CampoNumero extends StatefulWidget {
  final int valor;
  final int minimo;
  final int maximo;
  final Color acento;
  final ValueChanged<int> onChanged;

  const _CampoNumero({
    required this.valor,
    required this.minimo,
    required this.maximo,
    required this.acento,
    required this.onChanged,
  });

  @override
  State<_CampoNumero> createState() => _CampoNumeroState();
}

class _CampoNumeroState extends State<_CampoNumero> {
  late final TextEditingController _ctrl;
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: '${widget.valor}');
    _focus = FocusNode();
    _focus.addListener(() {
      if (!_focus.hasFocus) _normalizar();
    });
  }

  @override
  void didUpdateWidget(covariant _CampoNumero oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_focus.hasFocus) return;
    if (int.tryParse(_ctrl.text) != widget.valor) {
      _ctrl.text = '${widget.valor}';
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged(String texto) {
    if (texto.isEmpty) {
      widget.onChanged(widget.minimo);
      return;
    }
    final parsed = int.tryParse(texto);
    if (parsed == null) return;
    final acotado = parsed.clamp(widget.minimo, widget.maximo);
    if ('$acotado' != texto) {
      _ctrl.value = TextEditingValue(
        text: '$acotado',
        selection: TextSelection.collapsed(offset: '$acotado'.length),
      );
    }
    widget.onChanged(acotado);
  }

  void _normalizar() {
    final acotado =
        (int.tryParse(_ctrl.text) ?? widget.minimo).clamp(widget.minimo, widget.maximo);
    _ctrl.text = '$acotado';
    widget.onChanged(acotado);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: TextField(
        controller: _ctrl,
        focusNode: _focus,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(4),
        ],
        onChanged: _onChanged,
        onTapOutside: (_) => _focus.unfocus(),
        style: AppTextStyles.title.copyWith(fontSize: 24),
        cursorColor: widget.acento,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 6),
          border: UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.inputBorder),
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.inputBorder),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: widget.acento, width: 1.6),
          ),
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icono;
  final VoidCallback? onTap;
  final Color? acento;

  const _StepButton({required this.icono, this.onTap, this.acento});

  @override
  Widget build(BuildContext context) {
    final habilitado = onTap != null;
    final fondo = acento ?? AppColors.steelBlue;

    return Material(
      color: habilitado ? fondo : AppColors.inputBorder,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            icono,
            color: habilitado ? AppColors.white : AppColors.inputHint,
            size: 22,
          ),
        ),
      ),
    );
  }
}
