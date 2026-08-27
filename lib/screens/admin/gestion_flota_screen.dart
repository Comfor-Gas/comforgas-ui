import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/responsive.dart';
import '../../data/mock_flota_data.dart';
import '../../models/deposito_camion.dart';
import '../../models/movimiento_stock.dart';
import '../../models/producto_catalogo.dart';
import '../../models/usuario_model.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/catalogo_repository.dart';
import '../../repositories/flota_repository.dart';
import '../../repositories/network_exception.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/admin/flota/asignacion_camion_modal.dart';
import '../../widgets/admin/flota/flota_form_controls.dart';
import '../../widgets/admin/flota/flota_stat_card.dart';
import '../../widgets/admin/flota/flota_tabla.dart';
import '../../widgets/admin/flota/historial_recargas_panel.dart';
import '../../widgets/admin/flota/recarga_faltante_modal.dart';

class GestionFlotaScreen extends StatefulWidget {
  const GestionFlotaScreen({super.key});

  @override
  State<GestionFlotaScreen> createState() => _GestionFlotaScreenState();
}

class _GestionFlotaScreenState extends State<GestionFlotaScreen> {
  late final FlotaRepository _flotaRepo;
  late final CatalogoRepository _catalogoRepo;

  final _patenteCtrl = TextEditingController();
  final _choferCtrl = TextEditingController();

  bool _loading = true;
  bool _modoEjemplo = false;
  String? _aviso;

  List<DepositoCamion> _camiones = [];
  List<UsuarioModel> _choferes = [];
  List<ProductoCatalogo> _productos = [];
  int? _depositoCentralId;

  @override
  void initState() {
    super.initState();
    final apiClient = context.read<AuthProvider>().apiClient;
    _flotaRepo = FlotaRepository(apiClient);
    _catalogoRepo = CatalogoRepository(apiClient);
    _patenteCtrl.addListener(() => setState(() {}));
    _choferCtrl.addListener(() => setState(() {}));
    _cargar();
  }

  @override
  void dispose() {
    _patenteCtrl.dispose();
    _choferCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() {
      _loading = true;
      _aviso = null;
    });

    try {
      final camiones = await _flotaRepo.listarCamiones();
      final conStock = await Future.wait(camiones.map(_conStock));
      await _cargarCatalogos();
      if (!mounted) return;
      setState(() {
        _camiones = conStock;
        _modoEjemplo = false;
        _loading = false;
      });
    } on NetworkException {
      _usarEjemplo('No se pudo conectar con el servidor: mostrando datos de ejemplo.');
    } on FlotaRepositoryException catch (e) {
      if (e.endpointNoDisponible) {
        _usarEjemplo(
          'El módulo de flota todavía no está disponible en el backend: mostrando datos de ejemplo.',
        );
      } else {
        _usarEjemplo(e.message);
      }
    } catch (_) {
      _usarEjemplo('Ocurrió un problema al cargar la flota: mostrando datos de ejemplo.');
    }
  }

  Future<DepositoCamion> _conStock(DepositoCamion camion) async {
    try {
      final stock = await _flotaRepo.getStockCamion(camion.id);
      int llenos = 0;
      int vacios = 0;
      for (final item in stock.items) {
        final estado = item.estadoCodigo.toUpperCase();
        if (estado == 'LLENA') {
          llenos += item.cantidad;
        } else if (estado == 'VACIA') {
          vacios += item.cantidad;
        }
      }
      return camion.copyWith(llenos: llenos, vacios: vacios, stockCargado: true);
    } catch (_) {
      return camion;
    }
  }

  Future<void> _cargarCatalogos() async {
    try {
      _choferes = await _catalogoRepo.listarUsuarios(rol: 'CHOFER');
    } catch (_) {
      _choferes = _choferes.isEmpty ? _choferesDesdeCamiones() : _choferes;
    }
    try {
      _productos = await _flotaRepo.listarProductos();
    } catch (_) {
      if (_productos.isEmpty) _productos = productosFlotaDeEjemplo();
    }
    if (_productos.isEmpty) _productos = productosFlotaDeEjemplo();
    try {
      final centrales = await _flotaRepo.listarDepositosCentrales();
      if (centrales.isNotEmpty) _depositoCentralId = centrales.first.id;
    } catch (_) {}
  }

  List<UsuarioModel> _choferesDesdeCamiones() {
    final vistos = <String>{};
    final lista = <UsuarioModel>[];
    for (final c in _camiones) {
      final r = c.repartidor;
      if (r != null && vistos.add(r.id)) {
        lista.add(UsuarioModel(id: r.id, email: r.email, fullName: r.nombre, rol: 'CHOFER'));
      }
    }
    return lista;
  }

  void _usarEjemplo(String mensaje) {
    if (!mounted) return;
    setState(() {
      _camiones = camionesFlotaDeEjemplo();
      _productos = productosFlotaDeEjemplo();
      _choferes = _choferesDesdeCamiones();
      _modoEjemplo = true;
      _aviso = mensaje;
      _loading = false;
    });
  }

  List<DepositoCamion> get _camionesFiltrados {
    final patente = _patenteCtrl.text.trim().toLowerCase();
    final chofer = _choferCtrl.text.trim().toLowerCase();
    return _camiones.where((c) {
      if (patente.isNotEmpty && !c.patenteVisible.toLowerCase().contains(patente)) {
        return false;
      }
      if (chofer.isNotEmpty && !c.choferNombre.toLowerCase().contains(chofer)) {
        return false;
      }
      return true;
    }).toList();
  }

  int get _totalLlenos => _camiones.fold(0, (a, c) => a + c.llenos);
  int get _totalVacios => _camiones.fold(0, (a, c) => a + c.vacios);

  void _mostrarSnack(String mensaje, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: error ? AppColors.error : AppColors.badgeGreen,
      ),
    );
  }

  void _abrirNuevaAsignacion() {
    AsignacionCamionModal.mostrar(
      context,
      camiones: _camiones,
      choferes: _choferes,
      productos: _productos,
      onConfirmar: _confirmarAsignacion,
    );
  }

  Future<bool> _confirmarAsignacion({
    required DepositoCamion camion,
    required String choferId,
    required List<Map<String, dynamic>> items,
  }) async {
    if (_modoEjemplo) {
      _actualizarLocalAsignacion(camion, choferId, items);
      _mostrarSnack('Asignación registrada (ejemplo).');
      return true;
    }
    try {
      await _flotaRepo.asignarChofer(camion, repartidorId: choferId);
      final central = _depositoCentralId;
      if (items.isNotEmpty && central != null) {
        await _flotaRepo.recargarCamion(
          camion.id,
          depositoCentralId: central,
          items: items,
          observaciones: 'Carga inicial de despacho',
        );
      }
      _mostrarSnack('Camión asignado y despachado.');
      await _cargar();
      return true;
    } on FlotaRepositoryException catch (e) {
      _mostrarSnack(e.message, error: true);
      return false;
    } catch (_) {
      _mostrarSnack('No se pudo completar la asignación.', error: true);
      return false;
    }
  }

  void _actualizarLocalAsignacion(
    DepositoCamion camion,
    String choferId,
    List<Map<String, dynamic>> items,
  ) {
    final chofer = _choferes.where((c) => c.id == choferId).cast<UsuarioModel?>().firstWhere(
          (c) => c != null,
          orElse: () => null,
        );
    final total = items.fold<int>(0, (a, i) => a + ((i['cantidad'] as int?) ?? 0));
    setState(() {
      _camiones = [
        for (final c in _camiones)
          if (c.id == camion.id)
            c.copyWith(
              repartidor: chofer != null
                  ? RepartidorInfo(id: chofer.id, nombre: chofer.fullName, email: chofer.email)
                  : c.repartidor,
              llenos: total > 0 ? total : c.llenos,
              stockCargado: true,
            )
          else
            c,
      ];
    });
  }

  void _abrirRecarga(DepositoCamion camion) {
    RecargaFaltanteModal.mostrar(
      context,
      camion: camion,
      productos: _productos,
      onConfirmar: ({required productoId, required cantidad, observaciones}) =>
          _confirmarRecarga(camion, productoId, cantidad, observaciones),
    );
  }

  Future<bool> _confirmarRecarga(
    DepositoCamion camion,
    String productoId,
    int cantidad,
    String? observaciones,
  ) async {
    if (_modoEjemplo) {
      setState(() {
        _camiones = [
          for (final c in _camiones)
            if (c.id == camion.id)
              c.copyWith(llenos: c.llenos + cantidad, stockCargado: true)
            else
              c,
        ];
      });
      _mostrarSnack('Recarga registrada (ejemplo).');
      return true;
    }
    final central = _depositoCentralId;
    if (central == null) {
      _mostrarSnack(
        'No hay un depósito central configurado para originar la carga.',
        error: true,
      );
      return false;
    }
    try {
      await _flotaRepo.recargarCamion(
        camion.id,
        depositoCentralId: central,
        items: [
          {'productoId': productoId, 'cantidad': cantidad},
        ],
        observaciones: observaciones,
      );
      _mostrarSnack('Recarga registrada.');
      await _cargar();
      return true;
    } on FlotaRepositoryException catch (e) {
      _mostrarSnack(e.message, error: true);
      return false;
    } catch (_) {
      _mostrarSnack('No se pudo registrar la recarga.', error: true);
      return false;
    }
  }

  void _abrirHistorial(DepositoCamion camion) {
    HistorialRecargasPanel.mostrar(
      context,
      camion: camion,
      cargar: () => _cargarHistorial(camion),
    );
  }

  Future<List<MovimientoStock>> _cargarHistorial(DepositoCamion camion) async {
    if (_modoEjemplo) return historialRecargasDeEjemplo();
    return _flotaRepo.historialRecargas(camion.id);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = Responsive.isDesktop(constraints);
        final padding = EdgeInsets.all(isDesktop ? 28 : 16);
        return SingleChildScrollView(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Cabecera(onNuevaAsignacion: _abrirNuevaAsignacion, onRefrescar: _cargar),
              const SizedBox(height: 20),
              _FiltrosFlota(patenteCtrl: _patenteCtrl, choferCtrl: _choferCtrl),
              const SizedBox(height: 16),
              _StatsFlota(
                camiones: _camiones.length,
                llenos: _totalLlenos,
                vacios: _totalVacios,
              ),
              if (_aviso != null) ...[
                const SizedBox(height: 16),
                _AvisoBanner(mensaje: _aviso!, esEjemplo: _modoEjemplo),
              ],
              const SizedBox(height: 20),
              _TarjetaTabla(
                cantidad: _camionesFiltrados.length,
                child: _loading
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 60),
                        child: Center(child: CircularProgressIndicator(color: AppColors.orange)),
                      )
                    : FlotaTabla(
                        camiones: _camionesFiltrados,
                        onRecargar: _abrirRecarga,
                        onVerHistorial: _abrirHistorial,
                        mensajeVacio: _camiones.isEmpty
                            ? 'No hay camiones registrados.'
                            : 'No hay camiones que coincidan con los filtros.',
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Cabecera extends StatelessWidget {
  final VoidCallback onNuevaAsignacion;
  final VoidCallback onRefrescar;

  const _Cabecera({required this.onNuevaAsignacion, required this.onRefrescar});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Gestión de Flota', style: AppTextStyles.desktopTitle),
              const SizedBox(height: 4),
              Text(
                'Control de stock en camiones respecto al cupo base de $kCupoBaseCamion garrafas.',
                style: AppTextStyles.desktopSubtitle,
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        IconButton(
          onPressed: onRefrescar,
          tooltip: 'Actualizar',
          icon: const Icon(Icons.refresh, color: AppColors.steelBlue),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 190,
          child: FlotaBotonPrimario(
            texto: 'Nueva Asignación',
            icono: Icons.add,
            onTap: onNuevaAsignacion,
          ),
        ),
      ],
    );
  }
}

class _FiltrosFlota extends StatelessWidget {
  final TextEditingController patenteCtrl;
  final TextEditingController choferCtrl;

  const _FiltrosFlota({required this.patenteCtrl, required this.choferCtrl});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        SizedBox(
          width: 260,
          child: _CampoBusqueda(
            controller: patenteCtrl,
            hint: 'Buscar por patente',
            icono: Icons.local_shipping_outlined,
          ),
        ),
        SizedBox(
          width: 260,
          child: _CampoBusqueda(
            controller: choferCtrl,
            hint: 'Buscar por chofer',
            icono: Icons.person_outline,
          ),
        ),
      ],
    );
  }
}

class _CampoBusqueda extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icono;

  const _CampoBusqueda({
    required this.controller,
    required this.hint,
    required this.icono,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: TextField(
        controller: controller,
        style: AppTextStyles.input,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTextStyles.hint,
          prefixIcon: Icon(icono, color: AppColors.inputHint, size: 20),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close, color: AppColors.inputHint, size: 18),
                  onPressed: controller.clear,
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

class _StatsFlota extends StatelessWidget {
  final int camiones;
  final int llenos;
  final int vacios;

  const _StatsFlota({
    required this.camiones,
    required this.llenos,
    required this.vacios,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tres = constraints.maxWidth >= 720;
        final cards = [
          FlotaStatCard(
            icon: Icons.local_shipping_outlined,
            etiqueta: 'Camiones Totales',
            valor: '$camiones',
            acento: AppColors.steelBlue,
          ),
          FlotaStatCard(
            icon: Icons.propane_tank_outlined,
            etiqueta: 'Total Stock Llenos',
            valor: '$llenos',
            acento: AppColors.badgeGreen,
          ),
          FlotaStatCard(
            icon: Icons.replay_outlined,
            etiqueta: 'Vacías en Ruta',
            valor: '$vacios',
            acento: AppColors.orange,
          ),
        ];
        if (tres) {
          return Row(
            children: [
              for (int i = 0; i < cards.length; i++) ...[
                if (i > 0) const SizedBox(width: 16),
                Expanded(child: cards[i]),
              ],
            ],
          );
        }
        return Column(
          children: [
            for (int i = 0; i < cards.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              cards[i],
            ],
          ],
        );
      },
    );
  }
}

class _TarjetaTabla extends StatelessWidget {
  final int cantidad;
  final Widget child;

  const _TarjetaTabla({required this.cantidad, required this.child});

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
                const Text('Monitoreo Diario', style: AppTextStyles.label),
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
          Icon(esEjemplo ? Icons.info_outline : Icons.error_outline, size: 19, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              mensaje,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color),
            ),
          ),
        ],
      ),
    );
  }
}
