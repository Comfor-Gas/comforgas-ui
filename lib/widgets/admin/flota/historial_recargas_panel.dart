import 'package:flutter/material.dart';

import '../../../models/deposito_camion.dart';
import '../../../models/movimiento_stock.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../utils/date_format_utils.dart';

typedef CargarHistorial = Future<List<MovimientoStock>> Function();

class HistorialRecargasPanel extends StatefulWidget {
  final DepositoCamion camion;
  final CargarHistorial cargar;

  const HistorialRecargasPanel({
    super.key,
    required this.camion,
    required this.cargar,
  });

  static Future<void> mostrar(
    BuildContext context, {
    required DepositoCamion camion,
    required CargarHistorial cargar,
  }) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Historial',
      barrierColor: Colors.black.withOpacity(0.4),
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (_, __, ___) => Align(
        alignment: Alignment.centerRight,
        child: HistorialRecargasPanel(camion: camion, cargar: cargar),
      ),
      transitionBuilder: (_, animation, __, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        );
      },
    );
  }

  @override
  State<HistorialRecargasPanel> createState() => _HistorialRecargasPanelState();
}

class _HistorialRecargasPanelState extends State<HistorialRecargasPanel> {
  bool _loading = true;
  String? _error;
  List<MovimientoStock> _movimientos = const [];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await widget.cargar();
      if (!mounted) return;
      setState(() {
        _movimientos = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  bool _esHoy(DateTime? fecha) {
    if (fecha == null) return false;
    final now = DateTime.now();
    return fecha.year == now.year && fecha.month == now.month && fecha.day == now.day;
  }

  int get _totalHoy => _movimientos
      .where((m) => _esHoy(m.fecha))
      .fold(0, (a, m) => a + m.cantidad);

  int get _operacionesHoy => _movimientos.where((m) => _esHoy(m.fecha)).length;

  String get _skuHoy {
    for (final m in _movimientos) {
      if (_esHoy(m.fecha) && m.productoSku.isNotEmpty) return m.productoSku;
    }
    return 'Garrafas';
  }

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.sizeOf(context).width;
    final panelWidth = ancho < 520 ? ancho : 440.0;

    return Material(
      color: AppColors.background,
      child: SafeArea(
        child: SizedBox(
          width: panelWidth,
          height: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Encabezado(
                patente: widget.camion.patenteVisible,
                onCerrar: () => Navigator.of(context).pop(),
              ),
              Expanded(child: _cuerpo()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cuerpo() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.orange));
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
      children: [
        _ResumenAcumulado(
          total: _totalHoy,
          operaciones: _operacionesHoy,
          sku: _skuHoy,
        ),
        const SizedBox(height: 18),
        if (_error != null)
          _AvisoError(mensaje: _error!)
        else if (_movimientos.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text(
                'Todavía no hay recargas registradas para este camión.',
                style: AppTextStyles.link,
                textAlign: TextAlign.center,
              ),
            ),
          )
        else ...[
          Row(
            children: [
              const Icon(Icons.local_shipping_outlined, size: 18, color: AppColors.steelBlue),
              const SizedBox(width: 8),
              Text(
                'Camión ${widget.camion.patenteVisible}',
                style: AppTextStyles.label.copyWith(fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (int i = 0; i < _movimientos.length; i++)
            _FilaHistorial(
              movimiento: _movimientos[i],
              choferNombre: widget.camion.choferNombre,
              primero: i == 0,
              ultimo: i == _movimientos.length - 1,
            ),
        ],
      ],
    );
  }
}

class _Encabezado extends StatelessWidget {
  final String patente;
  final VoidCallback onCerrar;

  const _Encabezado({required this.patente, required this.onCerrar});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 12, 18),
      color: AppColors.sidebarBackground,
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Historial de Recargas · $patente',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.white,
              ),
            ),
          ),
          IconButton(
            onPressed: onCerrar,
            icon: const Icon(Icons.close, color: AppColors.white),
            tooltip: 'Cerrar',
          ),
        ],
      ),
    );
  }
}

class _ResumenAcumulado extends StatelessWidget {
  final int total;
  final int operaciones;
  final String sku;

  const _ResumenAcumulado({
    required this.total,
    required this.operaciones,
    required this.sku,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.steelBlue, AppColors.sidebarBackground],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total recargado hoy',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.local_shipping, color: AppColors.orange, size: 26),
              const SizedBox(width: 10),
              Text(
                '+$total',
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  sku,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.orange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Número de operaciones de recarga: $operaciones',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.white.withOpacity(0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilaHistorial extends StatelessWidget {
  final MovimientoStock movimiento;
  final String choferNombre;
  final bool primero;
  final bool ultimo;

  const _FilaHistorial({
    required this.movimiento,
    required this.choferNombre,
    required this.primero,
    required this.ultimo,
  });

  @override
  Widget build(BuildContext context) {
    final fecha = movimiento.fecha;
    final fechaTexto = fecha != null
        ? '${formatFechaCorta(fecha)} · ${formatHora12(fecha)}'
        : 'Sin fecha';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: primero ? AppColors.orange : AppColors.steelBlue,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.white, width: 2),
                ),
              ),
              if (!ultimo)
                Expanded(
                  child: Container(width: 2, color: AppColors.inputBorder),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: primero ? AppColors.orange.withOpacity(0.06) : AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: primero ? AppColors.orange.withOpacity(0.4) : AppColors.inputBorder,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          fechaTexto,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.graphiteGray,
                          ),
                        ),
                      ),
                      Text(
                        '+${movimiento.cantidad} ${movimiento.productoSku}',
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _LineaDato(icono: Icons.person_outline, texto: choferNombre),
                  const SizedBox(height: 4),
                  _LineaDato(
                    icono: Icons.warehouse_outlined,
                    texto: movimiento.usuario.isNotEmpty
                        ? 'Bodega: ${movimiento.usuario}'
                        : 'Operador de bodega no registrado',
                  ),
                  if (movimiento.observaciones != null &&
                      movimiento.observaciones!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    _LineaDato(
                      icono: Icons.notes_outlined,
                      texto: movimiento.observaciones!,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LineaDato extends StatelessWidget {
  final IconData icono;
  final String texto;

  const _LineaDato({required this.icono, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icono, size: 14, color: AppColors.graphiteGray),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            texto,
            style: const TextStyle(fontSize: 12.5, color: AppColors.steelBlue),
          ),
        ),
      ],
    );
  }
}

class _AvisoError extends StatelessWidget {
  final String mensaje;

  const _AvisoError({required this.mensaje});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 18, color: AppColors.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              mensaje,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
