import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/responsive.dart';
import '../../../models/dashboard/dashboard_kpis.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/formato.dart';
import '../../../utils/formato_dashboard.dart';
import 'dashboard_card.dart';
import 'dashboard_paleta.dart';
import 'escala_grafico.dart';
import 'paginador_compacto.dart';
import 'selector_segmentado.dart';

enum OrdenRutas { programadas, cumplimiento }

class CoberturaRutasChartCard extends StatefulWidget {
  final List<KpiRuta> rutas;
  final bool cargando;

  const CoberturaRutasChartCard({super.key, required this.rutas, this.cargando = false});

  @override
  State<CoberturaRutasChartCard> createState() => _CoberturaRutasChartCardState();
}

class _CoberturaRutasChartCardState extends State<CoberturaRutasChartCard> {
  static const int _porPagina = 8;
  static const int _porPaginaMovil = 5;
  static const double _anchoGrupo = 64;
  static const double _anchoGrupoMovil = 52;

  OrdenRutas _orden = OrdenRutas.programadas;
  int _pagina = 0;

  @override
  void didUpdateWidget(covariant CoberturaRutasChartCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.rutas, widget.rutas)) _pagina = 0;
  }

  List<KpiRuta> get _rutasOrdenadas {
    final lista = widget.rutas.where((r) => r.programadas > 0).toList();
    if (_orden == OrdenRutas.programadas) {
      lista.sort((a, b) => b.programadas.compareTo(a.programadas));
    } else {
      lista.sort((a, b) => a.porcentajeCumplimiento.compareTo(b.porcentajeCumplimiento));
    }
    return lista;
  }

  String _corto(String nombre, int maximo) =>
      nombre.length <= maximo ? nombre : '${nombre.substring(0, maximo - 1)}…';

  @override
  Widget build(BuildContext context) {
    final movil = Responsive.isMobileContext(context);
    final porPagina = movil ? _porPaginaMovil : _porPagina;
    final anchoGrupo = movil ? _anchoGrupoMovil : _anchoGrupo;
    final todas = _rutasOrdenadas;
    final total = todas.length;
    final pagina = PaginadorCompacto.acotar(_pagina, porPagina, total);
    final inicio = pagina * porPagina;
    final rutas = todas.sublist(inicio, math.min(inicio + porPagina, total));
    final maximo = todas.fold<int>(0, (a, r) => r.programadas > a ? r.programadas : a);
    return DashboardCard(
      titulo: 'Cobertura de rutas',
      subtitulo: 'Visitas programadas vs. realizadas por ruta',
      accion: SelectorSegmentado<OrdenRutas>(
        opciones: OrdenRutas.values,
        seleccion: _orden,
        etiqueta: (o) => o == OrdenRutas.programadas ? 'Más visitas' : 'Menor cumplimiento',
        onCambio: (o) => setState(() {
          _orden = o;
          _pagina = 0;
        }),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              LeyendaSerie(color: DashboardPaleta.serieAzul, etiqueta: 'Programadas'),
              LeyendaSerie(color: DashboardPaleta.serieNaranja, etiqueta: 'Realizadas'),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 260,
            child: rutas.isEmpty
                ? const DashboardVacio(
                    mensaje: 'No hay visitas programadas en rutas para los filtros elegidos.',
                    icono: Icons.alt_route_outlined,
                    alto: 260,
                  )
                : AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: widget.cargando ? 0.45 : 1,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final necesario = rutas.length * anchoGrupo + 60;
                        final ancho = necesario > constraints.maxWidth ? necesario : constraints.maxWidth;
                        final grafico = SizedBox(width: ancho, child: _grafico(rutas, maximo, movil ? 8 : 11));
                        if (ancho <= constraints.maxWidth) return grafico;
                        return SingleChildScrollView(scrollDirection: Axis.horizontal, child: grafico);
                      },
                    ),
                  ),
          ),
          if (total > porPagina) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: PaginadorCompacto(
                pagina: pagina,
                porPagina: porPagina,
                total: total,
                unidad: 'rutas',
                onCambio: (p) => setState(() => _pagina = p),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _grafico(List<KpiRuta> rutas, int maximo, int largoEtiqueta) {
    final escala = EscalaGrafico.para(maximo.toDouble(), entero: true);
    const radio = BorderRadius.vertical(top: Radius.circular(4));

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: escala.maximo,
        minY: 0,
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
              reservedSize: 40,
              interval: escala.intervalo,
              getTitlesWidget: (value, meta) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  formatEntero(value),
                  textAlign: TextAlign.right,
                  style: DashboardPaleta.ejeTexto,
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= rutas.length) return const SizedBox.shrink();
                final r = rutas[i];
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_corto(r.nombre, largoEtiqueta), style: DashboardPaleta.ejeTexto),
                      Text(
                        formatPorcentaje(r.porcentajeCumplimiento, decimales: 0),
                        style: DashboardPaleta.ejeTexto.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.steelBlue,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => DashboardPaleta.tooltipFondo,
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            maxContentWidth: 220,
            tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final r = rutas[group.x];
              return BarTooltipItem(
                '${formatPorcentaje(r.porcentajeCumplimiento)} cumplido',
                DashboardPaleta.tooltipValor,
                children: [
                  TextSpan(text: '\n${r.nombre}', style: DashboardPaleta.tooltipEtiqueta),
                  TextSpan(
                    text: '\n${formatEntero(r.realizadas)} realizadas de ${formatEntero(r.programadas)} programadas',
                    style: DashboardPaleta.tooltipEtiqueta,
                  ),
                  TextSpan(
                    text: '\n${formatEntero(r.volumenEntregado)} garrafas · ${formatMoneda(r.montoTotal)}',
                    style: DashboardPaleta.tooltipEtiqueta,
                  ),
                ],
              );
            },
          ),
        ),
        barGroups: [
          for (var i = 0; i < rutas.length; i++)
            BarChartGroupData(
              x: i,
              barsSpace: 3,
              barRods: [
                BarChartRodData(
                  toY: rutas[i].programadas.toDouble(),
                  color: DashboardPaleta.serieAzul,
                  width: 14,
                  borderRadius: radio,
                ),
                BarChartRodData(
                  toY: rutas[i].realizadas.toDouble(),
                  color: DashboardPaleta.serieNaranja,
                  width: 14,
                  borderRadius: radio,
                ),
              ],
            ),
        ],
      ),
      duration: const Duration(milliseconds: 250),
    );
  }
}
