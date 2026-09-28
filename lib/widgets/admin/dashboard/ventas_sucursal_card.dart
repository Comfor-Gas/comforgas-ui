import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../models/dashboard/dashboard_kpis.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../utils/formato.dart';
import '../../../utils/formato_dashboard.dart';
import 'dashboard_card.dart';
import 'dashboard_paleta.dart';
import 'paginador_compacto.dart';

class VentasSucursalCard extends StatefulWidget {
  final List<VentaSucursal> sucursales;
  final bool cargando;
  final ValueChanged<VentaSucursal>? onSeleccionar;

  const VentasSucursalCard({
    super.key,
    required this.sucursales,
    this.cargando = false,
    this.onSeleccionar,
  });

  @override
  State<VentasSucursalCard> createState() => _VentasSucursalCardState();
}

class _VentasSucursalCardState extends State<VentasSucursalCard> {
  static const int _porPagina = 8;

  int _pagina = 0;

  @override
  void didUpdateWidget(covariant VentasSucursalCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.sucursales, widget.sucursales)) _pagina = 0;
  }

  @override
  Widget build(BuildContext context) {
    final sucursales = widget.sucursales;
    final cantidad = sucursales.length;
    final pagina = PaginadorCompacto.acotar(_pagina, _porPagina, cantidad);
    final inicio = pagina * _porPagina;
    final visibles = sucursales.sublist(inicio, math.min(inicio + _porPagina, cantidad));
    final maximo = sucursales.isEmpty ? 0.0 : sucursales.first.montoTotal;
    final total = sucursales.fold<double>(0, (a, s) => a + s.montoTotal);
    final onSeleccionar = widget.onSeleccionar;

    return DashboardCard(
      titulo: 'Ventas por sucursal',
      subtitulo: onSeleccionar != null
          ? 'Ranking por monto vendido · tocá una sucursal para filtrar'
          : 'Ranking por monto vendido',
      child: visibles.isEmpty
          ? const DashboardVacio(
              mensaje: 'No hay ventas registradas para los filtros elegidos.',
              icono: Icons.storefront_outlined,
            )
          : AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: widget.cargando ? 0.45 : 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < visibles.length; i++)
                    _FilaSucursal(
                      posicion: inicio + i + 1,
                      sucursal: visibles[i],
                      proporcion: maximo > 0 ? visibles[i].montoTotal / maximo : 0,
                      participacion: total > 0 ? visibles[i].montoTotal / total * 100 : 0,
                      onTap: onSeleccionar != null && visibles[i].idSucursal != null
                          ? () => onSeleccionar(visibles[i])
                          : null,
                    ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Total ${formatMoneda(total)} en ${formatEntero(cantidad)} sucursales',
                          style: AppTextStyles.footer.copyWith(color: AppColors.graphiteGray),
                        ),
                      ),
                      PaginadorCompacto(
                        pagina: pagina,
                        porPagina: _porPagina,
                        total: cantidad,
                        onCambio: (p) => setState(() => _pagina = p),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}

class _FilaSucursal extends StatefulWidget {
  final int posicion;
  final VentaSucursal sucursal;
  final double proporcion;
  final double participacion;
  final VoidCallback? onTap;

  const _FilaSucursal({
    required this.posicion,
    required this.sucursal,
    required this.proporcion,
    required this.participacion,
    this.onTap,
  });

  @override
  State<_FilaSucursal> createState() => _FilaSucursalState();
}

class _FilaSucursalState extends State<_FilaSucursal> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.sucursal;
    return Tooltip(
      message:
          '${s.nombre}\n${formatMoneda(s.montoTotal)} · ${formatPorcentaje(widget.participacion)} del total\n'
          '${formatEntero(s.cantidadVentas)} ventas · ${formatEntero(s.volumenEntregado)} garrafas',
      waitDuration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: DashboardPaleta.tooltipFondo,
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: DashboardPaleta.tooltipEtiqueta.copyWith(color: Colors.white),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        cursor: widget.onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 6),
            decoration: BoxDecoration(
              color: _hover ? AppColors.background : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 30,
                  child: Text(
                    '${widget.posicion}',
                    style: AppTextStyles.footer.copyWith(
                      color: AppColors.graphiteGray,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Flexible(
                  flex: 2,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 150),
                    child: SizedBox(
                      width: 150,
                      child: Text(
                        s.nombre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.label.copyWith(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 3,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final ancho = math.min(constraints.maxWidth, math.max(4.0, constraints.maxWidth * widget.proporcion));
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: ancho,
                          height: 14,
                          decoration: BoxDecoration(
                            color: _hover
                                ? DashboardPaleta.serieAzul
                                : DashboardPaleta.serieAzul.withOpacity(0.85),
                            borderRadius: const BorderRadius.horizontal(right: Radius.circular(4)),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 96,
                  child: Text(
                    formatMoneda(s.montoTotal),
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.steelBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
