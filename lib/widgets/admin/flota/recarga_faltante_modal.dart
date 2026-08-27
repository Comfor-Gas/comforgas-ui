import 'package:flutter/material.dart';

import '../../../models/deposito_camion.dart';
import '../../../models/producto_catalogo.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import 'flota_form_controls.dart';

typedef RecargaConfirmada = Future<bool> Function({
  required String productoId,
  required int cantidad,
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
  late int _cantidad;
  late String _productoId;
  final _obsCtrl = TextEditingController();
  bool _guardando = false;

  int get _faltante => widget.camion.faltante;

  @override
  void initState() {
    super.initState();
    _cantidad = _faltante > 0 ? _faltante : 0;
    _productoId =
        widget.productos.isNotEmpty ? widget.productos.first.idProducto : '';
  }

  @override
  void dispose() {
    _obsCtrl.dispose();
    super.dispose();
  }

  void _setCantidad(int valor) {
    setState(() => _cantidad = valor.clamp(0, 999));
  }

  Future<void> _confirmar() async {
    if (_cantidad <= 0 || _productoId.isEmpty || _guardando) return;
    setState(() => _guardando = true);
    final ok = await widget.onConfirmar(
      productoId: _productoId,
      cantidad: _cantidad,
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
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
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
              if (widget.productos.length > 1) ...[
                const FlotaCampoLabel('Tipo de garrafa a recargar'),
                FlotaDropdown<String>(
                  value: _productoId.isNotEmpty ? _productoId : null,
                  hint: 'Seleccionar tipo de garrafa',
                  prefijo: Icons.propane_tank_outlined,
                  items: [
                    for (final p in widget.productos)
                      DropdownMenuItem(
                        value: p.idProducto,
                        child: Text('${p.sku} · ${p.etiquetaKg}'),
                      ),
                  ],
                  onChanged: (id) {
                    if (id != null) setState(() => _productoId = id);
                  },
                ),
                const SizedBox(height: 16),
              ],
              _ContadorRecarga(
                cantidad: _cantidad,
                faltante: _faltante,
                onChanged: _setCantidad,
                onRellenar: () => _setCantidad(_faltante),
              ),
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
                      onTap: (_cantidad > 0 && _productoId.isNotEmpty && !_guardando)
                          ? _confirmar
                          : null,
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

class _ContadorRecarga extends StatelessWidget {
  final int cantidad;
  final int faltante;
  final ValueChanged<int> onChanged;
  final VoidCallback onRellenar;

  const _ContadorRecarga({
    required this.cantidad,
    required this.faltante,
    required this.onChanged,
    required this.onRellenar,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CirculoStep(
          icono: Icons.remove,
          onTap: cantidad > 0 ? () => onChanged(cantidad - 1) : null,
        ),
        Expanded(
          child: Center(
            child: Text(
              '$cantidad',
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w800,
                color: AppColors.steelBlue,
              ),
            ),
          ),
        ),
        _CirculoStep(
          icono: Icons.add,
          acento: AppColors.orange,
          onTap: cantidad < 999 ? () => onChanged(cantidad + 1) : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: GestureDetector(
            onTap: faltante > 0 ? onRellenar : null,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              decoration: BoxDecoration(
                color: faltante > 0
                    ? AppColors.orange
                    : AppColors.badgeGray.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '+$faltante Garrafas Llenas',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CirculoStep extends StatelessWidget {
  final IconData icono;
  final VoidCallback? onTap;
  final Color? acento;

  const _CirculoStep({required this.icono, this.onTap, this.acento});

  @override
  Widget build(BuildContext context) {
    final habilitado = onTap != null;
    final color = acento ?? AppColors.steelBlue;
    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: habilitado ? color : AppColors.inputBorder,
              width: 1.4,
            ),
          ),
          child: Icon(
            icono,
            color: habilitado ? color : AppColors.inputHint,
            size: 22,
          ),
        ),
      ),
    );
  }
}

