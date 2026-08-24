import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/responsive.dart';
import '../../data/mock_ventas_monitoreo.dart';
import '../../models/venta_monitoreo.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/network_exception.dart';
import '../../repositories/venta_monitoreo_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/formato.dart';
import '../../widgets/admin/ventas/ventas_filtros_bar.dart';
import '../../widgets/admin/ventas/ventas_tabla.dart';
import '../../widgets/admin/ventas/venta_detalle_panel.dart';

class ConsolaVentasScreen extends StatefulWidget {
  const ConsolaVentasScreen({super.key});

  @override
  State<ConsolaVentasScreen> createState() => _ConsolaVentasScreenState();
}

class _ConsolaVentasScreenState extends State<ConsolaVentasScreen> {
  late final VentaMonitoreoRepository _repo;
  final TextEditingController _choferCtrl = TextEditingController();
  final TextEditingController _clienteCtrl = TextEditingController();

  bool _loading = true;
  String? _error;
  bool _modoEjemplo = false;

  DateTime _fecha = DateTime.now();
  EstadoVentaMonitoreo? _estadoFiltro;
  int? _idSeleccionada;

  List<VentaMonitoreo> _ventas = [];
  int _montoTotalDia = 0;

  @override
  void initState() {
    super.initState();
    _repo = VentaMonitoreoRepository(context.read<AuthProvider>().apiClient);
    _choferCtrl.addListener(() => setState(() {}));
    _clienteCtrl.addListener(() => setState(() {}));
    _cargar();
  }

  @override
  void dispose() {
    _choferCtrl.dispose();
    _clienteCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await _repo.obtenerMonitoreo(fecha: _fecha);
      if (!mounted) return;
      setState(() {
        _ventas = data.ventas;
        _montoTotalDia = data.montoTotal;
        _modoEjemplo = false;
        _loading = false;
        _sincronizarSeleccion();
      });
    } on NetworkException {
      _usarEjemplo('No se pudo conectar con el servidor: mostrando datos de ejemplo.');
    } on VentaMonitoreoRepositoryException catch (e) {
      if (e.endpointNoDisponible) {
        _usarEjemplo(
          'El endpoint de monitoreo todavía no está disponible en el backend: mostrando datos de ejemplo.',
        );
      } else {
        if (!mounted) return;
        setState(() {
          _error = e.message;
          _loading = false;
        });
      }
    } catch (_) {
      _usarEjemplo('Ocurrió un problema al cargar las ventas: mostrando datos de ejemplo.');
    }
  }

  void _usarEjemplo(String mensaje) {
    if (!mounted) return;
    final data = ventasMonitoreoDeEjemplo(_fecha);
    setState(() {
      _ventas = data.ventas;
      _montoTotalDia = data.montoTotal;
      _modoEjemplo = true;
      _error = mensaje;
      _loading = false;
      _sincronizarSeleccion();
    });
  }

  void _sincronizarSeleccion() {
    final visibles = _ventasFiltradas;
    if (visibles.isEmpty) {
      _idSeleccionada = null;
      return;
    }
    final sigueVisible = visibles.any((v) => v.idVenta == _idSeleccionada);
    if (!sigueVisible) {
      _idSeleccionada = visibles.first.idVenta;
    }
  }

  bool get _hayFiltros =>
      _choferCtrl.text.trim().isNotEmpty ||
      _clienteCtrl.text.trim().isNotEmpty ||
      _estadoFiltro != null;

  List<VentaMonitoreo> get _ventasFiltradas {
    final chofer = _choferCtrl.text.trim().toLowerCase();
    final cliente = _clienteCtrl.text.trim().toLowerCase();

    return _ventas.where((v) {
      if (chofer.isNotEmpty && !v.choferNombre.toLowerCase().contains(chofer)) {
        return false;
      }
      if (cliente.isNotEmpty && !v.clienteNombre.toLowerCase().contains(cliente)) {
        return false;
      }
      if (_estadoFiltro != null && v.estado != _estadoFiltro) {
        return false;
      }
      return true;
    }).toList();
  }

  VentaMonitoreo? get _ventaSeleccionada {
    for (final v in _ventasFiltradas) {
      if (v.idVenta == _idSeleccionada) return v;
    }
    return null;
  }

  Future<void> _elegirFecha() async {
    final elegida = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2023),
      lastDate: DateTime(2100),
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
    if (elegida != null) {
      setState(() => _fecha = elegida);
      _cargar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = Responsive.isDesktop(constraints);
        final dosColumnas = constraints.maxWidth >= 1200;
        final padding = EdgeInsets.all(isDesktop ? 28 : 16);

        if (dosColumnas) {
          return Padding(
            padding: padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ..._encabezadoYFiltros(),
                const SizedBox(height: 20),
                Expanded(child: _contenidoDosColumnas()),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ..._encabezadoYFiltros(),
              const SizedBox(height: 20),
              _contenidoApilado(),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _encabezadoYFiltros() {
    return [
      _Cabecera(
        cantidad: _ventasFiltradas.length,
        montoTotal: _montoTotalDia,
        onRefrescar: _cargar,
      ),
      const SizedBox(height: 20),
      VentasFiltrosBar(
        choferController: _choferCtrl,
        clienteController: _clienteCtrl,
        estadoSeleccionado: _estadoFiltro,
        onEstadoChanged: (estado) {
          setState(() {
            _estadoFiltro = estado;
            _sincronizarSeleccion();
          });
        },
        fecha: _fecha,
        onTapFecha: _elegirFecha,
      ),
      if (_error != null) ...[
        const SizedBox(height: 16),
        _AvisoBanner(mensaje: _error!, esEjemplo: _modoEjemplo),
      ],
    ];
  }

  Widget _tabla(bool scrollInterno) {
    return _TarjetaTabla(
      cantidad: _ventasFiltradas.length,
      scrollInterno: scrollInterno,
      child: VentasTabla(
        ventas: _ventasFiltradas,
        idSeleccionada: _idSeleccionada,
        onSeleccionar: (venta) => setState(() => _idSeleccionada = venta.idVenta),
        mensajeVacio: _hayFiltros
            ? 'No hay ventas que coincidan con los filtros.'
            : 'No hay ventas registradas para esta jornada.',
      ),
    );
  }

  Widget _contenidoDosColumnas() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.orange));
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: _tabla(true)),
        const SizedBox(width: 20),
        SizedBox(width: 340, child: VentaDetallePanel(venta: _ventaSeleccionada)),
      ],
    );
  }

  Widget _contenidoApilado() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 80),
        child: Center(child: CircularProgressIndicator(color: AppColors.orange)),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _tabla(false),
        const SizedBox(height: 20),
        VentaDetallePanel(venta: _ventaSeleccionada, scrollable: false),
      ],
    );
  }
}

class _Cabecera extends StatelessWidget {
  final int cantidad;
  final int montoTotal;
  final VoidCallback onRefrescar;

  const _Cabecera({
    required this.cantidad,
    required this.montoTotal,
    required this.onRefrescar,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Consola de Ventas', style: AppTextStyles.desktopTitle),
              const SizedBox(height: 4),
              Text(
                'Monitoreo diario de ventas con el desglose de cilindros entregados y retribuidos.',
                style: AppTextStyles.desktopSubtitle,
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        _ResumenChip(
          etiqueta: 'Total del día',
          valor: formatMoneda(montoTotal),
        ),
        const SizedBox(width: 12),
        IconButton(
          onPressed: onRefrescar,
          tooltip: 'Actualizar',
          icon: const Icon(Icons.refresh, color: AppColors.steelBlue),
        ),
      ],
    );
  }
}

class _ResumenChip extends StatelessWidget {
  final String etiqueta;
  final String valor;

  const _ResumenChip({required this.etiqueta, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            etiqueta,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.graphiteGray,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            valor,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.orange,
            ),
          ),
        ],
      ),
    );
  }
}

class _TarjetaTabla extends StatelessWidget {
  final int cantidad;
  final bool scrollInterno;
  final Widget child;

  const _TarjetaTabla({
    required this.cantidad,
    required this.scrollInterno,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            child: Row(
              children: [
                const Text('Consola de Ventas', style: AppTextStyles.label),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.steelBlue.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$cantidad',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.steelBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (scrollInterno)
            Flexible(child: SingleChildScrollView(child: child))
          else
            child,
        ],
      ),
    );
  }
}

class _AvisoBanner extends StatelessWidget {
  final String mensaje;
  final bool esEjemplo;

  const _AvisoBanner({required this.mensaje, required this.esEjemplo});

  @override
  Widget build(BuildContext context) {
    final color = esEjemplo ? AppColors.badgeAmber : AppColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Icon(
            esEjemplo ? Icons.info_outline : Icons.error_outline,
            size: 19,
            color: color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              mensaje,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
