import 'package:flutter/material.dart';
import '../../../core/responsive.dart';
import '../../../models/dashboard/dashboard_filtros.dart';
import '../../common/filtros/filtros.dart';

class DashboardFiltrosPanel extends StatelessWidget {
  final DashboardFiltros filtros;
  final List<OpcionFiltro> choferes;
  final List<OpcionFiltro> rutas;
  final List<OpcionFiltro> sucursales;
  final bool catalogosCargando;
  final String? catalogosError;
  final ValueChanged<DashboardFiltros> onCambio;
  final VoidCallback onRefrescar;
  final bool refrescando;

  const DashboardFiltrosPanel({
    super.key,
    required this.filtros,
    required this.choferes,
    required this.rutas,
    required this.sucursales,
    required this.onCambio,
    required this.onRefrescar,
    this.catalogosCargando = false,
    this.catalogosError,
    this.refrescando = false,
  });

  @override
  Widget build(BuildContext context) {
    return FiltrosPanel(
      aviso: catalogosError,
      filas: [
        SelectorRangoFechas(
          desde: filtros.desde,
          hasta: filtros.hasta,
          onCambio: (desde, hasta) {
            if (desde == null || hasta == null) return;
            onCambio(filtros.conRango(desde, hasta, RangoPreset.personalizado));
          },
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final movil = Responsive.isMobileContext(context);
            final double? anchoMovil = movil ? constraints.maxWidth : null;
            return FilaFiltros(
              children: [
                FiltroBuscable(
                  etiqueta: 'Chofer',
                  icono: Icons.person_outline,
                  opciones: choferes,
                  seleccion: filtros.idChofer,
                  habilitado: !catalogosCargando,
                  ancho: anchoMovil ?? 220.0,
                  onCambio: (id) => onCambio(filtros.conChofer(id)),
                ),
                FiltroBuscable(
                  etiqueta: 'Ruta',
                  icono: Icons.alt_route_outlined,
                  opciones: rutas,
                  seleccion: filtros.idRuta?.toString(),
                  habilitado: !catalogosCargando,
                  ancho: anchoMovil ?? 220.0,
                  onCambio: (id) => onCambio(filtros.conRuta(id == null ? null : int.tryParse(id))),
                ),
                FiltroBuscable(
                  etiqueta: 'Cliente',
                  icono: Icons.person_pin_circle_outlined,
                  opciones: sucursales,
                  seleccion: filtros.idSucursal?.toString(),
                  habilitado: !catalogosCargando,
                  ancho: anchoMovil ?? 260.0,
                  onCambio: (id) => onCambio(filtros.conSucursal(id == null ? null : int.tryParse(id))),
                ),
                if (filtros.tieneFiltrosDeEntidad)
                  BotonLimpiarFiltros(onPressed: () => onCambio(filtros.sinEntidades())),
                BotonActualizar(onPressed: onRefrescar, cargando: refrescando),
              ],
            );
          },
        ),
      ],
    );
  }
}
