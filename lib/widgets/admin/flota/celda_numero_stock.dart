import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

class CeldaNumeroStock extends StatefulWidget {
  final int valor;
  final Color acento;
  final bool enabled;
  final ValueChanged<int> onChanged;

  const CeldaNumeroStock({
    super.key,
    required this.valor,
    required this.acento,
    required this.enabled,
    required this.onChanged,
  });

  @override
  State<CeldaNumeroStock> createState() => _CeldaNumeroStockState();
}

class _CeldaNumeroStockState extends State<CeldaNumeroStock> {
  late final TextEditingController _ctrl;
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: '${widget.valor}');
    _focus = FocusNode();
    _focus.addListener(() {
      if (!_focus.hasFocus) _sincronizar();
    });
  }

  @override
  void didUpdateWidget(covariant CeldaNumeroStock old) {
    super.didUpdateWidget(old);
    if (!_focus.hasFocus && widget.valor != int.tryParse(_ctrl.text)) {
      _ctrl.text = '${widget.valor}';
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _sincronizar() {
    final parsed = int.tryParse(_ctrl.text.trim());
    final valor = (parsed == null || parsed < 0) ? 0 : parsed;
    _ctrl.text = '$valor';
    widget.onChanged(valor);
  }

  void _sumar(int delta) {
    final nuevo = widget.valor + delta;
    final valor = nuevo < 0 ? 0 : nuevo;
    _ctrl.text = '$valor';
    widget.onChanged(valor);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: widget.valor > 0 ? widget.acento.withOpacity(0.08) : AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: widget.valor > 0 ? widget.acento.withOpacity(0.6) : AppColors.inputBorder,
        ),
      ),
      child: Row(
        children: [
          _Mini(icono: Icons.remove, onTap: widget.enabled ? () => _sumar(-1) : null),
          Expanded(
            child: TextField(
              controller: _ctrl,
              focusNode: _focus,
              enabled: widget.enabled,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: AppTextStyles.label.copyWith(fontSize: 15),
              cursorColor: widget.acento,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
              ),
              onSubmitted: (_) => _sincronizar(),
              onEditingComplete: _sincronizar,
            ),
          ),
          _Mini(icono: Icons.add, acento: widget.acento, onTap: widget.enabled ? () => _sumar(1) : null),
        ],
      ),
    );
  }
}

class _Mini extends StatelessWidget {
  final IconData icono;
  final Color? acento;
  final VoidCallback? onTap;

  const _Mini({required this.icono, this.acento, this.onTap});

  @override
  Widget build(BuildContext context) {
    final habilitado = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 30,
        height: 40,
        alignment: Alignment.center,
        child: Icon(
          icono,
          size: 16,
          color: habilitado ? (acento ?? AppColors.graphiteGray) : AppColors.inputBorder,
        ),
      ),
    );
  }
}
