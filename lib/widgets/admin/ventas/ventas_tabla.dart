import 'package:flutter/material.dart';
import '../../../models/venta_monitoreo.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../utils/date_format_utils.dart';
import '../../../utils/formato.dart';
import 'detalle_cilindros_resumen.dart';
import 'venta_estado_badge.dart';

const double _wId = 66;
const double _wHora = 74;
const double _wEstado = 116;
const double _wMonto = 96;
const int _flexChofer = 2;
const int _flexCliente = 3;
const int _flexDetalle = 4;
const double _compactBreakpoint = 640;

const TextStyle _headerStyle = TextStyle(
  fontSize: 12,
  fontWeight: FontWeight.w800,
  letterSpacing: 0.3,
  color: AppColors.graphiteGray,
);

class VentasTabla extends StatelessWidget {
  final List<VentaMonitoreo> ventas;
  final int? idSeleccionada;
  final ValueChanged<VentaMonitoreo> onSeleccionar;
  final String mensajeVacio;

  const VentasTabla({
    super.key,
    required this.ventas,
    required this.idSeleccionada,
    required this.onSeleccionar,
    this.mensajeVacio = 'No hay ventas para mostrar.',
  });

  @override
  Widget build(BuildContext context) {
    if (ventas.isEmpty) return _SinResultados(mensaje: mensajeVacio);

    return LayoutBuilder(
      builder: (context, constraints) {
        return constraints.maxWidth < _compactBreakpoint
            ? _buildCompact()
            : _buildTabla();
      },
    );
  }

  Widget _buildTabla() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const _EncabezadoTabla(),
        for (int i = 0; i < ventas.length; i++)
          _FilaTabla(
            venta: ventas[i],
            seleccionada: ventas[i].idVenta == idSeleccionada,
            esPar: i.isEven,
            onTap: () => onSeleccionar(ventas[i]),
          ),
      ],
    );
  }

  Widget _buildCompact() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < ventas.length; i++)
          Padding(
            padding: EdgeInsets.only(
              top: i == 0 ? 4 : 0,
              bottom: i == ventas.length - 1 ? 4 : 10,
            ),
            child: _TarjetaVenta(
              venta: ventas[i],
              seleccionada: ventas[i].idVenta == idSeleccionada,
              onTap: () => onSeleccionar(ventas[i]),
            ),
          ),
      ],
    );
  }
}

class _EncabezadoTabla extends StatelessWidget {
  const _EncabezadoTabla();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.inputBorder, width: 1.4)),
      ),
      child: Row(
        children: const [
          SizedBox(width: _wId, child: Text('ID', style: _headerStyle)),
          SizedBox(width: _wHora, child: Text('HORA', style: _headerStyle)),
          Expanded(flex: _flexChofer, child: Text('CHOFER', style: _headerStyle)),
          Expanded(flex: _flexCliente, child: Text('CLIENTE', style: _headerStyle)),
          SizedBox(
            width: _wEstado,
            child: Center(child: Text('ESTADO', style: _headerStyle)),
          ),
          Expanded(flex: _flexDetalle, child: Text('DETALLE DE CILINDROS', style: _headerStyle)),
          SizedBox(
            width: _wMonto,
            child: Align(alignment: Alignment.centerRight, child: Text('MONTO', style: _headerStyle)),
          ),
        ],
      ),
    );
  }
}

class _FilaTabla extends StatefulWidget {
  final VentaMonitoreo venta;
  final bool seleccionada;
  final bool esPar;
  final VoidCallback onTap;

  const _FilaTabla({
    required this.venta,
    required this.seleccionada,
    required this.esPar,
    required this.onTap,
  });

  @override
  State<_FilaTabla> createState() => _FilaTablaState();
}

class _FilaTablaState extends State<_FilaTabla> {
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
              SizedBox(
                width: _wId,
                child: Text(
                  '#${venta.idVenta}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.steelBlue,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(
                width: _wHora,
                child: Text(
                  venta.timestamp != null ? formatHora12(venta.timestamp!) : '—',
                  style: const TextStyle(fontSize: 12.5, color: AppColors.graphiteGray),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                flex: _flexChofer,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
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
              ),
              Expanded(
                flex: _flexCliente,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    venta.clienteNombre,
                    style: const TextStyle(fontSize: 13, color: AppColors.graphiteGray),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              SizedBox(
                width: _wEstado,
                child: Center(child: VentaEstadoBadge(estado: venta.estado)),
              ),
              Expanded(
                flex: _flexDetalle,
                child: Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: DetalleCilindrosResumen(detalles: venta.detalles),
                ),
              ),
              SizedBox(
                width: _wMonto,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    formatMoneda(venta.montoTotal),
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.steelBlue,
                    ),
                    overflow: TextOverflow.ellipsis,
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

class _TarjetaVenta extends StatelessWidget {
  final VentaMonitoreo venta;
  final bool seleccionada;
  final VoidCallback onTap;

  const _TarjetaVenta({
    required this.venta,
    required this.seleccionada,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: seleccionada ? AppColors.orange.withOpacity(0.06) : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: seleccionada ? AppColors.orange : AppColors.inputBorder,
            width: seleccionada ? 1.4 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '#${venta.idVenta}',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.steelBlue,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  venta.timestamp != null ? formatHora12(venta.timestamp!) : '—',
                  style: const TextStyle(fontSize: 12.5, color: AppColors.graphiteGray),
                ),
                const Spacer(),
                VentaEstadoBadge(estado: venta.estado),
              ],
            ),
            const SizedBox(height: 10),
            _LineaCompacta(label: 'Chofer', valor: venta.choferNombre),
            const SizedBox(height: 4),
            _LineaCompacta(label: 'Cliente', valor: venta.clienteNombre),
            const SizedBox(height: 10),
            const Text('DETALLE DE CILINDROS', style: _headerStyle),
            const SizedBox(height: 6),
            DetalleCilindrosResumen(detalles: venta.detalles, compacto: false),
            const SizedBox(height: 12),
            Divider(color: AppColors.inputBorder, height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  'Monto Total',
                  style: AppTextStyles.desktopSubtitle.copyWith(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Text(
                  formatMoneda(venta.montoTotal),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LineaCompacta extends StatelessWidget {
  final String label;
  final String valor;

  const _LineaCompacta({required this.label, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 74,
          child: Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: AppColors.graphiteGray,
              letterSpacing: 0.4,
            ),
          ),
        ),
        Expanded(
          child: Text(
            valor,
            style: AppTextStyles.input.copyWith(fontSize: 13),
          ),
        ),
      ],
    );
  }
}

class _SinResultados extends StatelessWidget {
  final String mensaje;

  const _SinResultados({required this.mensaje});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 40, color: AppColors.inputHint.withOpacity(0.7)),
          const SizedBox(height: 12),
          Text(
            mensaje,
            textAlign: TextAlign.center,
            style: AppTextStyles.desktopSubtitle,
          ),
        ],
      ),
    );
  }
}
