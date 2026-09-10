import 'package:flutter/material.dart';

import '../../../models/deposito_camion.dart';
import '../../../models/nota_control_stock.dart';
import '../../../models/producto_catalogo.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import 'flota_form_controls.dart';
import 'planilla_stock_tabla.dart';

typedef EntradaMovilConfirmada = Future<bool> Function(EntradaMovilDraft draft);

class EntradaMovilModal extends StatefulWidget {
  final DepositoCamion camion;
  final List<ProductoCatalogo> productos;
  final bool backendPendiente;
  final EntradaMovilConfirmada onConfirmar;

  const EntradaMovilModal({
    super.key,
    required this.camion,
    required this.productos,
    required this.backendPendiente,
    required this.onConfirmar,
  });

  static Future<void> mostrar(
    BuildContext context, {
    required DepositoCamion camion,
    required List<ProductoCatalogo> productos,
    required bool backendPendiente,
    required EntradaMovilConfirmada onConfirmar,
  }) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (_) => EntradaMovilModal(
        camion: camion,
        productos: productos,
        backendPendiente: backendPendiente,
        onConfirmar: onConfirmar,
      ),
    );
  }

  @override
  State<EntradaMovilModal> createState() => _EntradaMovilModalState();
}

class _EntradaMovilModalState extends State<EntradaMovilModal> {
  final Map<String, Map<String, int>> _valores = {};
  final _obsCtrl = TextEditingController();
  DateTime _fecha = DateTime.now();
  bool _guardando = false;

  static const _columnas = [
    ColumnaStock(key: 'llenos', etiqueta: 'Llenos', color: AppColors.orange),
    ColumnaStock(key: 'vacios', etiqueta: 'Vacíos', color: AppColors.steelBlue),
    ColumnaStock(key: 'averiados', etiqueta: 'Averiados', color: AppColors.badgeRed),
  ];

  @override
  void initState() {
    super.initState();
    for (final p in widget.productos) {
      _valores[p.idProducto] = {'llenos': 0, 'vacios': 0, 'averiados': 0};
    }
  }

  @override
  void dispose() {
    _obsCtrl.dispose();
    super.dispose();
  }

  int _totalCol(String key) =>
      widget.productos.fold(0, (a, p) => a + (_valores[p.idProducto]?[key] ?? 0));

  int get _totalGeneral => _totalCol('llenos') + _totalCol('vacios') + _totalCol('averiados');
  bool get _valido => _totalGeneral > 0 && !_guardando;

  void _cambiar(String productoId, String key, int valor) {
    setState(() => _valores[productoId]?[key] = valor);
  }

  Future<void> _confirmar() async {
    if (!_valido) return;
    final lineas = widget.productos
        .map((p) => LineaStock(
              producto: p,
              llenos: _valores[p.idProducto]?['llenos'] ?? 0,
              vacios: _valores[p.idProducto]?['vacios'] ?? 0,
              averiados: _valores[p.idProducto]?['averiados'] ?? 0,
            ))
        .toList();
    final draft = EntradaMovilDraft(
      camionId: widget.camion.id,
      choferNombre: widget.camion.choferNombre,
      patente: widget.camion.patenteVisible,
      fecha: _fecha,
      lineas: lineas,
      observaciones: _obsCtrl.text.trim().isEmpty ? null : _obsCtrl.text.trim(),
    );

    setState(() => _guardando = true);
    final ok = await widget.onConfirmar(draft);
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
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Entrada del Móvil (cierre de jornada)',
                style: AppTextStyles.desktopTitle.copyWith(fontSize: 20),
              ),
              const SizedBox(height: 4),
              Text(
                'Camión ${widget.camion.patenteVisible} · ${widget.camion.choferNombre}',
                style: AppTextStyles.desktopSubtitle,
              ),
              const SizedBox(height: 18),
              if (widget.backendPendiente) ...[
                _Aviso(
                  color: AppColors.badgeAmber,
                  icono: Icons.info_outline,
                  texto:
                      'El registro definitivo de la entrada requiere el endpoint de estados de garrafa en el backend. Por ahora el conteo se refleja localmente para revisión.',
                ),
                const SizedBox(height: 16),
              ],
              Text(
                'Conteo de retorno por tipo de garrafa',
                style: AppTextStyles.label.copyWith(fontSize: 13),
              ),
              const SizedBox(height: 10),
              if (widget.productos.isEmpty)
                Text('No hay productos en el catálogo para contar.', style: AppTextStyles.footer)
              else
                PlanillaStockTabla(
                  productos: widget.productos,
                  columnas: _columnas,
                  valores: _valores,
                  enabled: !_guardando,
                  onCambio: _cambiar,
                ),
              const SizedBox(height: 18),
              Text('Observaciones', style: AppTextStyles.label.copyWith(fontSize: 13)),
              const SizedBox(height: 8),
              TextField(
                controller: _obsCtrl,
                enabled: !_guardando,
                maxLines: 2,
                style: AppTextStyles.input,
                decoration: InputDecoration(
                  hintText: 'Novedades del retorno (opcional)...',
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
                      texto: 'Registrar Entrada del Móvil',
                      icono: Icons.local_shipping_outlined,
                      cargando: _guardando,
                      onTap: _valido ? _confirmar : null,
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

class _Aviso extends StatelessWidget {
  final Color color;
  final IconData icono;
  final String texto;

  const _Aviso({required this.color, required this.icono, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(icono, size: 17, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              texto,
              style: AppTextStyles.footer.copyWith(color: AppColors.graphiteGray),
            ),
          ),
        ],
      ),
    );
  }
}
