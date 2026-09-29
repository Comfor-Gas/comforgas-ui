import 'package:flutter/material.dart';
import '../../../models/producto_catalogo.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import 'celda_numero_stock.dart';
import 'planilla_stock_tabla.dart';

class PlanillaStockCompacta extends StatelessWidget {
  final List<ProductoCatalogo> productos;
  final List<ColumnaStock> columnas;
  final Map<String, Map<String, int>> valores;
  final void Function(String productoId, String columnaKey, int valor) onCambio;
  final bool enabled;

  const PlanillaStockCompacta({
    super.key,
    required this.productos,
    required this.columnas,
    required this.valores,
    required this.onCambio,
    this.enabled = true,
  });

  static const double _anchoMinimoCelda = 112;
  static const double _espacio = 10;

  static const TextStyle _thStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.4,
    color: AppColors.graphiteGray,
  );

  int _valor(String productoId, String key) => valores[productoId]?[key] ?? 0;

  int _totalColumna(String key) =>
      productos.fold(0, (a, p) => a + _valor(p.idProducto, key));

  int _totalFila(String productoId) => columnas
      .where((c) => c.cuentaTotal)
      .fold(0, (a, c) => a + _valor(productoId, c.key));

  int get _totalGeneral => columnas
      .where((c) => c.cuentaTotal)
      .fold(0, (a, c) => a + _totalColumna(c.key));

  double _anchoCelda(double disponible) {
    if (!disponible.isFinite || columnas.isEmpty) return _anchoMinimoCelda;
    final calculado = ((disponible + _espacio) / (_anchoMinimoCelda + _espacio)).floor();
    final maximo = columnas.length;
    final porFila = calculado < 1 ? 1 : (calculado > maximo ? maximo : calculado);
    return (disponible - _espacio * (porFila - 1)) / porFila;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final p in productos) ...[
          _buildProducto(p),
          const SizedBox(height: 10),
        ],
        _buildTotales(),
      ],
    );
  }

  Widget _buildProducto(ProductoCatalogo p) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(p.etiquetaKg, style: AppTextStyles.label.copyWith(fontSize: 14)),
              ),
              const SizedBox(width: 8),
              const Text('TOTAL', style: _thStyle),
              const SizedBox(width: 6),
              Text(
                '${_totalFila(p.idProducto)}',
                style: AppTextStyles.label.copyWith(fontSize: 15, color: AppColors.steelBlue),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final ancho = _anchoCelda(constraints.maxWidth);
              return Wrap(
                spacing: _espacio,
                runSpacing: _espacio,
                children: [
                  for (final c in columnas)
                    SizedBox(
                      width: ancho,
                      child: _buildCelda(p, c),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCelda(ProductoCatalogo p, ColumnaStock c) {
    final valor = _valor(p.idProducto, c.key);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          c.etiqueta.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: _thStyle.copyWith(color: c.color),
        ),
        const SizedBox(height: 6),
        if (c.editable)
          CeldaNumeroStock(
            valor: valor,
            acento: c.color,
            enabled: enabled,
            onChanged: (v) => onCambio(p.idProducto, c.key, v),
          )
        else
          Container(
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.inputBorder),
            ),
            child: Text(
              '$valor',
              style: AppTextStyles.label.copyWith(fontSize: 15, color: c.color),
            ),
          ),
      ],
    );
  }

  Widget _buildTotales() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(child: Text('TOTALES', style: _thStyle)),
              Text('$_totalGeneral', style: AppTextStyles.title.copyWith(fontSize: 17)),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              for (final c in columnas)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(c.etiqueta, style: AppTextStyles.footer.copyWith(color: AppColors.graphiteGray)),
                    const SizedBox(width: 6),
                    Text(
                      '${_totalColumna(c.key)}',
                      style: AppTextStyles.label.copyWith(fontSize: 14, color: c.color),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
