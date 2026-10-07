import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/responsive.dart';
import '../../../models/dashboard/tendencia_punto.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/formato.dart';
import '../../../utils/formato_dashboard.dart';
import 'dashboard_card.dart';
import 'dashboard_paleta.dart';
import 'escala_grafico.dart';
import 'selector_segmentado.dart';

class TendenciaChartCard extends StatefulWidget {
  final List<TendenciaPunto> puntos;
  final bool cargando;
  final String? error;
  final VoidCallback? onReintentar;

  const TendenciaChartCard({
    super.key,
    required this.puntos,
    this.cargando = false,
    this.error,
    this.onReintentar,
  });

  @override
  State<TendenciaChartCard> createState() => _TendenciaChartCardState();
}

class _TendenciaChartCardState extends State<TendenciaChartCard> {
  MetricaTendencia _metrica = MetricaTendencia.ventas;

  String _valor(double v) {
    switch (_metrica) {
      case MetricaTendencia.ventas:
        return formatMoneda(v);
      case MetricaTendencia.garrafas:
        return '${formatEntero(v)} garrafas';
      case MetricaTendencia.cumplimiento:
        return formatPorcentaje(v);
    }
  }

  String _valorEje(double v) {
    switch (_metrica) {
      case MetricaTendencia.ventas:
        return formatMonedaCompacta(v);
      case MetricaTendencia.garrafas:
        return formatEntero(v);
      case MetricaTendencia.cumplimiento:
        return '${v.round()} %';
    }
  }

  String _periodo(TendenciaPunto p) =>
      p.esDiaUnico ? formatFechaDashboard(p.desde) : '${formatDiaMes(p.desde)} al ${formatDiaMes(p.hasta)}';

  String get _subtitulo {
    final puntos = widget.puntos;
    if (puntos.length < 2) return 'Evolución del período filtrado';
    return puntos.first.esDiaUnico ? 'Evolución diaria' : 'Evolución por tramos de ${puntos.first.hasta.difference(puntos.first.desde).inDays + 1} días';
  }

  @override
  Widget build(BuildContext context) {
    final movil = Responsive.isMobileContext(context);
    return DashboardCard(
      titulo: 'Tendencia comercial',
      subtitulo: _subtitulo,
      accion: SelectorSegmentado<MetricaTendencia>(
        opciones: MetricaTendencia.values,
        seleccion: _metrica,
        etiqueta: (m) => m.etiqueta,
        onCambio: (m) => setState(() => _metrica = m),
      ),
      child: SizedBox(height: movil ? 230 : 270, child: _contenido(movil)),
    );
  }

  Widget _contenido(bool movil) {
    if (widget.error != null && widget.puntos.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          DashboardVacio(mensaje: widget.error!, icono: Icons.cloud_off_outlined, alto: 150),
          if (widget.onReintentar != null)
            TextButton(
              onPressed: widget.onReintentar,
              child: const Text(
                'Reintentar',
                style: TextStyle(color: AppColors.orange, fontWeight: FontWeight.w700),
              ),
            ),
        ],
      );
    }
    if (widget.puntos.isEmpty && widget.cargando) {
      return const SizedBox.shrink();
    }
    if (widget.puntos.length < 2) {
      return const DashboardVacio(
        mensaje: 'Elegí un rango de al menos 2 días para ver la tendencia.',
        icono: Icons.show_chart,
      );
    }
    final valores = [for (final p in widget.puntos) p.valor(_metrica)];
    final maximoValor = valores.fold<double>(0, (a, v) => v > a ? v : a);
    if (maximoValor <= 0) {
      return const DashboardVacio(
        mensaje: 'No hubo movimientos en el período para esta métrica.',
        icono: Icons.show_chart,
      );
    }
    final escala = EscalaGrafico.para(
      maximoValor,
      tope: _metrica == MetricaTendencia.cumplimiento ? 100 : null,
      entero: _metrica == MetricaTendencia.garrafas,
    );
    final n = widget.puntos.length;
    final pasoEtiqueta = math.max(1, (n / (movil ? 4 : 7)).ceil());

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: widget.cargando ? 0.45 : 1,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (n - 1).toDouble(),
          minY: 0,
          maxY: escala.maximo,
          gridData: FlGridData(
            drawVerticalLine: false,
            horizontalInterval: escala.intervalo,
            getDrawingHorizontalLine: (_) => const FlLine(color: DashboardPaleta.grilla, strokeWidth: 1),
          ),
          borderData: FlBorderData(
            show: true,
            border: const Border(bottom: BorderSide(color: AppColors.inputBorder)),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 58,
                interval: escala.intervalo,
                getTitlesWidget: (value, meta) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    _valorEje(value),
                    textAlign: TextAlign.right,
                    style: DashboardPaleta.ejeTexto,
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final i = value.round();
                  if (i < 0 || i >= n || value != i.toDouble()) return const SizedBox.shrink();
                  if (i % pasoEtiqueta != 0 && i != n - 1) return const SizedBox.shrink();
                  if (i == n - 1 && i % pasoEtiqueta != 0 && (n - 1) % pasoEtiqueta < pasoEtiqueta / 2) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(formatDiaMes(widget.puntos[i].desde), style: DashboardPaleta.ejeTexto),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            handleBuiltInTouches: true,
            getTouchedSpotIndicator: (barData, indices) => [
              for (final _ in indices)
                TouchedSpotIndicatorData(
                  const FlLine(color: AppColors.badgeGray, strokeWidth: 1),
                  FlDotData(
                    getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                      radius: 6,
                      color: DashboardPaleta.serieNaranja,
                      strokeWidth: 2,
                      strokeColor: DashboardPaleta.superficie,
                    ),
                  ),
                ),
            ],
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => DashboardPaleta.tooltipFondo,
              fitInsideHorizontally: true,
              fitInsideVertically: true,
              maxContentWidth: 200,
              tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              getTooltipItems: (spots) => [
                for (final s in spots)
                  LineTooltipItem(
                    _valor(s.y),
                    DashboardPaleta.tooltipValor,
                    children: [
                      TextSpan(
                        text: '\n${_periodo(widget.puntos[s.x.round()])}',
                        style: DashboardPaleta.tooltipEtiqueta,
                      ),
                      if (_metrica == MetricaTendencia.cumplimiento)
                        TextSpan(
                          text:
                              '\n${widget.puntos[s.x.round()].realizadas} de ${widget.puntos[s.x.round()].programadas} visitas',
                          style: DashboardPaleta.tooltipEtiqueta,
                        ),
                    ],
                  ),
              ],
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: [for (var i = 0; i < n; i++) FlSpot(i.toDouble(), valores[i])],
              isCurved: true,
              curveSmoothness: 0.2,
              preventCurveOverShooting: true,
              color: DashboardPaleta.serieNaranja,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: n <= 31,
                getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                  radius: 4,
                  color: DashboardPaleta.serieNaranja,
                  strokeWidth: 2,
                  strokeColor: DashboardPaleta.superficie,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    DashboardPaleta.serieNaranja.withValues(alpha: 0.18),
                    DashboardPaleta.serieNaranja.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(milliseconds: 250),
      ),
    );
  }
}
