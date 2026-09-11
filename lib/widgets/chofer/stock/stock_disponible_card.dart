import 'package:flutter/material.dart';
import '../../../models/stock_camion.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

class StockDisponibleCard extends StatelessWidget {
  final StockCamion stock;

  const StockDisponibleCard({super.key, required this.stock});

  @override
  Widget build(BuildContext context) {
    final items = _agrupar();
    final totalLlenos = items.fold(0, (a, i) => a + i.llenos);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.orange.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.local_shipping_outlined, size: 20, color: AppColors.orange),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Disponible para vender / canjear',
                  style: AppTextStyles.label.copyWith(fontSize: 15, color: AppColors.orange),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Garrafas llenas cargadas en tu camión en este momento.',
            style: AppTextStyles.footer.copyWith(color: AppColors.graphiteGray),
          ),
          const SizedBox(height: 14),
          if (items.isEmpty)
            Text(
              'No hay stock cargado en tu camión.',
              style: AppTextStyles.input.copyWith(color: AppColors.graphiteGray),
            )
          else
            for (final it in items) _fila(it),
          const SizedBox(height: 6),
          const Divider(height: 20, color: AppColors.inputBorder),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Total llenos disponibles',
                  style: AppTextStyles.label.copyWith(fontSize: 14),
                ),
              ),
              Text(
                '$totalLlenos',
                style: AppTextStyles.title.copyWith(fontSize: 22, color: AppColors.orange),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _fila(_Agrupado it) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          const Icon(Icons.propane_tank_rounded, size: 20, color: AppColors.steelBlue),
          const SizedBox(width: 10),
          Expanded(
            child: Text(it.etiqueta, style: AppTextStyles.label.copyWith(fontSize: 14.5)),
          ),
          _Chip(valor: it.llenos, etiqueta: 'llenos', color: AppColors.orange),
          const SizedBox(width: 8),
          _Chip(valor: it.vacios, etiqueta: 'vacíos', color: AppColors.steelBlue),
        ],
      ),
    );
  }

  List<_Agrupado> _agrupar() {
    final mapa = <String, _Agrupado>{};
    for (final it in stock.items) {
      final key = it.productoId.isNotEmpty ? it.productoId : it.sku;
      final grupo = mapa.putIfAbsent(key, () => _Agrupado(_etiqueta(it)));
      if (it.esLlena) {
        grupo.llenos += it.cantidad;
      } else if (it.estadoCodigo.toUpperCase() == 'VACIA') {
        grupo.vacios += it.cantidad;
      }
    }
    final lista = mapa.values.toList();
    lista.sort((a, b) => _kg(a.etiqueta).compareTo(_kg(b.etiqueta)));
    return lista;
  }

  String _etiqueta(StockCamionItem it) {
    if (it.descripcion.isNotEmpty) return it.descripcion;
    final kg = _kgDe(it.sku) ?? _kgDe(it.productoId);
    return kg != null ? '$kg kg' : it.sku;
  }

  int _kg(String texto) => _kgDe(texto) ?? 0;

  int? _kgDe(String texto) {
    final match = RegExp(r'\d+').firstMatch(texto);
    return match != null ? int.tryParse(match.group(0)!) : null;
  }
}

class _Agrupado {
  final String etiqueta;
  int llenos = 0;
  int vacios = 0;

  _Agrupado(this.etiqueta);
}

class _Chip extends StatelessWidget {
  final int valor;
  final String etiqueta;
  final Color color;

  const _Chip({required this.valor, required this.etiqueta, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            '$valor',
            style: AppTextStyles.label.copyWith(fontSize: 15, color: color),
          ),
          Text(
            etiqueta,
            style: AppTextStyles.footer.copyWith(color: color, fontSize: 10.5),
          ),
        ],
      ),
    );
  }
}
