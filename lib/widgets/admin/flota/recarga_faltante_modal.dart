import 'package:flutter/material.dart';

import '../../../models/deposito_camion.dart';
import '../../../models/producto_catalogo.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../chofer/venta/cantidad_stepper.dart';
import 'flota_form_controls.dart';

typedef RecargaConfirmada = Future<bool> Function({
  required List<Map<String, dynamic>> items,
  String? observaciones,
});

class RecargaFaltanteModal extends StatefulWidget {
  final DepositoCamion camion;
  final List<ProductoCatalogo> productos;
  final RecargaConfirmada onConfirmar;

  const RecargaFaltanteModal({
    super.key,
    required this.camion,
    required this.productos,
    required this.onConfirmar,
  });

  static Future<void> mostrar(
    BuildContext context, {
    required DepositoCamion camion,
    required List<ProductoCatalogo> productos,
    required RecargaConfirmada onConfirmar,
  }) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (_) => RecargaFaltanteModal(
        camion: camion,
        productos: productos,
        onConfirmar: onConfirmar,
      ),
    );
  }

  @override
  State<RecargaFaltanteModal> createState() => _RecargaFaltanteModalState();
}

class _RecargaFaltanteModalState extends State<RecargaFaltanteModal> {
  final Map<String, int> _desglose = {};
  final _obsCtrl = TextEditingController();
  bool _guardando = false;

  int get _total => _desglose.values.fold(0, (a, b) => a + b);
  bool get _valido => _total > 0;

  @override
  void initState() {
    super.initState();
    for (final p in widget.productos) {
      _desglose[p.idProducto] = 0;
    }
  }

  @override
  void dispose() {
    _obsCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirmar() async {
    if (!_valido || _guardando) return;
    final items = <Map<String, dynamic>>[];
    for (final p in widget.productos) {
      final cant = _desglose[p.idProducto] ?? 0;
      if (cant > 0) {
        items.add({'productoId': p.idProducto, 'sku': p.sku, 'cantidad': cant});
      }
    }

    setState(() => _guardando = true);
    final ok = await widget.onConfirmar(
      items: items,
      observaciones: _obsCtrl.text.trim().isEmpty ? null : _obsCtrl.text.trim(),
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
    } else {
      setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Registrar Recarga en Ruta',
                style: AppTextStyles.desktopTitle.copyWith(fontSize: 20),
              ),
              const SizedBox(height: 4),
              Text(
                'Camión ${widget.camion.patenteVisible} · ${widget.camion.choferNombre}',
                style: AppTextStyles.desktopSubtitle,
              ),
              const SizedBox(height: 18),
              Text(
                'Cantidad a recargar por tipo de garrafa',
                style: AppTextStyles.label.copyWith(fontSize: 13),
              ),
              const SizedBox(height: 12),
              if (widget.productos.isEmpty)
                Text(
                  'No hay productos en el catálogo para recargar.',
                  style: AppTextStyles.footer,
                )
              else
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final p in widget.productos)
                      SizedBox(
                        width: 158,
                        child: CantidadStepper(
                          titulo: 'SKU ${p.sku}',
                          subtitulo: p.etiquetaKg,
                          icono: Icons.propane_tank_outlined,
                          acento: AppColors.orange,
                          valor: _desglose[p.idProducto] ?? 0,
                          editable: true,
                          onChanged: (valor) =>
                              setState(() => _desglose[p.idProducto] = valor),
                        ),
                      ),
                  ],
                ),
              const SizedBox(height: 12),
              _TotalRecarga(total: _total),
              const SizedBox(height: 18),
              Text(
                'Observaciones del Operador de Bodega',
                style: AppTextStyles.label.copyWith(fontSize: 13),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _obsCtrl,
                maxLines: 2,
                style: AppTextStyles.input,
                decoration: InputDecoration(
                  hintText: 'Ingrese notas o comentarios...',
                  hintStyle: AppTextStyles.hint,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.inputBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.inputBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.orange),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: FlotaBotonSecundario(
                      texto: 'Cancelar',
                      onTap: _guardando ? null : () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FlotaBotonPrimario(
                      texto: 'Confirmar Recarga de Stock',
                      cargando: _guardando,
                      onTap: (_valido && !_guardando) ? _confirmar : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TotalRecarga extends StatelessWidget {
  final int total;

  const _TotalRecarga({required this.total});

  @override
  Widget build(BuildContext context) {
    final vacio = total == 0;
    final color = vacio ? AppColors.graphiteGray : AppColors.badgeGreen;
    final mensaje = vacio
        ? 'Ingresá la cantidad por tipo de garrafa.'
        : 'Total a recargar en esta operación';

    return Row(
      children: [
        Icon(Icons.inventory_2_outlined, size: 17, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            mensaje,
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: color),
          ),
        ),
        Text(
          '$total',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color),
        ),
      ],
    );
  }
}
