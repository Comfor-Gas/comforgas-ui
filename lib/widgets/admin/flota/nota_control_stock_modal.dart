import 'package:flutter/material.dart';

import '../../../models/deposito_camion.dart';
import '../../../models/nota_control_stock.dart';
import '../../../models/producto_catalogo.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import 'flota_form_controls.dart';
import 'planilla_stock_tabla.dart';

typedef NotaControlConfirmada = Future<bool> Function(NotaControlStockDraft draft);

class NotaControlStockModal extends StatefulWidget {
  final DepositoCamion camion;
  final List<ProductoCatalogo> productos;
  final NotaControlConfirmada onConfirmar;

  const NotaControlStockModal({
    super.key,
    required this.camion,
    required this.productos,
    required this.onConfirmar,
  });

  static Future<void> mostrar(
    BuildContext context, {
    required DepositoCamion camion,
    required List<ProductoCatalogo> productos,
    required NotaControlConfirmada onConfirmar,
  }) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (_) => NotaControlStockModal(
        camion: camion,
        productos: productos,
        onConfirmar: onConfirmar,
      ),
    );
  }

  @override
  State<NotaControlStockModal> createState() => _NotaControlStockModalState();
}

class _NotaControlStockModalState extends State<NotaControlStockModal> {
  final Map<String, Map<String, int>> _valores = {};
  final _obsCtrl = TextEditingController();
  DateTime _fecha = DateTime.now();
  bool _guardando = false;

  static const _columnas = [
    ColumnaStock(key: 'llenos', etiqueta: 'Llenos', color: AppColors.orange),
    ColumnaStock(key: 'vacios', etiqueta: 'Vacíos', color: AppColors.steelBlue),
  ];

  @override
  void initState() {
    super.initState();
    for (final p in widget.productos) {
      _valores[p.idProducto] = {'llenos': 0, 'vacios': 0};
    }
  }

  @override
  void dispose() {
    _obsCtrl.dispose();
    super.dispose();
  }

  int get _totalLlenos =>
      widget.productos.fold(0, (a, p) => a + (_valores[p.idProducto]?['llenos'] ?? 0));
  int get _totalVacios =>
      widget.productos.fold(0, (a, p) => a + (_valores[p.idProducto]?['vacios'] ?? 0));

  int get _faltante => widget.camion.faltante;
  bool get _excedeCupo => _totalLlenos > _faltante;
  bool get _valido => (_totalLlenos > 0 || _totalVacios > 0) && !_excedeCupo && !_guardando;

  void _cambiar(String productoId, String key, int valor) {
    setState(() => _valores[productoId]?[key] = valor);
  }

  Future<void> _elegirFecha() async {
    final elegida = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.orange,
              onPrimary: AppColors.white,
              onSurface: AppColors.steelBlue,
            ),
          ),
          child: child!,
        );
      },
    );
    if (elegida != null) setState(() => _fecha = elegida);
  }

  Future<void> _confirmar() async {
    if (!_valido) return;
    final lineas = widget.productos
        .map((p) => LineaStock(
              producto: p,
              llenos: _valores[p.idProducto]?['llenos'] ?? 0,
              vacios: _valores[p.idProducto]?['vacios'] ?? 0,
            ))
        .toList();
    final draft = NotaControlStockDraft(
      camionId: widget.camion.id,
      choferNombre: widget.camion.choferNombre,
      patente: widget.camion.patenteVisible,
      folio: null,
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
        constraints: const BoxConstraints(maxWidth: 640),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Nota de Control Interno (Stock)',
                style: AppTextStyles.desktopTitle.copyWith(fontSize: 20),
              ),
              const SizedBox(height: 4),
              Text(
                'Carga inicial / recarga de garrafas del camión',
                style: AppTextStyles.desktopSubtitle,
              ),
              const SizedBox(height: 18),
              _buildCabecera(),
              const SizedBox(height: 16),
              _ResumenCupo(cupo: widget.camion.cupoBase, lleno: widget.camion.llenos, faltante: _faltante),
              const SizedBox(height: 16),
              Text(
                'Detalle por tipo de garrafa',
                style: AppTextStyles.label.copyWith(fontSize: 13),
              ),
              const SizedBox(height: 10),
              if (widget.productos.isEmpty)
                Text('No hay productos en el catálogo para cargar.', style: AppTextStyles.footer)
              else
                PlanillaStockTabla(
                  productos: widget.productos,
                  columnas: _columnas,
                  valores: _valores,
                  enabled: !_guardando,
                  onCambio: _cambiar,
                ),
              const SizedBox(height: 12),
              _buildAvisoCupo(),
              const SizedBox(height: 10),
              _buildAvisoVacios(),
              const SizedBox(height: 18),
              Text('Observaciones', style: AppTextStyles.label.copyWith(fontSize: 13)),
              const SizedBox(height: 8),
              TextField(
                controller: _obsCtrl,
                enabled: !_guardando,
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
                      texto: 'Guardar Nota de Control',
                      icono: Icons.save_outlined,
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

  Widget _buildCabecera() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Wrap(
        spacing: 14,
        runSpacing: 12,
        children: [
          _DatoCabecera(etiqueta: 'Chofer', valor: widget.camion.choferNombre, icono: Icons.person_outline),
          _DatoCabecera(etiqueta: 'Dominio', valor: widget.camion.patenteVisible, icono: Icons.local_shipping_outlined),
          _DatoFolio(),
          _DatoFecha(fecha: _fecha, onTap: _guardando ? null : _elegirFecha),
        ],
      ),
    );
  }

  Widget _buildAvisoCupo() {
    if (!_excedeCupo) return const SizedBox.shrink();
    return _Aviso(
      color: AppColors.error,
      icono: Icons.error_outline,
      texto: 'Los llenos ($_totalLlenos) superan el faltante del camión ($_faltante).',
    );
  }

  Widget _buildAvisoVacios() {
    return _Aviso(
      color: AppColors.badgeBlue,
      icono: Icons.info_outline,
      texto:
          'El Folio N° se genera automáticamente al guardar. Se registran en el stock del camión los llenos y los vacíos cargados.',
    );
  }
}

class _DatoCabecera extends StatelessWidget {
  final String etiqueta;
  final String valor;
  final IconData icono;

  const _DatoCabecera({required this.etiqueta, required this.valor, required this.icono});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 176,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(etiqueta.toUpperCase(), style: AppTextStyles.footer.copyWith(letterSpacing: 0.4)),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(icono, size: 16, color: AppColors.steelBlue),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  valor,
                  style: AppTextStyles.label.copyWith(fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DatoFolio extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 176,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('FOLIO N°', style: AppTextStyles.footer.copyWith(letterSpacing: 0.4)),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.tag, size: 16, color: AppColors.badgeGray),
              const SizedBox(width: 6),
              Text(
                'Se genera al guardar',
                style: AppTextStyles.footer.copyWith(color: AppColors.badgeGray),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DatoFecha extends StatelessWidget {
  final DateTime fecha;
  final VoidCallback? onTap;

  const _DatoFecha({required this.fecha, required this.onTap});

  String get _texto {
    final d = fecha.day.toString().padLeft(2, '0');
    final m = fecha.month.toString().padLeft(2, '0');
    return '$d/$m/${fecha.year}';
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 176,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('FECHA', style: AppTextStyles.footer.copyWith(letterSpacing: 0.4)),
          const SizedBox(height: 4),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 15, color: AppColors.orange),
                const SizedBox(width: 6),
                Text(_texto, style: AppTextStyles.label.copyWith(fontSize: 14)),
                if (onTap != null) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.expand_more, size: 16, color: AppColors.inputHint),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResumenCupo extends StatelessWidget {
  final int cupo;
  final int lleno;
  final int faltante;

  const _ResumenCupo({required this.cupo, required this.lleno, required this.faltante});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Row(
        children: [
          _Dato(etiqueta: 'Cupo Total', valor: '$cupo'),
          _Sep(),
          _Dato(etiqueta: 'Stock Lleno', valor: '$lleno'),
          _Sep(),
          _Dato(etiqueta: 'Faltante', valor: '$faltante', acento: AppColors.orange),
        ],
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  final String etiqueta;
  final String valor;
  final Color? acento;

  const _Dato({required this.etiqueta, required this.valor, this.acento});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            etiqueta,
            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.graphiteGray),
          ),
          const SizedBox(height: 4),
          Text(
            valor,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: acento ?? AppColors.steelBlue),
          ),
        ],
      ),
    );
  }
}

class _Sep extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 34, color: AppColors.inputBorder);
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
