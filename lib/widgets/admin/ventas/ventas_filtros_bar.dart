import 'package:flutter/material.dart';
import '../../../models/venta_monitoreo.dart';
import '../../common/filtros/filtros.dart';

class VentasFiltrosBar extends StatelessWidget {
  final TextEditingController choferController;
  final TextEditingController clienteController;
  final EstadoVentaMonitoreo? estadoSeleccionado;
  final ValueChanged<EstadoVentaMonitoreo?> onEstadoChanged;
  final DateTime fecha;
  final ValueChanged<DateTime> onFechaChanged;
  final VoidCallback onLimpiar;
  final VoidCallback onRefrescar;
  final bool cargando;

  const VentasFiltrosBar({
    super.key,
    required this.choferController,
    required this.clienteController,
    required this.estadoSeleccionado,
    required this.onEstadoChanged,
    required this.fecha,
    required this.onFechaChanged,
    required this.onLimpiar,
    required this.onRefrescar,
    this.cargando = false,
  });

  bool get _hayFiltros =>
      choferController.text.trim().isNotEmpty ||
      clienteController.text.trim().isNotEmpty ||
      estadoSeleccionado != null;

  @override
  Widget build(BuildContext context) {
    return FiltrosPanel(
      filas: [
        SelectorFechaUnica(
          etiqueta: 'Jornada',
          fecha: fecha,
          primera: DateTime(2023),
          ultima: DateTime(2100),
          onCambio: onFechaChanged,
        ),
        FilaFiltros(
          children: [
            CampoBusquedaFiltro(
              controller: choferController,
              etiqueta: 'Chofer',
              hint: 'Nombre del chofer',
              icono: Icons.person_outline,
              ancho: 240,
            ),
            CampoBusquedaFiltro(
              controller: clienteController,
              etiqueta: 'Cliente',
              hint: 'Nombre del cliente',
              icono: Icons.storefront_outlined,
              ancho: 240,
            ),
            FiltroBuscable(
              etiqueta: 'Estado',
              icono: Icons.filter_alt_outlined,
              hint: 'Todos los estados',
              opciones: [
                for (final estado in EstadoVentaMonitoreoMapper.filtrables)
                  OpcionFiltro(estado.name, estado.label),
              ],
              seleccion: estadoSeleccionado?.name,
              onCambio: (id) {
                EstadoVentaMonitoreo? estado;
                for (final e in EstadoVentaMonitoreoMapper.filtrables) {
                  if (e.name == id) estado = e;
                }
                onEstadoChanged(estado);
              },
            ),
            if (_hayFiltros) BotonLimpiarFiltros(onPressed: onLimpiar),
            BotonActualizar(onPressed: onRefrescar, cargando: cargando),
          ],
        ),
      ],
    );
  }
}
