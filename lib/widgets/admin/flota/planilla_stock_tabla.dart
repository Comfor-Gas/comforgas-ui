import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/producto_catalogo.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

class ColumnaStock {
  final String key;
  final String etiqueta;
  final Color color;
  final bool editable;
  final bool cuentaTotal;

  const ColumnaStock({
    required this.key,
    required this.etiqueta,
    required this.color,
    this.editable = true,
    this.cuentaTotal = true,
  });
}

class PlanillaStockTabla extends StatelessWidget {
  final List<ProductoCatalogo> productos;
  final List<ColumnaStock> columnas;
  final Map<String, Map<String, int>> valores;
  final void Function(String productoId, String columnaKey, int valor) onCambio;
  final bool enabled;

  const PlanillaStockTabla({
    super.key,
    required this.productos,
    required this.columnas,
    required this.valores,
    required this.onCambio,
    this.enabled = true,
  });

  int _valor(String productoId, String key) => valores[productoId]?[key] ?? 0;

  int _totalColumna(String key) =>
      productos.fold(0, (a, p) => a + _valor(p.idProducto, key));

  int _totalFila(String productoId) => columnas
      .where((c) => c.cuentaTotal)
      .fold(0, (a, c) => a + _valor(productoId, c.key));

  int get _totalGeneral => columnas
      .where((c) => c.cuentaTotal)
      .fold(0, (a, c) => a + _totalColumna(c.key));

  @override
  Widget build(BuildContext context) {
    final double anchoTabla = 120 + columnas.length * 118 + 64 + 32;
    final tabla = Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildEncabezado(),
          for (final p in productos) _buildFila(p),
          _buildTotales(),
        ],
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (anchoTabla <= constraints.maxWidth) {
          return Align(alignment: Alignment.center, child: tabla);
        }
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: tabla,
        );
      },
    );
  }

  Widget _buildEncabezado() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(13)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 120,
            child: Text('TIPO', style: _thStyle),
          ),
          for (final c in columnas)
            SizedBox(
              width: 118,
              child: Center(
                child: Text(c.etiqueta.toUpperCase(), style: _thStyle.copyWith(color: c.color)),
              ),
            ),
          SizedBox(
            width: 64,
            child: Center(child: Text('TOTAL', style: _thStyle)),
          ),
        ],
      ),
    );
  }

  Widget _buildFila(ProductoCatalogo p) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.inputBorder)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 120,
            child: Text(p.etiquetaKg, style: AppTextStyles.label.copyWith(fontSize: 13.5)),
          ),
          for (final c in columnas)
            SizedBox(
              width: 118,
              child: Center(
                child: c.editable
                    ? _CeldaNumero(
                        valor: _valor(p.idProducto, c.key),
                        acento: c.color,
                        enabled: enabled,
                        onChanged: (v) => onCambio(p.idProducto, c.key, v),
                      )
                    : Text(
                        '${_valor(p.idProducto, c.key)}',
                        style: AppTextStyles.label.copyWith(fontSize: 15, color: c.color),
                      ),
              ),
            ),
          SizedBox(
            width: 64,
            child: Center(
              child: Text(
                '${_totalFila(p.idProducto)}',
                style: AppTextStyles.label.copyWith(fontSize: 15, color: AppColors.steelBlue),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotales() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(13)),
        border: const Border(top: BorderSide(color: AppColors.inputBorder)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 120,
            child: Text('TOTALES', style: _thStyle),
          ),
          for (final c in columnas)
            SizedBox(
              width: 118,
              child: Center(
                child: Text(
                  '${_totalColumna(c.key)}',
                  style: AppTextStyles.label.copyWith(fontSize: 15, color: c.color),
                ),
              ),
            ),
          SizedBox(
            width: 64,
            child: Center(
              child: Text(
                '$_totalGeneral',
                style: AppTextStyles.title.copyWith(fontSize: 17),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const TextStyle _thStyle = TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.4,
    color: AppColors.graphiteGray,
  );
}

class _CeldaNumero extends StatefulWidget {
  final int valor;
  final Color acento;
  final bool enabled;
  final ValueChanged<int> onChanged;

  const _CeldaNumero({
    required this.valor,
    required this.acento,
    required this.enabled,
    required this.onChanged,
  });

  @override
  State<_CeldaNumero> createState() => _CeldaNumeroState();
}

class _CeldaNumeroState extends State<_CeldaNumero> {
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
  void didUpdateWidget(covariant _CeldaNumero old) {
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
