import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

class ContadorEnvases extends StatefulWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int? max;
  final bool enabled;

  const ContadorEnvases({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max,
    this.enabled = true,
  });

  @override
  State<ContadorEnvases> createState() => _ContadorEnvasesState();
}

class _ContadorEnvasesState extends State<ContadorEnvases> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.value}');
    _focusNode = FocusNode();
    _focusNode.addListener(_alCambiarFoco);
  }

  @override
  void didUpdateWidget(covariant ContadorEnvases oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value && !_focusNode.hasFocus) {
      _controller.text = '${widget.value}';
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_alCambiarFoco);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  bool get _puedeRestar => widget.enabled && widget.value > widget.min;
  bool get _puedeSumar =>
      widget.enabled && (widget.max == null || widget.value < widget.max!);

  int _acotar(int v) {
    var r = v;
    if (r < widget.min) r = widget.min;
    if (widget.max != null && r > widget.max!) r = widget.max!;
    return r;
  }

  void _emitir(int v) {
    final acotado = _acotar(v);
    if ('$acotado' != _controller.text) {
      _controller.value = TextEditingValue(
        text: '$acotado',
        selection: TextSelection.collapsed(offset: '$acotado'.length),
      );
    }
    if (acotado != widget.value) widget.onChanged(acotado);
  }

  void _alEscribir(String text) {
    if (text.isEmpty) return;
    final parsed = int.tryParse(text);
    if (parsed == null) return;
    _emitir(parsed);
  }

  void _alCambiarFoco() {
    if (_focusNode.hasFocus) return;
    final parsed = int.tryParse(_controller.text);
    final v = _acotar(parsed ?? widget.min);
    _controller.text = '$v';
    if (v != widget.value) widget.onChanged(v);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _BotonRedondo(
          icon: Icons.remove,
          onTap: _puedeRestar ? () => _emitir(widget.value - 1) : null,
        ),
        Container(
          width: 96,
          margin: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.inputBorder, width: 1.2),
          ),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            enabled: widget.enabled,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: AppTextStyles.title.copyWith(fontSize: 30),
            cursorColor: AppColors.orange,
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 10),
            ),
            onChanged: _alEscribir,
            onTapOutside: (_) => _focusNode.unfocus(),
            onSubmitted: (_) => _focusNode.unfocus(),
          ),
        ),
        _BotonRedondo(
          icon: Icons.add,
          onTap: _puedeSumar ? () => _emitir(widget.value + 1) : null,
        ),
      ],
    );
  }
}

class _BotonRedondo extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _BotonRedondo({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool activo = onTap != null;
    return Material(
      color: activo ? AppColors.orange : AppColors.badgeGray.withOpacity(0.4),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          height: 52,
          width: 52,
          child: Icon(
            icon,
            color: AppColors.white,
            size: 26,
          ),
        ),
      ),
    );
  }
}
