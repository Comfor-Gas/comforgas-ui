import 'package:flutter/material.dart';
import '../../../models/venta_monitoreo.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../utils/date_format_utils.dart';
import '../../../utils/formato.dart';
import 'detalle_cilindros_resumen.dart';
import 'venta_estado_badge.dart';

class _Columna {
  final String titulo;
  final int flex;
  final Alignment alineacion;

  const _Columna(this.titulo, this.flex, [this.alineacion = Alignment.centerLeft]);
}

const List<_Columna> _columnas = [
  _Columna('ID Venta', 2),
  _Columna('Hora', 2),
  _Columna('Chofer', 3),
  _Columna('Cliente', 3),
  _Columna('Estado', 2, Alignment.center),
  _Columna('Detalle de Cilindros', 5),
  _Columna('Monto Total', 2, Alignment.centerRight),
];

class VentasTabla extends StatelessWidget {
  final List<VentaMonitoreo> ventas;
  final int? idSeleccionada;
  final ValueChanged<VentaMonitoreo> onSeleccionar;

  const VentasTabla({
    super.key,
    required this.ventas,
    required this.idSeleccionada,
    required this.onSeleccionar,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const minWidth = 720.0;
        final width =
            constraints.maxWidth.isFinite && constraints.maxWidth > minWidth
                ? constraints.maxWidth
                : minWidth;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: width,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                const _Encabezado(),
                if (ventas.isEmpty)
                  const _SinResultados()
                else
                  for (int i = 0; i < ventas.length; i++)
                    _Fila(
                      venta: ventas[i],
                      seleccionada: ventas[i].idVenta == idSeleccionada,
                      esPar: i.isEven,
                      onTap: () => onSeleccionar(ventas[i]),
                    ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Encabezado extends StatelessWidget {
  const _Encabezado();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.inputBorder, width: 1.4)),
      ),
      child: Row(
        children: [
          for (final columna in _columnas)
            Expanded(
              flex: columna.flex,
              child: Align(
                alignment: columna.alineacion,
                child: Text(
                  columna.titulo,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                    color: AppColors.graphiteGray,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Fila extends StatefulWidget {
  final VentaMonitoreo venta;
  final bool seleccionada;
  final bool esPar;
  final VoidCallback onTap;

  const _Fila({
    required this.venta,
    required this.seleccionada,
    required this.esPar,
    required this.onTap,
  });

  @override
  State<_Fila> createState() => _FilaState();
}

class _FilaState extends State<_Fila> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final venta = widget.venta;

    Color fondo;
    if (widget.seleccionada) {
      fondo = AppColors.orange.withOpacity(0.08);
    } else if (_hover) {
      fondo = AppColors.steelBlue.withOpacity(0.05);
    } else {
      fondo = widget.esPar ? AppColors.white : AppColors.background.withOpacity(0.5);
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: fondo,
            border: Border(
              left: BorderSide(
                color: widget.seleccionada ? AppColors.orange : Colors.transparent,
                width: 3,
              ),
              bottom: const BorderSide(color: AppColors.inputBorder, width: 0.7),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: _columnas[0].flex,
                child: Text(
                  '#${venta.idVenta}',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.steelBlue,
                  ),
                ),
              ),
              Expanded(
                flex: _columnas[1].flex,
                child: Text(
                  venta.timestamp != null ? formatHora12(venta.timestamp!) : '—',
                  style: const TextStyle(fontSize: 13, color: AppColors.graphiteGray),
                ),
              ),
              Expanded(
                flex: _columnas[2].flex,
                child: Text(
                  venta.choferNombre,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.steelBlue,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                flex: _columnas[3].flex,
                child: Text(
                  venta.clienteNombre,
                  style: const TextStyle(fontSize: 13, color: AppColors.graphiteGray),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                flex: _columnas[4].flex,
                child: Align(
                  alignment: Alignment.center,
                  child: VentaEstadoBadge(estado: venta.estado),
                ),
              ),
              Expanded(
                flex: _columnas[5].flex,
                child: DetalleCilindrosResumen(detalles: venta.detalles),
              ),
              Expanded(
                flex: _columnas[6].flex,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    formatMoneda(venta.montoTotal),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.steelBlue,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SinResultados extends StatelessWidget {
  const _SinResultados();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 40, color: AppColors.inputHint.withOpacity(0.7)),
          const SizedBox(height: 12),
          Text(
            'No hay ventas que coincidan con los filtros.',
            style: AppTextStyles.desktopSubtitle,
          ),
        ],
      ),
    );
  }
}
