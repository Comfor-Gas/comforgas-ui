import 'package:flutter/material.dart';

import '../../../models/deposito_camion.dart';
import '../../../models/producto_catalogo.dart';
import '../../../models/usuario_model.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../chofer/venta/cantidad_stepper.dart';
import 'flota_form_controls.dart';

typedef AsignacionConfirmada = Future<bool> Function({
  required DepositoCamion camion,
  required String choferId,
  required List<Map<String, dynamic>> items,
});

class AsignacionCamionModal extends StatefulWidget {
  final List<DepositoCamion> camiones;
  final List<UsuarioModel> choferes;
  final List<ProductoCatalogo> productos;
  final DepositoCamion? camionInicial;
  final AsignacionConfirmada onConfirmar;

  const AsignacionCamionModal({
    super.key,
    required this.camiones,
    required this.choferes,
    required this.productos,
    required this.onConfirmar,
    this.camionInicial,
  });

  static Future<void> mostrar(
    BuildContext context, {
    required List<DepositoCamion> camiones,
    required List<UsuarioModel> choferes,
    required List<ProductoCatalogo> productos,
    DepositoCamion? camionInicial,
    required AsignacionConfirmada onConfirmar,
  }) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (_) => AsignacionCamionModal(
        camiones: camiones,
        choferes: choferes,
        productos: productos,
        camionInicial: camionInicial,
        onConfirmar: onConfirmar,
      ),
    );
  }

  @override
  State<AsignacionCamionModal> createState() => _AsignacionCamionModalState();
}

class _AsignacionCamionModalState extends State<AsignacionCamionModal> {
  String? _choferId;
  int? _camionId;
  final Map<String, int> _desglose = {};
  bool _guardando = false;

  int get _total => _desglose.values.fold(0, (a, b) => a + b);
  bool get _sumaCorrecta => _total == kCupoBaseCamion;

  @override
  void initState() {
    super.initState();
    _camionId = widget.camionInicial?.id;
    _choferId = widget.camionInicial?.repartidor?.id;
    for (final p in widget.productos) {
      _desglose[p.idProducto] = 0;
    }
    if (widget.productos.isNotEmpty) {
      _desglose[widget.productos.first.idProducto] = kCupoBaseCamion;
    }
  }

  DepositoCamion? get _camionSeleccionado {
    for (final c in widget.camiones) {
      if (c.id == _camionId) return c;
    }
    return null;
  }

  Future<void> _confirmar() async {
    final camion = _camionSeleccionado;
    final choferId = _choferId;
    if (camion == null || choferId == null || !_sumaCorrecta || _guardando) return;

    final items = _desglose.entries
        .where((e) => e.value > 0)
        .map((e) => {'productoId': e.key, 'cantidad': e.value})
        .toList();

    setState(() => _guardando = true);
    final ok = await widget.onConfirmar(
      camion: camion,
      choferId: choferId,
      items: items,
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
                'Asignar Camión y Carga Inicial',
                style: AppTextStyles.desktopTitle.copyWith(fontSize: 20),
              ),
              const SizedBox(height: 4),
              Text(
                'Vinculá un chofer a un camión y despachá el cupo base de $kCupoBaseCamion garrafas.',
                style: AppTextStyles.desktopSubtitle,
              ),
              const SizedBox(height: 20),
              const FlotaCampoLabel('Chofer'),
              FlotaDropdown<String>(
                value: _choferId,
                hint: 'Seleccionar Chofer',
                prefijo: Icons.person_outline,
                items: [
                  for (final ch in widget.choferes)
                    DropdownMenuItem(
                      value: ch.id,
                      child: Text(ch.fullName.isNotEmpty ? ch.fullName : ch.email),
                    ),
                ],
                onChanged: (id) => setState(() => _choferId = id),
              ),
              const SizedBox(height: 16),
              const FlotaCampoLabel('Patente Camión'),
              FlotaDropdown<int>(
                value: _camionId,
                hint: 'Seleccionar Patente',
                prefijo: Icons.local_shipping_outlined,
                items: [
                  for (final c in widget.camiones)
                    DropdownMenuItem(
                      value: c.id,
                      child: Text(c.patenteVisible),
                    ),
                ],
                onChanged: (id) => setState(() => _camionId = id),
              ),
              const SizedBox(height: 16),
              _CampoBloqueado(total: kCupoBaseCamion),
              const SizedBox(height: 18),
              const FlotaCampoLabel('Carga Inicial Predeterminada'),
              _DesgloseSkus(
                productos: widget.productos,
                desglose: _desglose,
                onCambiar: (id, valor) => setState(() => _desglose[id] = valor),
              ),
              const SizedBox(height: 12),
              _TotalDesglose(total: _total, objetivo: kCupoBaseCamion),
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
                      texto: 'Confirmar y Despachar Camión',
                      icono: Icons.local_shipping_outlined,
                      cargando: _guardando,
                      onTap: (_camionId != null &&
                              _choferId != null &&
                              _sumaCorrecta &&
                              !_guardando)
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

class _CampoBloqueado extends StatelessWidget {
  final int total;

  const _CampoBloqueado({required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline, size: 18, color: AppColors.graphiteGray),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Stock Inicial Total: $total Garrafas (Solo Lectura)',
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: AppColors.graphiteGray,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DesgloseSkus extends StatelessWidget {
  final List<ProductoCatalogo> productos;
  final Map<String, int> desglose;
  final void Function(String productoId, int valor) onCambiar;

  const _DesgloseSkus({
    required this.productos,
    required this.desglose,
    required this.onCambiar,
  });

  @override
  Widget build(BuildContext context) {
    if (productos.isEmpty) {
      return Text(
        'No hay productos en el catálogo para desglosar la carga.',
        style: AppTextStyles.footer,
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final p in productos)
          SizedBox(
            width: 158,
            child: CantidadStepper(
              titulo: 'SKU ${p.sku}',
              subtitulo: p.etiquetaKg,
              icono: Icons.propane_tank_outlined,
              acento: AppColors.orange,
              valor: desglose[p.idProducto] ?? 0,
              maximo: kCupoBaseCamion,
              editable: true,
              onChanged: (valor) => onCambiar(p.idProducto, valor),
            ),
          ),
      ],
    );
  }
}

class _TotalDesglose extends StatelessWidget {
  final int total;
  final int objetivo;

  const _TotalDesglose({required this.total, required this.objetivo});

  @override
  Widget build(BuildContext context) {
    final correcto = total == objetivo;
    final color = correcto ? AppColors.badgeGreen : AppColors.error;
    final mensaje = correcto
        ? 'Carga estándar calculada para ruta predeterminada'
        : (total > objetivo
            ? 'La suma supera el cupo. Ajustá el desglose a $objetivo.'
            : 'Faltan ${objetivo - total} para completar el cupo de $objetivo.');

    return Row(
      children: [
        Icon(
          correcto ? Icons.check_circle_outline : Icons.error_outline,
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
          '$total / $objetivo',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color),
        ),
      ],
    );
  }
}
