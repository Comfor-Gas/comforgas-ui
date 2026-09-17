import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/responsive.dart';
import '../../data/mock_flota_data.dart';
import '../../models/deposito_camion.dart';
import '../../models/movimiento_stock.dart';
import '../../models/nota_control_stock.dart';
import '../../models/producto_catalogo.dart';
import '../../models/usuario_model.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/catalogo_repository.dart';
import '../../repositories/flota_repository.dart';
import '../../repositories/network_exception.dart';
import '../../repositories/stock_rodante_admin_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/admin/flota/asignacion_camion_modal.dart';
import '../../widgets/admin/flota/entrada_movil_modal.dart';
import '../../widgets/admin/flota/flota_form_controls.dart';
import '../../widgets/admin/flota/flota_stat_card.dart';
import '../../widgets/admin/flota/flota_tabla.dart';
import '../../widgets/admin/flota/historial_recargas_panel.dart';
import '../../widgets/admin/flota/nota_control_stock_modal.dart';
import '../../widgets/admin/flota/recarga_faltante_modal.dart';
import '../../widgets/admin/flota/reporte_cuadre_modal.dart';

class GestionFlotaScreen extends StatefulWidget {
  const GestionFlotaScreen({super.key});

  @override
  State<GestionFlotaScreen> createState() => _GestionFlotaScreenState();
}

class _GestionFlotaScreenState extends State<GestionFlotaScreen> {
  late final FlotaRepository _flotaRepo;
  late final CatalogoRepository _catalogoRepo;
  late final StockRodanteAdminRepository _rodanteRepo;

  final _patenteCtrl = TextEditingController();
  final _choferCtrl = TextEditingController();

  bool _loading = true;
  bool _modoEjemplo = false;
  String? _aviso;

  List<DepositoCamion> _camiones = [];
  List<UsuarioModel> _choferes = [];
  List<ProductoCatalogo> _productos = [];
  int _vaciasRetornadasHoy = 0;
  Map<String, int> _asignadoPorChofer = {};
  Map<String, NotaRodanteResumen> _notaPorChofer = {};
  DateTime _fecha = DateTime.now();

  @override
  void initState() {
    super.initState();
    final apiClient = context.read<AuthProvider>().apiClient;
    _flotaRepo = FlotaRepository(apiClient);
    _catalogoRepo = CatalogoRepository(apiClient);
    _rodanteRepo = StockRodanteAdminRepository(apiClient);
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
      final resumen = await _flotaRepo.getResumenFlota(fecha: _fecha);
      await _cargarCatalogos();
      Map<String, int> asignado = {};
      Map<String, NotaRodanteResumen> notas = {};
      try {
        asignado = await _rodanteRepo.asignadoLlenosPorChofer(_fecha);
        for (final n in await _rodanteRepo.notasDelDia(_fecha)) {
          final id = n.idUsuario;
          if (id != null && id.isNotEmpty) notas[id] = n;
        }
      } catch (_) {
        asignado = {};
        notas = {};
      }
      if (!mounted) return;
      setState(() {
        _camiones = resumen.camiones;
        _vaciasRetornadasHoy = resumen.vaciasRetornadasHoy;
        _asignadoPorChofer = asignado;
        _notaPorChofer = notas;
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
      _vaciasRetornadasHoy = _camiones.fold(0, (a, c) => a + c.vacios);
      _asignadoPorChofer = {
        for (final c in _camiones)
          if (c.repartidor != null) c.repartidor!.id: c.llenos,
      };
      _notaPorChofer = {};
      _modoEjemplo = true;
      _aviso = mensaje;
      _loading = false;
    });
  }

  Future<void> _elegirFecha() async {
    final elegida = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime.now().add(const Duration(days: 7)),
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
    if (elegida == null) return;
    final distinta = elegida.year != _fecha.year ||
        elegida.month != _fecha.month ||
        elegida.day != _fecha.day;
    if (distinta) {
      setState(() => _fecha = elegida);
      _cargar();
    }
  }

  void _abrirReporte(DepositoCamion camion) {
    final id = camion.repartidor?.id;
    final nota = (id != null && id.isNotEmpty) ? _notaPorChofer[id] : null;
    if (nota == null) {
      _mostrarSnack(
        'No hay una nota de stock para este camión en la fecha seleccionada.',
        error: true,
      );
      return;
    }
    ReporteCuadreModal.mostrar(context, cargar: () => _rodanteRepo.getCuadre(nota.idNota));
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

  int get _llenosCargadosHoy =>
      _asignadoPorChofer.values.fold(0, (a, v) => a + v);

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
      if (items.isNotEmpty) {
        final dominio = camion.patente;
        if (dominio == null || dominio.isEmpty) {
          _mostrarSnack(
            'Camión asignado. Cargá la patente del camión para poder despachar el stock.',
            error: true,
          );
          await _cargar();
          return true;
        }
        final rodanteItems = [
          for (final i in items)
            {
              'idProducto': (i['productoId'] ?? i['idProducto'] ?? '').toString(),
              'sku': _skuDeProducto((i['productoId'] ?? i['idProducto'] ?? '').toString()),
              'llenosSalida': (i['cantidad'] as int?) ?? 0,
              'vaciosSalida': 0,
            },
        ];
        await _rodanteRepo.asignarCargaInicial(
          idUsuario: choferId,
          dominioVehiculo: dominio,
          fecha: DateTime.now(),
          items: rodanteItems,
          observaciones: 'Carga inicial de despacho',
        );
      }
      _mostrarSnack('Camión asignado y despachado.');
      await _cargar();
      return true;
    } on FlotaRepositoryException catch (e) {
      _mostrarSnack(e.message, error: true);
      return false;
    } on StockRodanteAdminException catch (e) {
      _mostrarSnack(e.message, error: true);
      return false;
    } on NetworkException {
      _mostrarSnack('Sin conexión: no se pudo completar la asignación.', error: true);
      return false;
    } catch (_) {
      _mostrarSnack('No se pudo completar la asignación.', error: true);
      return false;
    }
  }

  String _skuDeProducto(String idProducto) {
    for (final p in _productos) {
      if (p.idProducto == idProducto) {
        return p.sku.isNotEmpty ? p.sku : idProducto;
      }
    }
    return idProducto;
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

  void _abrirNotaControl(DepositoCamion camion) {
    NotaControlStockModal.mostrar(
      context,
      camion: camion,
      productos: _productos,
      fechaInicial: _fecha,
      onConfirmar: (draft) => _confirmarNotaControl(camion, draft),
    );
  }

  Future<bool> _confirmarNotaControl(DepositoCamion camion, NotaControlStockDraft draft) async {
    final idUsuario = camion.repartidor?.id;
    final dominio = camion.patente;
    if (idUsuario == null || idUsuario.isEmpty) {
      _mostrarSnack('Asigná un chofer al camión antes de cargar el stock.', error: true);
      return false;
    }
    if (dominio == null || dominio.isEmpty) {
      _mostrarSnack('El camión no tiene patente/dominio cargado.', error: true);
      return false;
    }

    final items = [
      for (final l in draft.lineas)
        if (l.llenos > 0 || l.vacios > 0)
          {
            'idProducto': l.producto.idProducto,
            'sku': l.producto.sku,
            'llenosSalida': l.llenos,
            'vaciosSalida': l.vacios,
          },
    ];
    if (items.isEmpty) {
      _mostrarSnack('Ingresá al menos una garrafa para asignar la carga.', error: true);
      return false;
    }

    if (_modoEjemplo) {
      setState(() {
        _camiones = [
          for (final c in _camiones)
            if (c.id == camion.id)
              c.copyWith(llenos: c.llenos + draft.totalLlenos, vacios: c.vacios + draft.totalVacios, stockCargado: true)
            else
              c,
        ];
      });
      _mostrarSnack('Carga inicial asignada (ejemplo).');
      return true;
    }
    try {
      final nota = await _rodanteRepo.asignarCargaInicial(
        idUsuario: idUsuario,
        dominioVehiculo: dominio,
        fecha: draft.fecha,
        items: items,
        observaciones: draft.observaciones,
      );
      final folio = nota.numeroNota;
      _mostrarSnack(folio != null && folio.isNotEmpty
          ? 'Carga inicial asignada. Nota $folio'
          : 'Carga inicial asignada al chofer.');
      await _cargar();
      return true;
    } on StockRodanteAdminException catch (e) {
      _mostrarSnack(e.message, error: true);
      return false;
    } on NetworkException {
      _mostrarSnack('Sin conexión: no se pudo asignar la carga.', error: true);
      return false;
    } catch (_) {
      _mostrarSnack('No se pudo asignar la carga inicial.', error: true);
      return false;
    }
  }

  void _abrirEntradaMovil(DepositoCamion camion) {
    EntradaMovilModal.mostrar(
      context,
      camion: camion,
      productos: _productos,
      backendPendiente: false,
      onConfirmar: (draft) => _confirmarEntradaMovil(camion, draft),
      cargarResumen: () => _cargarResumenCierre(camion),
    );
  }

  Future<ResumenCierreCamion> _cargarResumenCierre(DepositoCamion camion) async {
    if (_modoEjemplo) return const ResumenCierreCamion();
    try {
      final resultados = await Future.wait([
        _flotaRepo.ventasDelDia(camion.id),
        _flotaRepo.stockLlenoPorProducto(camion.id),
      ]);
      return ResumenCierreCamion(
        vendidasHoy: resultados[0],
        stockLlenoActual: resultados[1],
      );
    } catch (_) {
      return const ResumenCierreCamion();
    }
  }

  Future<bool> _confirmarEntradaMovil(DepositoCamion camion, EntradaMovilDraft draft) async {
    if (_modoEjemplo) {
      setState(() {
        _vaciasRetornadasHoy += draft.totalVacios;
        _camiones = [
          for (final c in _camiones)
            if (c.id == camion.id) c.copyWith(vacios: c.vacios + draft.totalVacios) else c,
        ];
      });
      _mostrarSnack('Entrada del móvil registrada (ejemplo).');
      return true;
    }

    try {
      final idNota = await _rodanteRepo.resolverIdNota(
        fecha: _fecha,
        idUsuario: camion.repartidor?.id,
        dominioVehiculo: camion.patente,
      );
      if (idNota == null) {
        _mostrarSnack(
          'No hay una carga asignada hoy para este camión. Asigná primero la carga inicial.',
          error: true,
        );
        return false;
      }
      final items = [
        for (final l in draft.lineas)
          if (l.llenos > 0 || l.vacios > 0 || l.averiados > 0)
            {
              'idProducto': l.producto.idProducto,
              'sku': l.producto.sku,
              'llenosEntrada': l.llenos,
              'vaciosEntrada': l.vacios,
              'averiadosEntrada': l.averiados,
            },
      ];
      if (items.isEmpty) {
        _mostrarSnack('No hay unidades para registrar en la entrada.', error: true);
        return false;
      }
      await _rodanteRepo.registrarEntrada(idNota, items: items, observaciones: draft.observaciones);
      _mostrarSnack('Entrada del móvil registrada.');
      await _cargar();
      return true;
    } on StockRodanteAdminException catch (e) {
      _mostrarSnack(e.message, error: true);
      return false;
    } on NetworkException {
      _mostrarSnack('Sin conexión: no se pudo registrar la entrada.', error: true);
      return false;
    } catch (_) {
      _mostrarSnack('No se pudo registrar la entrada del móvil.', error: true);
      return false;
    }
  }

  void _abrirRecarga(DepositoCamion camion) {
    RecargaFaltanteModal.mostrar(
      context,
      camion: camion,
      productos: _productos,
      onConfirmar: ({required items, observaciones}) =>
          _confirmarRecarga(camion, items, observaciones),
    );
  }

  Future<bool> _confirmarRecarga(
    DepositoCamion camion,
    List<Map<String, dynamic>> items,
    String? observaciones,
  ) async {
    final total = items.fold<int>(0, (a, i) => a + ((i['cantidad'] as int?) ?? 0));
    if (_modoEjemplo) {
      setState(() {
        _camiones = [
          for (final c in _camiones)
            if (c.id == camion.id)
              c.copyWith(llenos: c.llenos + total, stockCargado: true)
            else
              c,
        ];
      });
      _mostrarSnack('Recarga registrada (ejemplo).');
      return true;
    }
    try {
      final idNota = await _rodanteRepo.resolverIdNota(
        fecha: _fecha,
        idUsuario: camion.repartidor?.id,
        dominioVehiculo: camion.patente,
      );
      if (idNota == null) {
        _mostrarSnack(
          'No hay una carga asignada hoy para este camión. Asigná primero la carga inicial.',
          error: true,
        );
        return false;
      }
      final rodanteItems = [
        for (final i in items)
          if (((i['cantidad'] as int?) ?? 0) > 0)
            {
              'idProducto': (i['idProducto'] ?? i['productoId'] ?? '').toString(),
              'sku': (i['sku'] ?? i['productoCodigo'] ?? '').toString(),
              'cantidad': (i['cantidad'] as int?) ?? 0,
            },
      ];
      if (rodanteItems.isEmpty) {
        _mostrarSnack('Ingresá una cantidad para recargar.', error: true);
        return false;
      }
      await _rodanteRepo.registrarRecarga(idNota, items: rodanteItems, observaciones: observaciones);
      _mostrarSnack('Recarga registrada.');
      await _cargar();
      return true;
    } on StockRodanteAdminException catch (e) {
      _mostrarSnack(e.message, error: true);
      return false;
    } on NetworkException {
      _mostrarSnack('Sin conexión: no se pudo registrar la recarga.', error: true);
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
              const SizedBox(height: 12),
              _SelectorFecha(fecha: _fecha, onTap: _elegirFecha),
              const SizedBox(height: 16),
              _StatsFlota(
                camiones: _camiones.length,
                llenos: _llenosCargadosHoy,
                vaciasRetornadas: _vaciasRetornadasHoy,
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
                        asignadoPorChofer: _asignadoPorChofer,
                        notaPorChofer: _notaPorChofer,
                        onNota: _abrirNotaControl,
                        onRecargaRuta: _abrirRecarga,
                        onEntradaMovil: _abrirEntradaMovil,
                        onVerHistorial: _abrirHistorial,
                        onVerReporte: _abrirReporte,
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

class _SelectorFecha extends StatelessWidget {
  final DateTime fecha;
  final VoidCallback onTap;

  const _SelectorFecha({required this.fecha, required this.onTap});

  bool get _esHoy {
    final hoy = DateTime.now();
    return fecha.year == hoy.year && fecha.month == hoy.month && fecha.day == hoy.day;
  }

  String get _texto {
    final d = fecha.day.toString().padLeft(2, '0');
    final m = fecha.month.toString().padLeft(2, '0');
    return '$d/$m/${fecha.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.inputBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.orange),
              const SizedBox(width: 8),
              Text('Día:', style: AppTextStyles.footer.copyWith(color: AppColors.graphiteGray)),
              const SizedBox(width: 6),
              Text(
                _esHoy ? 'Hoy · $_texto' : _texto,
                style: AppTextStyles.label.copyWith(fontSize: 13.5),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.expand_more, size: 18, color: AppColors.inputHint),
            ],
          ),
        ),
      ),
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
                'Control de stock y carga de garrafas en los camiones.',
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
  final int vaciasRetornadas;

  const _StatsFlota({
    required this.camiones,
    required this.llenos,
    required this.vaciasRetornadas,
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
            etiqueta: 'Llenos Cargados Hoy',
            valor: '$llenos',
            acento: AppColors.badgeGreen,
          ),
          FlotaStatCard(
            icon: Icons.replay_outlined,
            etiqueta: 'Vacías Retornadas Hoy',
            valor: '$vaciasRetornadas',
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
