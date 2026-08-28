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

  int get _faltante => widget.camion.faltante;
  int get _total => _desglose.values.fold(0, (a, b) => a + b);
  bool get _valido => _total > 0 && _total <= _faltante;

  @override
  void initState() {
    super.initState();
    for (final p in widget.productos) {
      _desglose[p.idProducto] = 0;
    }
    if (widget.productos.isNotEmpty && _faltante > 0) {
      _desglose[widget.productos.first.idProducto] = _faltante;
    }
  }

  @override
  void dispose() {
    _obsCtrl.dispose();
    super.dispose();
  }

  void _completarFaltante() {
    if (widget.productos.isEmpty) return;
    setState(() {
      for (final p in widget.productos) {
        _desglose[p.idProducto] = 0;
      }
      _desglose[widget.productos.first.idProducto] = _faltante;
    });
  }

  Future<void> _confirmar() async {
    if (!_valido || _guardando) return;
    final items = _desglose.entries
        .where((e) => e.value > 0)
        .map((e) => {'productoId': e.key, 'cantidad': e.value})
        .toList();

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
                'Recarga de Faltante de Garrafas',
                style: AppTextStyles.desktopTitle.copyWith(fontSize: 20),
              ),
              const SizedBox(height: 4),
              Text(
                'Camión ${widget.camion.patenteVisible} · ${widget.camion.choferNombre}',
                style: AppTextStyles.desktopSubtitle,
              ),
              const SizedBox(height: 18),
              _ResumenCupo(
                cupo: widget.camion.cupoBase,
                lleno: widget.camion.llenos,
                faltante: _faltante,
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Cantidad a recargar por tipo de garrafa',
                      style: AppTextStyles.label.copyWith(fontSize: 13),
                    ),
                  ),
                  if (_faltante > 0)
                    TextButton.icon(
                      onPressed: _completarFaltante,
                      icon: const Icon(Icons.auto_fix_high, size: 16, color: AppColors.orange),
                      label: Text(
                        'Completar faltante ($_faltante)',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.orange,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                ],
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
                          maximo: _faltante > 0 ? _faltante : 0,
                          editable: true,
                          onChanged: (valor) =>
                              setState(() => _desglose[p.idProducto] = valor),
                        ),
                      ),
                  ],
                ),
              const SizedBox(height: 12),
              _TotalRecarga(total: _total, faltante: _faltante),
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

class _ResumenCupo extends StatelessWidget {
  final int cupo;
  final int lleno;
  final int faltante;

  const _ResumenCupo({
    required this.cupo,
    required this.lleno,
    required this.faltante,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Row(
        children: [
          _DatoCupo(etiqueta: 'Cupo Total', valor: '$cupo'),
          _SeparadorCupo(),
          _DatoCupo(etiqueta: 'Stock Lleno', valor: '$lleno'),
          _SeparadorCupo(),
          _DatoCupo(etiqueta: 'Faltante', valor: '$faltante', acento: AppColors.orange),
        ],
      ),
    );
  }
}

class _DatoCupo extends StatelessWidget {
  final String etiqueta;
  final String valor;
  final Color? acento;

  const _DatoCupo({required this.etiqueta, required this.valor, this.acento});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            etiqueta,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.graphiteGray,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            valor,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: acento ?? AppColors.steelBlue,
            ),
          ),
        ],
      ),
    );
  }
}

class _SeparadorCupo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 34, color: AppColors.inputBorder);
  }
}

class _TotalRecarga extends StatelessWidget {
  final int total;
  final int faltante;

  const _TotalRecarga({required this.total, required this.faltante});

  @override
  Widget build(BuildContext context) {
    final excede = total > faltante;
    final vacio = total == 0;
    final color = excede
        ? AppColors.error
        : (vacio ? AppColors.graphiteGray : AppColors.badgeGreen);
    final mensaje = excede
        ? 'La recarga supera el faltante de $faltante.'
        : (vacio
            ? 'Ingresá la cantidad por tipo de garrafa.'
            : 'Total a recargar en esta operación');

    return Row(
      children: [
        Icon(
          excede ? Icons.error_outline : Icons.inventory_2_outlined,
          size: 17,
          color: color,
        ),
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
