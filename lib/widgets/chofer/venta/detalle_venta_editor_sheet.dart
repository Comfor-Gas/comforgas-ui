import 'package:flutter/material.dart';
import '../../../models/detalle_venta_draft.dart';
import '../../../models/producto_sku.dart';
import '../../../models/tipo_operacion_venta.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../utils/formato.dart';
import 'cantidad_stepper.dart';

Future<DetalleVentaDraft?> mostrarDetalleVentaEditor(
  BuildContext context, {
  required ProductoSku producto,
  required TipoOperacionVenta tipoOperacion,
  DetalleVentaDraft? inicial,
}) {
  return showModalBottomSheet<DetalleVentaDraft>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _DetalleVentaEditorSheet(
      producto: producto,
      tipoOperacion: tipoOperacion,
      inicial: inicial,
    ),
  );
}

class _DetalleVentaEditorSheet extends StatefulWidget {
  final ProductoSku producto;
  final TipoOperacionVenta tipoOperacion;
  final DetalleVentaDraft? inicial;

  const _DetalleVentaEditorSheet({
    required this.producto,
    required this.tipoOperacion,
    this.inicial,
  });

  @override
  State<_DetalleVentaEditorSheet> createState() =>
      _DetalleVentaEditorSheetState();
}

class _DetalleVentaEditorSheetState extends State<_DetalleVentaEditorSheet> {
  late DetalleVentaDraft _draft;
  bool _mostrarError = false;

  void _intentarGuardar() {
    if (_draft.esValido) {
      Navigator.of(context).pop(_draft);
    } else {
      setState(() => _mostrarError = true);
    }
  }

  @override
  void initState() {
    super.initState();
    final base = widget.inicial;
    final stock = widget.producto.stockDisponible;
    var entregada = base?.cantidadEntregada ?? 1;
    if (stock != null && entregada > stock) entregada = stock;
    _draft = DetalleVentaDraft(
      producto: widget.producto,
      tipoOperacion: widget.tipoOperacion,
      cantidadEntregada: entregada,
      cantidadRecibida: widget.tipoOperacion == TipoOperacionVenta.prestamo
          ? 0
          : base?.cantidadRecibida ??
              (widget.tipoOperacion == TipoOperacionVenta.vacioXLleno ? 1 : 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final info = widget.tipoOperacion.info;
    final error = _mostrarError ? _draft.mensajeError : null;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.inputBorder,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 18),
                _EncabezadoProducto(
                  descripcion: widget.producto.descripcion,
                  tipoLabel: info.label,
                  tipoColor: widget.tipoOperacion.color,
                  tipoIcono: info.icono,
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: CantidadStepper(
                        titulo: 'Entregados',
                        subtitulo: widget.producto.stockDisponible != null
                            ? 'Lleno · máx ${widget.producto.stockDisponible}'
                            : 'Lleno',
                        icono: Icons.propane_tank,
                        acento: AppColors.orange,
                        valor: _draft.cantidadEntregada,
                        maximo: widget.producto.stockDisponible ?? 999,
                        onChanged: (v) => setState(() {
                          _draft.cantidadEntregada = v;
                          _mostrarError = false;
                        }),
                      ),
                    ),
                    if (widget.tipoOperacion.usaRecibidos) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: CantidadStepper(
                          titulo: 'Recibidos',
                          subtitulo: 'Vacío',
                          icono: Icons.propane_tank_outlined,
                          acento: AppColors.steelBlue,
                          valor: _draft.cantidadRecibida,
                          onChanged: (v) => setState(() {
                            _draft.cantidadRecibida = v;
                            _mostrarError = false;
                          }),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                _ResumenSubtotal(
                  precioUnitario: widget.producto.precioUnitario,
                  cantidad: _draft.cantidadEntregada,
                  subtotal: _draft.subtotal,
                ),
                if (error != null) ...[
                  const SizedBox(height: 14),
                  _BannerError(mensaje: error),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _intentarGuardar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.orange,
                      disabledBackgroundColor: AppColors.inputBorder,
                      foregroundColor: Colors.white,
                      disabledForegroundColor: AppColors.inputHint,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: AppTextStyles.button,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      widget.inicial == null
                          ? 'AGREGAR AL DETALLE'
                          : 'ACTUALIZAR DETALLE',
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

class _EncabezadoProducto extends StatelessWidget {
  final String descripcion;
  final String tipoLabel;
  final Color tipoColor;
  final IconData tipoIcono;

  const _EncabezadoProducto({
    required this.descripcion,
    required this.tipoLabel,
    required this.tipoColor,
    required this.tipoIcono,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.orange.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.propane_tank_outlined,
            color: AppColors.orange,
            size: 26,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(descripcion, style: AppTextStyles.title.copyWith(fontSize: 18)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: tipoColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(tipoIcono, size: 14, color: tipoColor),
                    const SizedBox(width: 5),
                    Text(
                      tipoLabel,
                      style: AppTextStyles.footer.copyWith(
                        color: tipoColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ResumenSubtotal extends StatelessWidget {
  final int precioUnitario;
  final int cantidad;
  final int subtotal;

  const _ResumenSubtotal({
    required this.precioUnitario,
    required this.cantidad,
    required this.subtotal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        children: [
          Text(
            formatMoneda(subtotal),
            style: AppTextStyles.title.copyWith(fontSize: 30),
          ),
          const SizedBox(height: 2),
          Text(
            'Subtotal calculado automáticamente',
            style: AppTextStyles.footer,
          ),
          const SizedBox(height: 10),
          Divider(color: AppColors.inputBorder, height: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${formatMoneda(precioUnitario)}  ×  $cantidad entregados',
                style: AppTextStyles.link.copyWith(fontSize: 13),
              ),
              Text(
                formatMoneda(subtotal),
                style: AppTextStyles.label.copyWith(fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BannerError extends StatelessWidget {
  final String mensaje;

  const _BannerError({required this.mensaje});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withOpacity(0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              mensaje,
              style: AppTextStyles.errorText.copyWith(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
