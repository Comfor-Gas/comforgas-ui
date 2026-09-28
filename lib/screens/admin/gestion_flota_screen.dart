import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/responsive.dart';
import '../../data/mock_flota_data.dart';
import '../../models/deposito_camion.dart';
import '../../models/movimiento_stock.dart';
import '../../models/nota_control_stock.dart';
import '../../models/producto_catalogo.dart';
import '../../models/stock_rodante_chofer.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/flota_repository.dart';
import '../../repositories/network_exception.dart';
import '../../repositories/producto_repository.dart';
import '../../repositories/stock_rodante_admin_repository.dart';
import '../../repositories/visita_repository.dart';
import '../../services/nota_rodante_mapper.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/admin/flota/entrada_movil_modal.dart';
import '../../widgets/admin/flota/flota_stat_card.dart';
import '../../widgets/admin/flota/flota_tabla.dart';
import '../../widgets/admin/flota/historial_recargas_panel.dart';
import '../../widgets/admin/flota/nota_control_stock_modal.dart';
import '../../widgets/admin/flota/recarga_faltante_modal.dart';
import '../../widgets/admin/flota/reporte_cuadre_modal.dart';
import '../../widgets/common/carga/zona_carga.dart';
import '../../widgets/common/filtros/filtros.dart';
import '../../core/feedback/app_feedback.dart';

class GestionFlotaScreen extends StatefulWidget {
  const GestionFlotaScreen({super.key});

  @override
  State<GestionFlotaScreen> createState() => _GestionFlotaScreenState();
}

class _GestionFlotaScreenState extends State<GestionFlotaScreen> {
  static const _mapper = NotaRodanteMapper();

  late final FlotaRepository _flotaRepo;
  late final StockRodanteAdminRepository _rodanteRepo;
  late final ProductoRepository _productoRepo;
  late final VisitaRepository _visitaRepo;

  final _patenteCtrl = TextEditingController();
  final _choferCtrl = TextEditingController();

  bool _loading = true;
  bool _modoEjemplo = false;
  String? _aviso;

  List<DepositoCamion> _camiones = [];
  List<ProductoCatalogo> _productos = [];
  int _vaciasRetornadasHoy = 0;
  Map<String, StockRodanteChofer> _notaPorChofer = {};
  DateTime _fecha = DateTime.now();

  @override
  void initState() {
    super.initState();
    final apiClient = context.read<AuthProvider>().apiClient;
    _flotaRepo = FlotaRepository(apiClient);
    _rodanteRepo = StockRodanteAdminRepository(apiClient);
    _productoRepo = ProductoRepository(apiClient);
    _visitaRepo = VisitaRepository(apiClient);
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

    await _cargarCatalogos();
    List<StockRodanteChofer> notas;
    try {
      notas = await _rodanteRepo.notasDelDia(_fecha);
    } on NetworkException {
      _usarEjemplo('No se pudo conectar con el servidor: mostrando datos de ejemplo.');
      return;
    } catch (_) {
      notas = const [];
    }

    List<DepositoCamion> camiones;
    String? aviso;
    try {
      camiones = await _flotaRepo.getResumenFlota(fecha: _fecha);
    } on NetworkException {
      _usarEjemplo('No se pudo conectar con el servidor: mostrando datos de ejemplo.');
      return;
    } on FlotaRepositoryException catch (e) {
      camiones = _camionesDesdeNotas(notas);
      aviso = e.endpointNoDisponible
          ? 'El listado de camiones no está disponible en el backend: se muestran los camiones con nota de stock del día.'
          : e.message;
    } catch (_) {
      camiones = _camionesDesdeNotas(notas);
      aviso = 'No se pudo cargar el listado de camiones: se muestran los camiones con nota de stock del día.';
    }

    final porChofer = _indexarPorChofer(notas);
    if (!mounted) return;
    setState(() {
      _camiones = camiones;
      _vaciasRetornadasHoy = porChofer.values
          .where((n) => n.cerrada)
          .fold(0, (a, n) => a + n.totalVaciosEntrada);
      _notaPorChofer = porChofer;
      _modoEjemplo = false;
      _aviso = aviso;
      _loading = false;
    });
    unawaited(_enriquecerConAgenda(_fecha));
  }

  List<DepositoCamion> _camionesDesdeNotas(List<StockRodanteChofer> notas) {
    final camiones = <DepositoCamion>[];
    for (final n in notas) {
      final idChofer = n.idUsuario;
      camiones.add(DepositoCamion(
        id: n.idNota ?? camiones.length,
        nombre: n.dominioVehiculo ?? 'Camión',
        patente: n.dominioVehiculo,
        repartidor: idChofer == null || idChofer.isEmpty
            ? null
            : RepartidorInfo(id: idChofer, nombre: n.nombreChofer ?? '', email: ''),
      ));
    }
    return camiones;
  }

  Future<void> _enriquecerConAgenda(DateTime fecha) async {
    final base = _camiones;
    if (base.isEmpty || _modoEjemplo) return;

    final resultados = List<DepositoCamion>.from(base);
    await Future.wait(base.asMap().entries.map((entry) async {
      final i = entry.key;
      final camion = entry.value;
      final idChofer = camion.repartidor?.id;
      if (idChofer == null || idChofer.isEmpty) return;
      try {
        final items = await _visitaRepo.getVisitasPorUsuarioYFecha(
          idUsuario: idChofer,
          fecha: fecha,
        );
        String? vendedor;
        String? patente;
        for (final it in items) {
          final v = it.vendedor?.trim();
          final p = it.patente?.trim();
          if (vendedor == null && v != null && v.isNotEmpty) vendedor = v;
          if (patente == null && p != null && p.isNotEmpty) patente = p;
          if (vendedor != null && patente != null) break;
        }
        if (vendedor == null && patente == null) return;
        resultados[i] = camion.copyWith(
          patente: patente,
          repartidor: vendedor != null
              ? RepartidorInfo(
                  id: camion.repartidor!.id,
                  nombre: vendedor,
                  email: camion.repartidor!.email,
                )
              : null,
        );
      } catch (_) {}
    }));

    if (!mounted) return;
    setState(() => _camiones = resultados);
  }

  Map<String, StockRodanteChofer> _indexarPorChofer(List<StockRodanteChofer> notas) {
    final mapa = <String, StockRodanteChofer>{};
    for (final n in notas) {
      final id = n.idUsuario;
      if (id == null || id.isEmpty) continue;
      final previa = mapa[id];
      if (previa == null || (previa.cerrada && !n.cerrada)) mapa[id] = n;
    }
    return mapa;
  }

  Future<StockRodanteChofer?> _notaVigente(DepositoCamion camion, {bool refrescar = false}) async {
    final idChofer = camion.repartidor?.id;
    var nota = (idChofer != null && idChofer.isNotEmpty) ? _notaPorChofer[idChofer] : null;
    if (nota == null) {
      final notas = await _rodanteRepo.notasDelDia(_fecha);
      final dominio = camion.patente?.trim().toUpperCase();
      for (final n in notas) {
        final mismoChofer = idChofer != null && idChofer.isNotEmpty && n.idUsuario == idChofer;
        final mismoDominio = dominio != null &&
            dominio.isNotEmpty &&
            (n.dominioVehiculo ?? '').toUpperCase() == dominio;
        if (mismoChofer || mismoDominio) {
          nota = n;
          if (!n.cerrada) break;
        }
      }
      return nota;
    }
    if (refrescar && nota.idNota != null) {
      return _rodanteRepo.nota(nota.idNota!);
    }
    return nota;
  }

  Future<void> _cargarCatalogos() async {
    try {
      _productos = await _productoRepo.listar();
    } catch (_) {
      if (_productos.isEmpty) _productos = productosFlotaDeEjemplo();
    }
    if (_productos.isEmpty) _productos = productosFlotaDeEjemplo();
  }

  void _usarEjemplo(String mensaje) {
    if (!mounted) return;
    setState(() {
      _camiones = camionesFlotaDeEjemplo();
      _productos = productosFlotaDeEjemplo();
      _vaciasRetornadasHoy = _camiones.fold(0, (a, c) => a + c.vacios);
      _notaPorChofer = {};
      _modoEjemplo = true;
      _aviso = mensaje;
      _loading = false;
    });
  }

  void _cambiarFecha(DateTime elegida) {
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
    final idNota = nota.idNota;
    if (idNota == null) return;
    ReporteCuadreModal.mostrar(context, cargar: () => _rodanteRepo.getCuadre(idNota));
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
      _notaPorChofer.values.fold(0, (a, n) => a + n.totalLlenosCargados);

  void _mostrarSnack(String mensaje, {bool error = false}) {
    if (error) {
      AppFeedback.error(mensaje);
    } else {
      AppFeedback.exito(mensaje);
    }
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
      _mostrarSnack('Este camión todavía no tiene un chofer asignado en el sistema.', error: true);
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
      final nota = await _notaVigente(camion, refrescar: true);
      return _mapper.resumenCierre(nota, _productos);
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
      final nota = await _notaVigente(camion);
      final idNota = nota?.idNota;
      if (nota == null || idNota == null) {
        _mostrarSnack(
          'No hay una carga asignada hoy para este camión. Asigná primero la carga inicial.',
          error: true,
        );
        return false;
      }
      if (nota.cerrada) {
        _mostrarSnack('La nota de este camión ya está cerrada.', error: true);
        return false;
      }
      final items = _mapper.itemsCierre(nota, draft.lineas);
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
      final nota = await _notaVigente(camion);
      final idNota = nota?.idNota;
      if (nota == null || idNota == null) {
        _mostrarSnack(
          'No hay una carga asignada hoy para este camión. Asigná primero la carga inicial.',
          error: true,
        );
        return false;
      }
      if (nota.cerrada) {
        _mostrarSnack('La nota de este camión ya está cerrada: no admite recargas.', error: true);
        return false;
      }
      final cantidades = <String, int>{};
      for (final i in items) {
        final id = (i['idProducto'] ?? i['productoId'] ?? '').toString();
        final cantidad = (i['cantidad'] as int?) ?? 0;
        if (id.isNotEmpty && cantidad > 0) cantidades[id] = (cantidades[id] ?? 0) + cantidad;
      }
      final rodanteItems = _mapper.itemsRecarga(nota, _productos, cantidades);
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
      fecha: _fecha,
      cargar: () => _cargarHistorial(camion),
    );
  }

  Future<List<MovimientoStock>> _cargarHistorial(DepositoCamion camion) async {
    if (_modoEjemplo) return historialRecargasDeEjemplo();
    final nota = await _notaVigente(camion, refrescar: true);
    final idNota = nota?.idNota;
    if (nota == null || idNota == null) return [];
    try {
      final eventos = await _rodanteRepo.movimientos(idNota);
      final historial = _mapper.historialDesdeEventos(nota, eventos);
      if (historial.isNotEmpty) return historial;
    } on StockRodanteAdminException {
      return _mapper.historialCargas(nota);
    }
    return _mapper.historialCargas(nota);
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
              ReportarCarga(cargando: _loading),
              const _Cabecera(),
              const SizedBox(height: 20),
              _FiltrosFlota(
                patenteCtrl: _patenteCtrl,
                choferCtrl: _choferCtrl,
                fecha: _fecha,
                cargando: _loading,
                onCambioFecha: _cambiarFecha,
                onRefrescar: _cargar,
              ),
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
                    ? const SizedBox(height: 160)
                    : FlotaTabla(
                        camiones: _camionesFiltrados,
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

class _Cabecera extends StatelessWidget {
  const _Cabecera();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Gestión de Flota', style: AppTextStyles.desktopTitle),
        const SizedBox(height: 4),
        Text(
          'El chofer y su vehículo vienen de la API. Acá asignás y controlás el stock de garrafas de cada camión.',
          style: AppTextStyles.desktopSubtitle,
        ),
      ],
    );
  }
}

class _FiltrosFlota extends StatelessWidget {
  final TextEditingController patenteCtrl;
  final TextEditingController choferCtrl;
  final DateTime fecha;
  final bool cargando;
  final ValueChanged<DateTime> onCambioFecha;
  final VoidCallback onRefrescar;

  const _FiltrosFlota({
    required this.patenteCtrl,
    required this.choferCtrl,
    required this.fecha,
    required this.cargando,
    required this.onCambioFecha,
    required this.onRefrescar,
  });

  bool get _hayBusqueda =>
      patenteCtrl.text.trim().isNotEmpty || choferCtrl.text.trim().isNotEmpty;

  void _limpiar() {
    patenteCtrl.clear();
    choferCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final hoy = DateTime.now();
    return FiltrosPanel(
      filas: [
        SelectorFechaUnica(
          fecha: fecha,
          etiqueta: 'Día',
          incluirManiana: true,
          primera: DateTime(hoy.year - 1),
          ultima: hoy.add(const Duration(days: 7)),
          onCambio: onCambioFecha,
        ),
        FilaFiltros(
          children: [
            CampoBusquedaFiltro(
              controller: patenteCtrl,
              etiqueta: 'Patente',
              hint: 'Buscar por patente',
              icono: Icons.local_shipping_outlined,
              ancho: 260,
            ),
            CampoBusquedaFiltro(
              controller: choferCtrl,
              etiqueta: 'Chofer',
              hint: 'Buscar por chofer',
              icono: Icons.person_outline,
              ancho: 260,
            ),
            if (_hayBusqueda) BotonLimpiarFiltros(onPressed: _limpiar),
            BotonActualizar(onPressed: onRefrescar, cargando: cargando),
          ],
        ),
      ],
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
