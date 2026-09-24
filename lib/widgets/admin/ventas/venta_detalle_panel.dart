import 'package:flutter/material.dart';
import '../../../models/venta_monitoreo.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../utils/formato.dart';
import 'consistencia_badge.dart';
import 'venta_estado_badge.dart';

class VentaDetallePanel extends StatelessWidget {
  final VentaMonitoreo? venta;
  final bool scrollable;
  final VoidCallback? onRegistrarCobro;
  final bool registrandoCobro;

  const VentaDetallePanel({
    super.key,
    required this.venta,
    this.scrollable = true,
    this.onRegistrarCobro,
    this.registrandoCobro = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: venta == null
          ? const _PanelVacio()
          : _PanelContenido(
              venta: venta!,
              scrollable: scrollable,
              onRegistrarCobro: onRegistrarCobro,
              registrandoCobro: registrandoCobro,
            ),
    );
  }
}

class _PanelVacio extends StatelessWidget {
  const _PanelVacio();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 56),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long_outlined,
              size: 44, color: AppColors.inputHint.withOpacity(0.7)),
          const SizedBox(height: 14),
          Text(
            'Seleccioná una venta',
            style: AppTextStyles.label.copyWith(fontSize: 15),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Elegí una fila de la tabla para ver el desglose de cilindros entregados y retribuidos.',
            style: AppTextStyles.desktopSubtitle,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _PanelContenido extends StatelessWidget {
  final VentaMonitoreo venta;
  final bool scrollable;
  final VoidCallback? onRegistrarCobro;
  final bool registrandoCobro;

  const _PanelContenido({
    required this.venta,
    this.scrollable = true,
    this.onRegistrarCobro,
    this.registrandoCobro = false,
  });

  @override
  Widget build(BuildContext context) {
    const padding = EdgeInsets.fromLTRB(22, 22, 22, 24);
    final columna = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Detalle Venta', style: AppTextStyles.label),
              ),
              Text(
                '#${venta.idVenta}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _FilaDato(label: 'Chofer', valor: venta.choferNombre),
          _FilaDato(label: 'Cliente', valor: venta.clienteNombre),
          _FilaDato(label: 'Fecha/Hora', valor: _fechaHora(venta.timestamp)),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Estado',
                    style: AppTextStyles.desktopSubtitle.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                VentaEstadoBadge(estado: venta.estado),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const _Separador(),
          const SizedBox(height: 14),
          Text(
            'Artículos',
            style: AppTextStyles.label.copyWith(fontSize: 13.5),
          ),
          const SizedBox(height: 12),
          for (final detalle in venta.detalles) ...[
            _ArticuloCard(detalle: detalle),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 6),
          const _Separador(),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  'Venta Total',
                  style: AppTextStyles.label.copyWith(fontSize: 15),
                ),
              ),
              Text(
                formatMoneda(venta.montoTotal),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Center(child: ConsistenciaBadge(consistente: venta.consistente)),
          if (venta.estado == EstadoVentaMonitoreo.pendiente &&
              onRegistrarCobro != null) ...[
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: registrandoCobro ? null : onRegistrarCobro,
                icon: registrandoCobro
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2.2, color: AppColors.white),
                      )
                    : const Icon(Icons.attach_money, size: 20),
                label: const Text('Registrar cobro'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  foregroundColor: AppColors.white,
                  disabledBackgroundColor: AppColors.inputBorder,
                  disabledForegroundColor: AppColors.inputHint,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ],
    );

    if (!scrollable) {
      return Padding(padding: padding, child: columna);
    }
    return SingleChildScrollView(padding: padding, child: columna);
  }

  String _fechaHora(DateTime? fecha) {
    if (fecha == null) return '—';
    final d = fecha.day.toString().padLeft(2, '0');
    final m = fecha.month.toString().padLeft(2, '0');
    final y = fecha.year.toString().padLeft(4, '0');
    final hh = fecha.hour.toString().padLeft(2, '0');
    final mm = fecha.minute.toString().padLeft(2, '0');
    return '$d/$m/$y $hh:$mm';
  }
}

class _FilaDato extends StatelessWidget {
  final String label;
  final String valor;

  const _FilaDato({required this.label, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: AppTextStyles.desktopSubtitle.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 6,
            child: Text(
              valor,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.steelBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArticuloCard extends StatelessWidget {
  final DetalleVentaMonitoreo detalle;

  const _ArticuloCard({required this.detalle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  detalle.sku,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.steelBlue,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.orange.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  detalle.tipoLabel,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.orange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _LineaValor(
            label: 'Entregados (llenos)',
            valor: '${detalle.cantidadEntregada}',
            color: AppColors.badgeGreen,
          ),
          if (detalle.usaRecibidos)
            _LineaValor(
              label: 'Recibidos (vacíos)',
              valor: '${detalle.cantidadRecibida}',
              color: AppColors.badgeBlue,
            ),
          _LineaValor(
            label: 'Precio unitario',
            valor: formatMoneda(detalle.precioUnitario),
          ),
          const SizedBox(height: 6),
          Divider(color: AppColors.inputBorder, height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Subtotal',
                  style: AppTextStyles.desktopSubtitle.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                formatMoneda(detalle.subtotal),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.steelBlue,
                ),
              ),
            ],
          ),
          if (!detalle.consistente) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.error_outline, size: 15, color: AppColors.error),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Entregados y recibidos no concuerdan para este tipo de operación.',
                    style: AppTextStyles.errorText,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _LineaValor extends StatelessWidget {
  final String label;
  final String valor;
  final Color? color;

  const _LineaValor({required this.label, required this.valor, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.desktopSubtitle.copyWith(fontSize: 13),
            ),
          ),
          Text(
            valor,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: color ?? AppColors.steelBlue,
            ),
          ),
        ],
      ),
    );
  }
}

class _Separador extends StatelessWidget {
  const _Separador();

  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: AppColors.inputBorder);
  }
}
