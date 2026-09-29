import 'package:flutter/material.dart';

import '../../../models/stock_rodante_chofer.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

class DetalleCargaNota extends StatefulWidget {
  final StockRodanteChofer? nota;

  const DetalleCargaNota({super.key, required this.nota});

  @override
  State<DetalleCargaNota> createState() => _DetalleCargaNotaState();
}

class _DetalleCargaNotaState extends State<DetalleCargaNota> {
  bool _abierta = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => setState(() => _abierta = !_abierta),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                const Icon(Icons.inventory_2_outlined, size: 15, color: AppColors.steelBlue),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Detalle de la carga del día por tipo',
                    style: AppTextStyles.footer.copyWith(
                      color: AppColors.steelBlue,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: _abierta ? 0.5 : 0,
                  duration: const Duration(milliseconds: 160),
                  child: const Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.graphiteGray),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 160),
          crossFadeState: _abierta ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          firstChild: Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 6),
            child: _TablaCarga(nota: widget.nota),
          ),
          secondChild: const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

class _TablaCarga extends StatelessWidget {
  final StockRodanteChofer? nota;

  const _TablaCarga({required this.nota});

  @override
  Widget build(BuildContext context) {
    final lineas = (nota?.ordenados ?? const <StockRodanteProducto>[])
        .where((l) =>
            l.llenosCargados > 0 || l.vaciosEnCamion > 0 || l.vaciosSalida > 0 || l.averiadosEnCamion > 0)
        .toList();
    if (lineas.isEmpty) {
      return Text(
        'El camión no tiene carga asignada hoy. Empieza en 0 hasta que le asignes su carga inicial.',
        style: AppTextStyles.footer.copyWith(color: AppColors.graphiteGray),
      );
    }
    final cerrada = nota?.cerrada ?? false;
    final hayAveriados = lineas.any((l) => l.averiadosEnCamion > 0);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Row(
              children: [
                const Expanded(flex: 4, child: _Celda('TIPO')),
                const Expanded(flex: 3, child: _Celda('CARGADAS', alinearFinal: true)),
                Expanded(flex: 3, child: _Celda(cerrada ? 'RETORNO LL.' : 'EN CAMIÓN', alinearFinal: true)),
                const Expanded(flex: 3, child: _Celda('VACÍAS', alinearFinal: true)),
                if (hayAveriados)
                  const Expanded(flex: 3, child: _Celda('AVERIADAS', alinearFinal: true)),
              ],
            ),
          ),
          for (final l in lineas) ...[
            const Divider(height: 1, color: AppColors.inputBorder),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Text('Garrafa ${l.etiqueta}', style: AppTextStyles.input.copyWith(fontSize: 13)),
                  ),
                  Expanded(flex: 3, child: _Numero(l.llenosCargados, AppColors.orange)),
                  Expanded(
                    flex: 3,
                    child: _Numero(cerrada ? l.llenosEntrada : l.disponiblesParaVenta, AppColors.orange),
                  ),
                  Expanded(flex: 3, child: _Numero(l.vaciosEnCamion, AppColors.steelBlue)),
                  if (hayAveriados)
                    Expanded(flex: 3, child: _Numero(l.averiadosEnCamion, AppColors.graphiteGray)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Numero extends StatelessWidget {
  final int valor;
  final Color color;

  const _Numero(this.valor, this.color);

  @override
  Widget build(BuildContext context) {
    return Text(
      '$valor',
      textAlign: TextAlign.right,
      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: color),
    );
  }
}

class _Celda extends StatelessWidget {
  final String texto;
  final bool alinearFinal;

  const _Celda(this.texto, {this.alinearFinal = false});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alinearFinal ? Alignment.centerRight : Alignment.centerLeft,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: alinearFinal ? Alignment.centerRight : Alignment.centerLeft,
        child: Text(
          texto,
          maxLines: 1,
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
            color: AppColors.graphiteGray,
          ),
        ),
      ),
    );
  }
}
