import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/responsive.dart';
import '../../../models/dashboard/dashboard_kpis.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../utils/formato.dart';
import '../../../utils/formato_dashboard.dart';
import 'chofer_resumen_tile.dart';
import 'dashboard_card.dart';
import 'paginador_compacto.dart';

enum _ColumnaChofer { nombre, visitas, cumplimiento, efectividad, recupero, monto }

class DesgloseChoferesTabla extends StatefulWidget {
  final List<KpiChofer> choferes;
  final bool cargando;

  const DesgloseChoferesTabla({super.key, required this.choferes, this.cargando = false});

  @override
  State<DesgloseChoferesTabla> createState() => _DesgloseChoferesTablaState();
}

class _DesgloseChoferesTablaState extends State<DesgloseChoferesTabla> {
  _ColumnaChofer _orden = _ColumnaChofer.monto;
  bool _descendente = true;
  int _pagina = 0;

  static const int _porPagina = 10;

  @override
  void didUpdateWidget(covariant DesgloseChoferesTabla oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.choferes, widget.choferes)) _pagina = 0;
  }

  List<KpiChofer> get _ordenados {
    final lista = List<KpiChofer>.of(widget.choferes);
    int comparar(KpiChofer a, KpiChofer b) {
      switch (_orden) {
        case _ColumnaChofer.nombre:
          return a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase());
        case _ColumnaChofer.visitas:
          return a.realizadas.compareTo(b.realizadas);
        case _ColumnaChofer.cumplimiento:
          return a.porcentajeCumplimiento.compareTo(b.porcentajeCumplimiento);
        case _ColumnaChofer.efectividad:
          return a.efectividadVenta.compareTo(b.efectividadVenta);
        case _ColumnaChofer.recupero:
          return a.tasaRecupero.compareTo(b.tasaRecupero);
        case _ColumnaChofer.monto:
          return a.montoTotal.compareTo(b.montoTotal);
      }
    }

    lista.sort((a, b) => _descendente ? comparar(b, a) : comparar(a, b));
    return lista;
  }

  void _ordenar(_ColumnaChofer columna) {
    setState(() {
      if (_orden == columna) {
        _descendente = !_descendente;
      } else {
        _orden = columna;
        _descendente = columna != _ColumnaChofer.nombre;
      }
      _pagina = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final todas = _ordenados;
    final pagina = PaginadorCompacto.acotar(_pagina, _porPagina, todas.length);
    final inicio = pagina * _porPagina;
    final filas = todas.sublist(inicio, math.min(inicio + _porPagina, todas.length));
    final movil = Responsive.isMobileContext(context);
    return DashboardCard(
      titulo: 'Rendimiento por chofer',
      subtitulo: movil ? 'Elegí el criterio para ordenar' : 'Tocá un encabezado para ordenar',
      accion: movil && filas.isNotEmpty
          ? _SelectorOrdenMovil(orden: _orden, descendente: _descendente, onOrdenar: _ordenar)
          : null,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
      child: filas.isEmpty
          ? const DashboardVacio(
              mensaje: 'No hay choferes con visitas para los filtros elegidos.',
              icono: Icons.person_outline,
              alto: 140,
            )
          : AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: widget.cargando ? 0.45 : 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (movil)
                    DecoratedBox(
                      decoration: const BoxDecoration(
                        border: Border(top: BorderSide(color: AppColors.inputBorder, width: 0.6)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (var i = 0; i < filas.length; i++)
                            ChoferResumenTile(chofer: filas[i], alterna: i.isOdd),
                        ],
                      ),
                    )
                  else
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final ancho = constraints.maxWidth < 760 ? 760.0 : constraints.maxWidth;
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(
                            width: ancho,
                            child: Column(
                              children: [
                                _encabezado(),
                                for (var i = 0; i < filas.length; i++) _fila(filas[i], i.isOdd),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  if (todas.length > _porPagina)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: PaginadorCompacto(
                          pagina: pagina,
                          porPagina: _porPagina,
                          total: todas.length,
                          unidad: 'choferes',
                          onCambio: (p) => setState(() => _pagina = p),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _encabezado() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
      ),
      child: Row(
        children: [
          _th('Chofer', _ColumnaChofer.nombre, flex: 4, alinearDerecha: false),
          _th('Visitas', _ColumnaChofer.visitas, flex: 2),
          _th('Cumplimiento', _ColumnaChofer.cumplimiento, flex: 2),
          _th('Efect. venta', _ColumnaChofer.efectividad, flex: 2),
          _th('Recupero', _ColumnaChofer.recupero, flex: 2),
          _th('Monto', _ColumnaChofer.monto, flex: 3),
        ],
      ),
    );
  }

  Widget _th(String texto, _ColumnaChofer columna, {required int flex, bool alinearDerecha = true}) {
    final activo = _orden == columna;
    return Expanded(
      flex: flex,
      child: InkWell(
        onTap: () => _ordenar(columna),
        child: Row(
          mainAxisAlignment: alinearDerecha ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            Flexible(
              child: Text(
                texto.toUpperCase(),
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.footer.copyWith(
                  letterSpacing: 0.5,
                  fontWeight: FontWeight.w700,
                  color: activo ? AppColors.orange : AppColors.graphiteGray,
                ),
              ),
            ),
            if (activo)
              Icon(
                _descendente ? Icons.arrow_downward : Icons.arrow_upward,
                size: 13,
                color: AppColors.orange,
              ),
          ],
        ),
      ),
    );
  }

  Widget _fila(KpiChofer c, bool alterna) {
    TextStyle estilo({bool fuerte = false}) => TextStyle(
          fontSize: 13,
          fontWeight: fuerte ? FontWeight.w800 : FontWeight.w500,
          color: AppColors.steelBlue,
        );
    Widget celda(String texto, int flex, {bool fuerte = false}) => Expanded(
          flex: flex,
          child: Text(texto, textAlign: TextAlign.right, style: estilo(fuerte: fuerte)),
        );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: alterna ? AppColors.background.withOpacity(0.5) : AppColors.white,
        border: const Border(bottom: BorderSide(color: AppColors.inputBorder, width: 0.6)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              c.nombre,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: estilo(fuerte: true),
            ),
          ),
          celda('${formatEntero(c.realizadas)} / ${formatEntero(c.programadas)}', 2),
          celda(formatPorcentaje(c.porcentajeCumplimiento), 2),
          celda(formatPorcentaje(c.efectividadVenta), 2),
          celda(formatPorcentaje(c.tasaRecupero), 2),
          celda(formatMoneda(c.montoTotal), 3, fuerte: true),
        ],
      ),
    );
  }
}

String _etiquetaColumna(_ColumnaChofer columna) {
  switch (columna) {
    case _ColumnaChofer.nombre:
      return 'Chofer';
    case _ColumnaChofer.visitas:
      return 'Visitas';
    case _ColumnaChofer.cumplimiento:
      return 'Cumplimiento';
    case _ColumnaChofer.efectividad:
      return 'Efect. venta';
    case _ColumnaChofer.recupero:
      return 'Recupero';
    case _ColumnaChofer.monto:
      return 'Monto';
  }
}

class _SelectorOrdenMovil extends StatelessWidget {
  final _ColumnaChofer orden;
  final bool descendente;
  final ValueChanged<_ColumnaChofer> onOrdenar;

  const _SelectorOrdenMovil({required this.orden, required this.descendente, required this.onOrdenar});

  @override
  Widget build(BuildContext context) {
    final flecha = descendente ? Icons.arrow_downward : Icons.arrow_upward;
    return PopupMenuButton<_ColumnaChofer>(
      tooltip: 'Ordenar',
      position: PopupMenuPosition.under,
      color: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: onOrdenar,
      itemBuilder: (context) => [
        for (final columna in _ColumnaChofer.values)
          PopupMenuItem<_ColumnaChofer>(
            value: columna,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _etiquetaColumna(columna),
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: columna == orden ? FontWeight.w700 : FontWeight.w500,
                      color: columna == orden ? AppColors.orange : AppColors.steelBlue,
                    ),
                  ),
                ),
                if (columna == orden) Icon(flecha, size: 14, color: AppColors.orange),
              ],
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.inputBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sort, size: 16, color: AppColors.graphiteGray),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                'Ordenar: ${_etiquetaColumna(orden)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.steelBlue,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(flecha, size: 14, color: AppColors.orange),
          ],
        ),
      ),
    );
  }
}
