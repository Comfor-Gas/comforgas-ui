import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../models/dashboard/dashboard_kpis.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/formato.dart';
import '../../../utils/formato_dashboard.dart';
import 'kpi_card.dart';

class KpiCardsGrid extends StatelessWidget {
  final DashboardKpis kpis;

  const KpiCardsGrid({super.key, required this.kpis});

  List<Widget> _cards() {
    final agenda = kpis.agenda;
    final ventas = kpis.ventas;
    final comodatos = kpis.comodatos;
    final canjes = kpis.canjes;
    final top = kpis.ventasPorSucursal.isNotEmpty ? kpis.ventasPorSucursal.first : null;

    return [
      KpiCard(
        icono: Icons.event_available_outlined,
        acento: AppColors.orange,
        titulo: 'Cumplimiento de agendas',
        valor: formatPorcentaje(agenda.porcentajeCumplimiento),
        detalle: '${formatEntero(agenda.realizadas)} de ${formatEntero(agenda.programadas)} visitas realizadas',
        progreso: agenda.porcentajeCumplimiento / 100,
        secundarios: [
          KpiDatoSecundario(etiqueta: 'no asistió', valor: formatEntero(agenda.noAsistio)),
          KpiDatoSecundario(etiqueta: 'pendientes', valor: formatEntero(agenda.pendientes)),
          KpiDatoSecundario(etiqueta: 'canceladas', valor: formatEntero(agenda.canceladas)),
        ],
      ),
      KpiCard(
        icono: Icons.storefront_outlined,
        acento: AppColors.steelBlue,
        titulo: 'Ventas totales por sucursal',
        valor: formatMoneda(ventas.montoTotal),
        detalle: top == null
            ? 'Sin ventas en el período'
            : 'Mayor venta: ${top.nombre} (${formatMoneda(top.montoTotal)})',
        secundarios: [
          KpiDatoSecundario(etiqueta: 'sucursales', valor: formatEntero(kpis.sucursalesConVenta)),
          KpiDatoSecundario(etiqueta: 'ventas', valor: formatEntero(ventas.transacciones)),
          KpiDatoSecundario(etiqueta: 'ticket prom.', valor: formatMoneda(ventas.ticketPromedio)),
        ],
      ),
      KpiCard(
        icono: Icons.inventory_2_outlined,
        acento: AppColors.badgeBlue,
        titulo: 'Estado general de comodatos',
        valor: comodatos.auditorias == 0 ? 'Sin auditorías' : formatPorcentaje(comodatos.tasaConformidad),
        detalle: comodatos.auditorias == 0
            ? 'No hubo controles de comodato en el período'
            : '${formatEntero(comodatos.auditoriasConformes)} de ${formatEntero(comodatos.auditorias)} auditorías conformes',
        progreso: comodatos.auditorias == 0 ? null : comodatos.tasaConformidad / 100,
        secundarios: [
          KpiDatoSecundario(etiqueta: 'contratadas', valor: formatEntero(comodatos.totalContratado)),
          KpiDatoSecundario(etiqueta: 'contadas', valor: formatEntero(comodatos.totalAuditado)),
          KpiDatoSecundario(etiqueta: 'faltantes', valor: formatEntero(comodatos.discrepancias)),
        ],
      ),
      KpiCard(
        icono: Icons.swap_horiz,
        acento: AppColors.graphiteGray,
        titulo: 'Tasa de canjes defectuosos',
        valor: formatPorcentaje(canjes.tasaDefectuososPorcentaje, decimales: 2),
        detalle:
            '${formatEntero(canjes.totalCanjes)} canjes sobre ${formatEntero(ventas.volumenEntregado)} garrafas entregadas',
        secundarios: [
          KpiDatoSecundario(etiqueta: 'visitas con canje', valor: formatEntero(canjes.visitasConCanje)),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final cards = _cards();
    return LayoutBuilder(
      builder: (context, constraints) {
        final ancho = constraints.maxWidth;
        final columnas = ancho >= 1100 ? 4 : (ancho >= 560 ? 2 : 1);
        final filas = <Widget>[];
        for (var i = 0; i < cards.length; i += columnas) {
          final tramo = cards.sublist(i, math.min(i + columnas, cards.length));
          filas.add(
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var j = 0; j < columnas; j++) ...[
                    Expanded(child: j < tramo.length ? tramo[j] : const SizedBox.shrink()),
                    if (j < columnas - 1) const SizedBox(width: 14),
                  ],
                ],
              ),
            ),
          );
          if (i + columnas < cards.length) filas.add(const SizedBox(height: 14));
        }
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: filas);
      },
    );
  }
}
