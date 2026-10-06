import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/ruta_model.dart';
import '../../models/sucursal_model.dart';
import '../../models/usuario_model.dart';
import '../../models/visita_estado.dart';
import '../../models/visita_model.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/catalogo_repository.dart';
import '../../repositories/visita_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/json_parsing.dart';
import '../../widgets/admin/estado_visita_badge.dart';
import '../../widgets/common/carga/zona_carga.dart';
import '../../widgets/common/filtros/filtros.dart';
import '../../widgets/primary_button.dart';
import '../../core/feedback/app_feedback.dart';
import '../../core/responsive.dart';

class _AgendaRow {
  final VisitaModel visita;
  final bool esBorrador;

  const _AgendaRow({required this.visita, required this.esBorrador});
}

class PlanificacionVisitasScreen extends StatefulWidget {
  const PlanificacionVisitasScreen({super.key});

  @override
  State<PlanificacionVisitasScreen> createState() =>
      _PlanificacionVisitasScreenState();
}

class _PlanificacionVisitasScreenState
    extends State<PlanificacionVisitasScreen> {
  late final VisitaRepository _repo;
  late final CatalogoRepository _catalogoRepo;

  bool _loading = true;
  bool _publishing = false;
  String? _loadError;

  List<VisitaModel> _serverVisitas = [];
  final List<VisitaModel> _draftVisitas = [];

  bool _loadingCatalogos = true;
  String? _catalogoError;
  List<UsuarioModel> _choferes = [];
  List<SucursalModel> _sucursales = [];
  List<RutaModel> _rutas = [];

  final _choferFilterCtrl = TextEditingController();
  final _clienteFilterCtrl = TextEditingController();
  DateTime? _fechaFilter;
  bool _fechaPorCreacion = false;

  int _sortColumnIndex = 1;
  bool _sortAsc = true;

  UsuarioModel? _formChofer;
  DateTime? _formFecha;
  SucursalModel? _formSucursal;
  RutaModel? _formRuta;
  String? _formError;

  @override
  void initState() {
    super.initState();
    _fechaFilter = _hoyFechaSola();
    _repo = VisitaRepository(context.read<AuthProvider>().apiClient);
    _catalogoRepo = CatalogoRepository(context.read<AuthProvider>().apiClient);
    _choferFilterCtrl.addListener(() => setState(() {}));
    _clienteFilterCtrl.addListener(() => setState(() {}));
    _loadCatalogos().then((_) {
      if (mounted) _loadVisitas();
    });
  }

  @override
  void dispose() {
    _choferFilterCtrl.dispose();
    _clienteFilterCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCatalogos() async {
    setState(() {
      _loadingCatalogos = true;
      _catalogoError = null;
    });
    try {
      final results = await Future.wait([
        _catalogoRepo.listarUsuarios(rol: 'CHOFER'),
        _catalogoRepo.listarClientes(),
        _catalogoRepo.listarRutas(),
      ]);
      if (!mounted) return;
      setState(() {
        _choferes = results[0] as List<UsuarioModel>;
        _sucursales = results[1] as List<SucursalModel>;
        _rutas = results[2] as List<RutaModel>;
        _loadingCatalogos = false;
      });
    } on CatalogoRepositoryException catch (e) {
      if (!mounted) return;
      setState(() {
        _catalogoError = e.message;
        _loadingCatalogos = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _catalogoError =
            'No se pudieron cargar los catálogos de choferes/clientes/rutas.';
        _loadingCatalogos = false;
      });
    }
  }

  Future<void> _loadVisitas() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      if (_choferes.isEmpty) {
        _choferes = await _catalogoRepo.listarUsuarios(rol: 'CHOFER');
      }
      final fecha = _fechaFilter ?? _hoyFechaSola();
      final resultados = await Future.wait(
        _choferes.map(
          (ch) => _repo
              .getVisitasPorUsuarioYFecha(idUsuario: ch.id, fecha: fecha)
              .then((items) => items.map((i) => i.toVisitaModel(ch.id)).toList())
              .catchError((_) => <VisitaModel>[]),
        ),
      );
      if (!mounted) return;
      final agenda = <VisitaModel>[];
      for (final lista in resultados) {
        agenda.addAll(lista);
      }
      setState(() {
        _serverVisitas = agenda;
        _loading = false;
      });
    } on CatalogoRepositoryException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadError = 'No se pudo cargar la agenda por chofer.';
        _loading = false;
      });
    }
  }

  String _clienteNombre(VisitaModel v) {
    final snapshot = v.sucursalSnapshot;
    for (final key in ['nombre', 'nombreSucursal', 'razonSocial', 'cliente']) {
      final value = snapshot[key];
      if (value is String && value.trim().isNotEmpty) return value;
    }
    return 'Cliente #${v.idSucursal}';
  }

  String _rutaNombre(VisitaModel v) {
    for (final r in _rutas) {
      if (r.idRuta == v.idRuta) return r.nombre;
    }
    final snapshot = v.rutaSnapshot;
    for (final key in ['nombre', 'nombreRuta', 'ruta']) {
      final value = snapshot[key];
      if (value is String && value.trim().isNotEmpty) return value;
    }
    return 'Ruta #${v.idRuta}';
  }

  String _formatDisplayDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd/$mm/${d.year}';
  }

  DateTime _hoyFechaSola() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  bool _esMismoDia(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }


  String _initials(String nombre) {
    final parts = nombre.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  List<_AgendaRow> get _filteredSortedRows {
    final choferQuery = _choferFilterCtrl.text.trim().toLowerCase();
    final clienteQuery = _clienteFilterCtrl.text.trim().toLowerCase();

    final rows = [
      ..._draftVisitas.map((v) => _AgendaRow(visita: v, esBorrador: true)),
      ..._serverVisitas.map((v) => _AgendaRow(visita: v, esBorrador: false)),
    ].where((row) {
      final nombreChofer = (row.visita.nombreChoferMostrado ?? '').toLowerCase();
      if (choferQuery.isNotEmpty && !nombreChofer.contains(choferQuery)) {
        return false;
      }

      final nombreCliente = _clienteNombre(row.visita).toLowerCase();
      if (clienteQuery.isNotEmpty && !nombreCliente.contains(clienteQuery)) {
        return false;
      }

      if (_fechaFilter != null) {
        final fecha = _fechaPorCreacion ? row.visita.createdAt : row.visita.fecha;
        if (fecha == null ||
            fecha.year != _fechaFilter!.year ||
            fecha.month != _fechaFilter!.month ||
            fecha.day != _fechaFilter!.day) {
          return false;
        }
      }

      return true;
    }).toList();

    int compare(_AgendaRow a, _AgendaRow b) {
      switch (_sortColumnIndex) {
        case 0:
          return (a.visita.nombreChoferMostrado ?? '')
              .compareTo(b.visita.nombreChoferMostrado ?? '');
        case 2:
          return _clienteNombre(a.visita).compareTo(_clienteNombre(b.visita));
        default:
          final fa = a.visita.fecha ?? DateTime(0);
          final fb = b.visita.fecha ?? DateTime(0);
          return fa.compareTo(fb);
      }
    }

    rows.sort((a, b) => _sortAsc ? compare(a, b) : compare(b, a));
    return rows;
  }

  int _siguienteOrden(String idChofer, DateTime fecha) {
    var maxOrden = 0;
    for (final v in [..._draftVisitas, ..._serverVisitas]) {
      final f = v.fecha;
      final mismoChoferYDia = v.idUsuario == idChofer &&
          f != null &&
          f.year == fecha.year &&
          f.month == fecha.month &&
          f.day == fecha.day;
      if (mismoChoferYDia && v.ordenVisita > maxOrden) {
        maxOrden = v.ordenVisita;
      }
    }
    return maxOrden + 1;
  }

  void _handleGuardar() {
    if (_formChofer == null ||
        _formFecha == null ||
        _formSucursal == null ||
        _formRuta == null) {
      setState(() =>
          _formError = 'Completá chofer, fecha, sucursal y ruta.');
      return;
    }

    final chofer = _formChofer!;
    final fecha = _formFecha!;
    final sucursal = _formSucursal!;
    final ruta = _formRuta!;

    final draft = VisitaModel(
      idUsuario: chofer.id,
      nombreUsuario: chofer.fullName,
      idSucursal: sucursal.idSucursal,
      idRuta: ruta.idRuta,
      sucursalSnapshot: {
        'nombre': sucursal.nombre,
        if (sucursal.direccion != null) 'direccion': sucursal.direccion,
        if (sucursal.barrio != null) 'barrio': sucursal.barrio,
        if (sucursal.ciudad != null) 'ciudad': sucursal.ciudad,
        if (sucursal.telefono != null) 'telefono': sucursal.telefono,
        if (sucursal.latitud != null) 'latitud': sucursal.latitud,
        if (sucursal.longitud != null) 'longitud': sucursal.longitud,
      },
      rutaSnapshot: {
        'nombre': ruta.nombre,
        'chofer': chofer.fullName,
        'fecha_ruta': formatDateOnly(fecha),
      },
      ordenVisita: _siguienteOrden(chofer.id, fecha),
      estadoVisita: VisitaEstado.pendiente,
      fecha: fecha,
    );

    setState(() {
      _draftVisitas.insert(0, draft);
      _formSucursal = null;
      _formRuta = null;
      _formError = null;
    });

    if (mounted) {
      AppFeedback.info(
        'Publicá la agenda del día para confirmarla.',
        titulo: 'Visita agregada como borrador',
      );
    }
  }

  Future<void> _handlePublicar() async {
    if (_draftVisitas.isEmpty) {
      AppFeedback.advertencia(
        'No hay visitas nuevas para publicar. Agregá al menos una desde el formulario.',
        titulo: 'Nada para publicar',
      );
      return;
    }

    setState(() => _publishing = true);

    try {
      final result = await _repo.importarAgenda(List.of(_draftVisitas));
      if (!mounted) return;
      setState(() {
        _draftVisitas.clear();
        _publishing = false;
      });
      await _loadVisitas();
      if (!mounted) return;
      final resumen = 'Insertadas: ${result.insertadas} · Omitidas: ${result.omitidas}';
      if (result.errores.isEmpty) {
        AppFeedback.exito(resumen, titulo: 'Visitas publicadas');
      } else {
        AppFeedback.advertencia(
          '$resumen\n${result.errores.join('\n')}',
          titulo: 'Visitas publicadas con observaciones',
        );
      }
    } on VisitaRepositoryException catch (e) {
      if (!mounted) return;
      setState(() => _publishing = false);
      AppFeedback.error(e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _publishing = false);
      AppFeedback.error('No se pudieron publicar las visitas.');
    }
  }

  Future<void> _handleSincronizar() async {
    setState(() => _formError = null);

    final chofer = _formChofer;
    final fecha = _formFecha ?? _fechaFilter ?? _hoyFechaSola();
    final fechaTexto = _formatDisplayDate(fecha);
    final quien = chofer != null ? chofer.fullName : 'todos los choferes';

    setState(() => _publishing = true);

    try {
      final result = chofer != null
          ? await _repo.sincronizarAgenda(choferId: chofer.id, fecha: fecha)
          : await _repo.sincronizarAgendaTodos(fecha: fecha);
      if (!mounted) return;
      setState(() {
        _publishing = false;
        _draftVisitas.removeWhere((v) =>
            v.fecha != null &&
            _esMismoDia(v.fecha!, fecha) &&
            (chofer == null || v.idUsuario == chofer.id));
      });
      await _loadVisitas();
      if (!mounted) return;

      final hayErrores = result.errores.isNotEmpty;
      if (hayErrores && result.insertadas == 0 && result.omitidas == 0) {
        AppFeedback.error(
          result.errores.join('\n'),
          titulo: 'Error en la sincronización',
        );
      } else if (result.insertadas > 0 && result.omitidas == 0) {
        AppFeedback.exito(
          'Se cargaron ${result.insertadas} visita(s) para $quien el $fechaTexto.',
          titulo: 'Agenda sincronizada',
        );
      } else if (result.insertadas == 0 && result.omitidas > 0) {
        AppFeedback.info(
          'Se actualizaron ${result.omitidas} visita(s) existentes para $quien el $fechaTexto.',
          titulo: 'Agenda actualizada',
        );
      } else if (result.insertadas == 0 && result.omitidas == 0) {
        AppFeedback.info(
          'No se encontraron visitas en la agenda para $quien el $fechaTexto.',
          titulo: 'Sin visitas',
        );
      } else {
        AppFeedback.info(
          'Se cargaron ${result.insertadas} visita(s) nuevas y se actualizaron ${result.omitidas} para $quien el $fechaTexto.',
          titulo: 'Agenda sincronizada parcialmente',
        );
      }
      if (hayErrores && (result.insertadas > 0 || result.omitidas > 0)) {
        AppFeedback.advertencia(
          result.errores.join('\n'),
          titulo: 'La sincronización tuvo errores',
        );
      }
    } on VisitaRepositoryException catch (e) {
      if (!mounted) return;
      setState(() => _publishing = false);
      AppFeedback.error(e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _publishing = false);
      AppFeedback.error('No se pudo sincronizar la agenda.');
    }
  }

  Future<void> _handleEditar(_AgendaRow row) async {
    if (!row.esBorrador) return;
    final hoy = _hoyFechaSola();
    final fechaInicial = row.visita.fecha ?? DateTime.now();
    final nuevaFecha = await showDatePicker(
      context: context,
      initialDate: fechaInicial.isBefore(hoy) ? hoy : fechaInicial,
      firstDate: hoy,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (nuevaFecha == null) return;

    setState(() {
      final index = _draftVisitas.indexOf(row.visita);
      if (index != -1) {
        _draftVisitas[index] = row.visita.copyWith(fecha: nuevaFecha);
      }
    });
  }

  Future<void> _handleEliminar(_AgendaRow row) async {
    if (!row.esBorrador) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Quitar del borrador', style: AppTextStyles.title),
        content: Text(
          '¿Querés quitar la visita de "${_clienteNombre(row.visita)}" del borrador?',
          style: AppTextStyles.input,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('Volver', style: AppTextStyles.link),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              'Quitar',
              style: AppTextStyles.button.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    setState(() => _draftVisitas.remove(row.visita));
  }

  Widget _buildPublicarSection() {
    final count = _draftVisitas.length;
    final hay = count > 0;
    final plural = count == 1 ? '' : 's';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: hay
                ? AppColors.orange.withOpacity(0.08)
                : AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hay
                  ? AppColors.orange.withOpacity(0.4)
                  : AppColors.inputBorder,
            ),
          ),
          child: Row(
            children: [
              Icon(
                hay ? Icons.playlist_add_check : Icons.info_outline,
                size: 18,
                color: hay ? AppColors.orange : AppColors.graphiteGray,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  hay
                      ? 'Tenés $count visita$plural en borrador sin publicar. '
                          'Revisá la lista y publicá para confirmar la agenda del día.'
                      : 'No hay visitas en borrador. Agregá visitas con '
                          '"Agregar a la lista" y luego publicá la agenda del día.',
                  style: AppTextStyles.link.copyWith(
                    color: AppColors.graphiteGray,
                    fontSize: 12.5,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        PrimaryButton(
          text: hay
              ? 'Publicar $count visita$plural del día'
              : 'Publicar Visitas del Día',
          isLoading: _publishing,
          onPressed: hay ? _handlePublicar : null,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomSafePadding = MediaQuery.of(context).padding.bottom;
    final mobile = Responsive.isMobileContext(context);
    final pad = mobile ? 16.0 : 24.0;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(pad, pad, pad, pad + bottomSafePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ReportarCarga(cargando: _loading || _loadingCatalogos),
          Text(
            'Planificación Diaria de Visitas',
            style: mobile
                ? AppTextStyles.desktopTitle.copyWith(fontSize: 22)
                : AppTextStyles.desktopTitle,
          ),
          const SizedBox(height: 4),
          Text(
            'Armá y publicá la agenda de visitas de cada chofer para el día.',
            style: AppTextStyles.desktopSubtitle,
          ),
          const SizedBox(height: 20),
          _FiltrosCard(
            choferCtrl: _choferFilterCtrl,
            clienteCtrl: _clienteFilterCtrl,
            fecha: _fechaFilter,
            onFechaChanged: (d) {
              setState(() => _fechaFilter = d);
              _loadVisitas();
            },
            porCreacion: _fechaPorCreacion,
            onModoChanged: (v) => setState(() => _fechaPorCreacion = v),
            onLimpiar: () {
              _choferFilterCtrl.clear();
              _clienteFilterCtrl.clear();
            },
            onActualizar: _loadVisitas,
            cargando: _loading,
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 1000;
              final listado = _ListadoCard(
                loading: _loading,
                error: _loadError,
                rows: _filteredSortedRows,
                sortColumnIndex: _sortColumnIndex,
                sortAsc: _sortAsc,
                onSort: (columnIndex, asc) => setState(() {
                  _sortColumnIndex = columnIndex;
                  _sortAsc = asc;
                }),
                onRetry: _loadVisitas,
                clienteNombreOf: _clienteNombre,
                rutaNombreOf: _rutaNombre,
                formatFecha: _formatDisplayDate,
                initialsOf: _initials,
                onEditar: _handleEditar,
                onEliminar: _handleEliminar,
              );
              final formulario = _FormularioCard(
                chofer: _formChofer,
                fecha: _formFecha,
                sucursal: _formSucursal,
                ruta: _formRuta,
                error: _formError,
                choferes: _choferes,
                sucursales: _sucursales,
                rutas: _rutas,
                loadingCatalogos: _loadingCatalogos,
                catalogoError: _catalogoError,
                onReintentarCatalogos: _loadCatalogos,
                onChoferChanged: (c) => setState(() => _formChofer = c),
                onFechaChanged: (d) => setState(() => _formFecha = d),
                onSucursalChanged: (s) => setState(() => _formSucursal = s),
                onRutaChanged: (r) => setState(() => _formRuta = r),
                onGuardar: _handleGuardar,
                onSincronizar: _handleSincronizar,
                sincronizando: _publishing,
              );

              if (wide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 65,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: listado,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 35,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          formulario,
                          const SizedBox(height: 20),
                          _buildPublicarSection(),
                        ],
                      ),
                    ),
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  listado,
                  SizedBox(height: mobile ? 16 : 20),
                  formulario,
                  SizedBox(height: mobile ? 16 : 24),
                  _buildPublicarSection(),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CardContainer extends StatelessWidget {
  final Widget child;

  const _CardContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(Responsive.isMobileContext(context) ? 16 : 20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: child,
    );
  }
}

class _FiltrosCard extends StatelessWidget {
  final TextEditingController choferCtrl;
  final TextEditingController clienteCtrl;
  final DateTime? fecha;
  final ValueChanged<DateTime?> onFechaChanged;
  final bool porCreacion;
  final ValueChanged<bool> onModoChanged;
  final VoidCallback onLimpiar;
  final VoidCallback onActualizar;
  final bool cargando;

  const _FiltrosCard({
    required this.choferCtrl,
    required this.clienteCtrl,
    required this.fecha,
    required this.onFechaChanged,
    required this.porCreacion,
    required this.onModoChanged,
    required this.onLimpiar,
    required this.onActualizar,
    required this.cargando,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final mobile = Responsive.isMobileContext(context);
    final hayBusqueda =
        choferCtrl.text.trim().isNotEmpty || clienteCtrl.text.trim().isNotEmpty;
    return FiltrosPanel(
      filas: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SelectorFechaUnica(
              fecha: fecha,
              onCambio: onFechaChanged,
              etiqueta: porCreacion ? 'Fecha de creación' : 'Fecha planificada',
              incluirManiana: true,
              ultima: now.add(const Duration(days: 365)),
              onSinFecha: () => onFechaChanged(null),
              etiquetaSinFecha: 'Todas las fechas',
            ),
          ],
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const EtiquetaFiltro('Filtrar fecha por'),
            ChipFiltro(
              etiqueta: 'Planificada',
              activo: !porCreacion,
              onTap: () => onModoChanged(false),
            ),
            ChipFiltro(
              etiqueta: 'Creación',
              activo: porCreacion,
              onTap: () => onModoChanged(true),
            ),
          ],
        ),
        FilaFiltros(
          children: [
            CampoBusquedaFiltro(
              controller: choferCtrl,
              etiqueta: 'Chofer',
              hint: 'Nombre del chofer',
              icono: Icons.person_search_outlined,
              ancho: mobile ? double.infinity : 280,
            ),
            CampoBusquedaFiltro(
              controller: clienteCtrl,
              etiqueta: 'Cliente',
              hint: 'Nombre del cliente o sucursal',
              icono: Icons.storefront_outlined,
              ancho: mobile ? double.infinity : 300,
            ),
            if (hayBusqueda) BotonLimpiarFiltros(onPressed: onLimpiar),
            BotonActualizar(onPressed: onActualizar, cargando: cargando),
          ],
        ),
      ],
    );
  }
}

class _ListadoCard extends StatelessWidget {
  final bool loading;
  final String? error;
  final List<_AgendaRow> rows;
  final int sortColumnIndex;
  final bool sortAsc;
  final void Function(int columnIndex, bool asc) onSort;
  final VoidCallback onRetry;
  final String Function(VisitaModel) clienteNombreOf;
  final String Function(VisitaModel) rutaNombreOf;
  final String Function(DateTime) formatFecha;
  final String Function(String) initialsOf;
  final void Function(_AgendaRow) onEditar;
  final void Function(_AgendaRow) onEliminar;

  const _ListadoCard({
    required this.loading,
    required this.error,
    required this.rows,
    required this.sortColumnIndex,
    required this.sortAsc,
    required this.onSort,
    required this.onRetry,
    required this.clienteNombreOf,
    required this.rutaNombreOf,
    required this.formatFecha,
    required this.initialsOf,
    required this.onEditar,
    required this.onEliminar,
  });

  // Debajo de este ancho se usa el listado en tarjetas (mobile/tablet real).
  // Por encima, la tabla ya entra achicando columnas y separación — no hace
  // falta pasar a tarjetas en un panel de escritorio normal.
  static const double _compactBreakpoint = 640;

  @override
  Widget build(BuildContext context) {
    return _CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Listado de Agendas por Chofer',
              style: AppTextStyles.title.copyWith(fontSize: 17)),
          const SizedBox(height: 16),
          if (loading)
            const SizedBox(height: 120)
          else if (error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Column(
                children: [
                  Text(error!, style: AppTextStyles.errorText, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: onRetry,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.steelBlue,
                      side: const BorderSide(color: AppColors.steelBlue),
                    ),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            )
          else if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Center(
                child: Text(
                  'No hay visitas que coincidan con los filtros.',
                  style: AppTextStyles.link.copyWith(color: AppColors.graphiteGray),
                ),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < _compactBreakpoint;
                return isCompact ? _buildCardsList(context) : _buildTable(context);
              },
            ),
        ],
      ),
    );
  }
Widget _buildTable(BuildContext context) {
    final horizontalScrollController = ScrollController();
    return SizedBox(
      height: 520,
      child: Scrollbar(
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: LayoutBuilder(
            builder: (context, tableConstraints) {
              return Scrollbar(
                controller: horizontalScrollController,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: horizontalScrollController,
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: tableConstraints.maxWidth,
                  ),
                  child: DataTable(
                    columnSpacing: 14,
                    horizontalMargin: 10,
                    dataRowMinHeight: 60,
                    dataRowMaxHeight: 60,
                    sortColumnIndex: sortColumnIndex,
                    sortAscending: sortAsc,
                    headingRowColor: MaterialStateProperty.all(AppColors.background),
                    columns: [
                      DataColumn(
                        label: const Text('Chofer'),
                        onSort: (i, asc) => onSort(i, asc),
                      ),
                      DataColumn(
                        label: const Text('Fecha'),
                        onSort: (i, asc) => onSort(i, asc),
                      ),
                      DataColumn(
                        label: const Text('Cliente'),
                        onSort: (i, asc) => onSort(i, asc),
                      ),
                      const DataColumn(label: Text('Ruta')),
                      const DataColumn(label: Text('Estado')),
                      const DataColumn(label: Text('Acciones')),
                    ],
                    rows: rows.map((row) {
                      final nombreChofer = row.visita.nombreChoferMostrado ?? 'Sin asignar';
                      final fecha = row.visita.fecha;
                      final clienteNombre = clienteNombreOf(row.visita);
                      final rutaNombre = rutaNombreOf(row.visita);
                      return DataRow(cells: [
                        DataCell(Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 13,
                              backgroundColor: AppColors.steelBlue.withOpacity(0.12),
                              child: Text(
                                initialsOf(nombreChofer),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.steelBlue,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 92),
                              child: Tooltip(
                                message: nombreChofer,
                                child: Text(
                                  nombreChofer,
                                  style: AppTextStyles.input,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        )),
                        DataCell(Text(
                          fecha == null ? '—' : formatFecha(fecha),
                          style: AppTextStyles.input,
                        )),
                        DataCell(ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 160),
                          child: Tooltip(
                            message: clienteNombre,
                            child: Text(
                              clienteNombre,
                              style: AppTextStyles.input,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )),
                        DataCell(ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 90),
                          child: Tooltip(
                            message: rutaNombre,
                            child: Text(
                              rutaNombre,
                              style: AppTextStyles.input,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )),
                        DataCell(EstadoVisitaBadge(
                          estado: row.visita.estadoVisita,
                          esBorrador: row.esBorrador,
                        )),
                        DataCell(Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (row.esBorrador)
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 19),
                                color: AppColors.steelBlue,
                                onPressed: () => onEditar(row),
                              ),
                            if (row.esBorrador)
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 19),
                                color: AppColors.error,
                                onPressed: () => onEliminar(row),
                              ),
                          ],
                        )),
                      ]);
                    }).toList(),
                  ),
                ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }


  Widget _buildCardsList(BuildContext context) {
    if (Responsive.isMobileContext(context)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            _buildCardItem(rows[i], compactPadding: true),
          ],
        ],
      );
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 480),
      child: Scrollbar(
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: rows.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) => _buildCardItem(rows[index]),
        ),
      ),
    );
  }

  Widget _buildCardItem(_AgendaRow row, {bool compactPadding = false}) {
    final nombreChofer = row.visita.nombreChoferMostrado ?? 'Sin asignar';
    final fecha = row.visita.fecha;

    return Container(
      padding: EdgeInsets.all(compactPadding ? 12 : 14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.steelBlue.withOpacity(0.12),
                child: Text(
                  initialsOf(nombreChofer),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.steelBlue,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  nombreChofer,
                  style: AppTextStyles.input.copyWith(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              EstadoVisitaBadge(
                estado: row.visita.estadoVisita,
                esBorrador: row.esBorrador,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _CardInfoLine(
            label: 'Fecha',
            value: fecha == null ? '—' : formatFecha(fecha),
          ),
          const SizedBox(height: 6),
          _CardInfoLine(label: 'Cliente', value: clienteNombreOf(row.visita)),
          const SizedBox(height: 6),
          _CardInfoLine(label: 'Ruta', value: rutaNombreOf(row.visita)),
          if (row.esBorrador) ...[
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (row.esBorrador)
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 19),
                    color: AppColors.steelBlue,
                    onPressed: () => onEditar(row),
                  ),
                if (row.esBorrador)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 19),
                    color: AppColors.error,
                    onPressed: () => onEliminar(row),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _CardInfoLine extends StatelessWidget {
  final String label;
  final String value;

  const _CardInfoLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 64,
          child: Text(
            label,
            style: AppTextStyles.label.copyWith(fontSize: 12, color: AppColors.graphiteGray),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.input,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _FormularioCard extends StatelessWidget {
  final UsuarioModel? chofer;
  final DateTime? fecha;
  final SucursalModel? sucursal;
  final RutaModel? ruta;
  final String? error;
  final List<UsuarioModel> choferes;
  final List<SucursalModel> sucursales;
  final List<RutaModel> rutas;
  final bool loadingCatalogos;
  final String? catalogoError;
  final VoidCallback onReintentarCatalogos;
  final ValueChanged<UsuarioModel?> onChoferChanged;
  final ValueChanged<DateTime?> onFechaChanged;
  final ValueChanged<SucursalModel?> onSucursalChanged;
  final ValueChanged<RutaModel?> onRutaChanged;
  final VoidCallback onGuardar;
  final VoidCallback onSincronizar;
  final bool sincronizando;
  final bool camposHabilitados;

  const _FormularioCard({
    required this.chofer,
    required this.fecha,
    required this.sucursal,
    required this.ruta,
    required this.error,
    required this.choferes,
    required this.sucursales,
    required this.rutas,
    required this.loadingCatalogos,
    required this.catalogoError,
    required this.onReintentarCatalogos,
    required this.onChoferChanged,
    required this.onFechaChanged,
    required this.onSucursalChanged,
    required this.onRutaChanged,
    required this.onGuardar,
    required this.onSincronizar,
    this.sincronizando = false,
    this.camposHabilitados = false,
  });

  @override
  Widget build(BuildContext context) {
    final mobile = Responsive.isMobileContext(context);
    final botonSincronizar = OutlinedButton.icon(
      onPressed: sincronizando ? null : onSincronizar,
      icon: sincronizando
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.orange),
            )
          : const Icon(Icons.sync, size: 18),
      label: const Text('Sincronizar agenda'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.steelBlue,
        side: BorderSide(color: AppColors.steelBlue),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    final botonAgregar = ElevatedButton.icon(
      onPressed: camposHabilitados ? onGuardar : null,
      icon: const Icon(Icons.playlist_add, size: 18),
      label: const Text('Agregar a la lista'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.steelBlue,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.inputBorder,
        disabledForegroundColor: AppColors.inputHint,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    return _CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Asignar choferes', style: AppTextStyles.title.copyWith(fontSize: 17)),
          const SizedBox(height: 4),
          Text('Nueva Asignación', style: AppTextStyles.desktopSubtitle),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.steelBlue.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline,
                    size: 16, color: AppColors.steelBlue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    camposHabilitados
                        ? '"Agregar a la lista": deja como borrador en el listado.'
                            ' Usá "Publicar Visitas del Día" para confirmarlas en el sistema.'
                        : 'Las visitas ahora se cargan automáticamente desde la API.'
                            ' Usá "Sincronizar agenda" para traer la agenda del día.',
                    style: AppTextStyles.link.copyWith(
                      color: AppColors.steelBlue,
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('Campos', style: AppTextStyles.label),
          const SizedBox(height: 10),
          IgnorePointer(
            ignoring: !camposHabilitados,
            child: Opacity(
              opacity: camposHabilitados ? 1 : 0.5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
          if (camposHabilitados && loadingCatalogos) ...[
            const SizedBox(height: 84),
          ] else if (camposHabilitados && catalogoError != null) ...[
            Text(catalogoError!, style: AppTextStyles.errorText),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: onReintentarCatalogos,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Reintentar'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.steelBlue,
                side: BorderSide(color: AppColors.steelBlue),
              ),
            ),
          ] else ...[
            _SearchableDropdown<UsuarioModel>(
              hint: 'Selección de Chofer',
              searchHint: 'Buscar chofer por nombre...',
              icon: Icons.person_outline,
              value: chofer,
              items: choferes,
              labelOf: (c) => c.fullName,
              onChanged: onChoferChanged,
            ),
            const SizedBox(height: 14),
            _DatePickerField(
              label: '',
              hideLabel: true,
              hint: 'Calendario de Fecha',
              value: fecha,
              onChanged: onFechaChanged,
            ),
            const SizedBox(height: 14),
            if (sucursales.isEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: AppColors.badgeAmber.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.badgeAmber.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 18, color: AppColors.badgeAmber),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'No hay clientes cargados. Cargá o sincronizá clientes para poder asignar visitas.',
                        style: AppTextStyles.link.copyWith(fontSize: 12.5, color: AppColors.graphiteGray),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            _SearchableDropdown<SucursalModel>(
              hint: 'Selección de Sucursal/Cliente',
              searchHint: 'Buscar cliente por nombre...',
              icon: Icons.storefront_outlined,
              value: sucursal,
              items: sucursales,
              labelOf: (s) => s.nombre,
              onChanged: onSucursalChanged,
            ),
            const SizedBox(height: 14),
            _SearchableDropdown<RutaModel>(
              hint: 'Selección de Ruta',
              searchHint: 'Buscar ruta por nombre...',
              icon: Icons.alt_route_outlined,
              value: ruta,
              items: rutas,
              labelOf: (r) => r.nombre,
              onChanged: onRutaChanged,
            ),
          ],
                ],
              ),
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 10),
            Text(error!, style: AppTextStyles.errorText),
          ],
          const SizedBox(height: 18),
          if (mobile)
            SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  botonSincronizar,
                  const SizedBox(height: 10),
                  botonAgregar,
                ],
              ),
            )
          else
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 10,
              runSpacing: 10,
              children: [
                botonSincronizar,
                botonAgregar,
              ],
            ),
        ],
      ),
    );
  }
}

class _DatePickerField extends StatelessWidget {
  final String label;
  final bool hideLabel;
  final String hint;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final bool clearable;
  final bool permitirPasado;

  const _DatePickerField({
    required this.label,
    this.hideLabel = false,
    required this.hint,
    required this.value,
    required this.onChanged,
    this.clearable = false,
    this.permitirPasado = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!hideLabel) ...[
          Text(label, style: AppTextStyles.label),
          const SizedBox(height: 8),
        ],
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            final now = DateTime.now();
            final hoy = DateTime(now.year, now.month, now.day);
            final firstDate = permitirPasado ? DateTime(now.year - 2, 1, 1) : hoy;
            final fechaInicial = value ?? now;
            final inicial = fechaInicial.isBefore(firstDate) ? firstDate : fechaInicial;
            final picked = await showDatePicker(
              context: context,
              initialDate: inicial,
              firstDate: firstDate,
              lastDate: now.add(const Duration(days: 365)),
              builder: (context, child) => Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: Theme.of(context).colorScheme.copyWith(
                        primary: AppColors.orange,
                        onPrimary: AppColors.white,
                        onSurface: AppColors.graphiteGray,
                      ),
                ),
                child: child!,
              ),
            );
            if (picked != null) onChanged(picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.inputBorder, width: 1.2),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_outlined,
                    size: 18, color: AppColors.inputHint),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    value == null
                        ? hint
                        : '${value!.day.toString().padLeft(2, '0')}/${value!.month.toString().padLeft(2, '0')}/${value!.year}',
                    style: value == null ? AppTextStyles.hint : AppTextStyles.input,
                  ),
                ),
                if (clearable && value != null)
                  GestureDetector(
                    onTap: () => onChanged(null),
                    child: Icon(Icons.close, size: 16, color: AppColors.inputHint),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchableDropdown<T> extends StatefulWidget {
  final String hint;
  final String searchHint;
  final IconData icon;
  final T? value;
  final List<T> items;
  final String Function(T) labelOf;
  final ValueChanged<T?> onChanged;

  const _SearchableDropdown({
    required this.hint,
    required this.searchHint,
    required this.icon,
    required this.value,
    required this.items,
    required this.labelOf,
    required this.onChanged,
  });

  @override
  State<_SearchableDropdown<T>> createState() => _SearchableDropdownState<T>();
}

class _SearchableDropdownState<T> extends State<_SearchableDropdown<T>> {
  final LayerLink _link = LayerLink();
  final GlobalKey _fieldKey = GlobalKey();
  OverlayEntry? _overlay;
  bool _open = false;

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _toggle() {
    if (_open) {
      _close();
    } else {
      _openOverlay();
    }
  }

  double get _fieldWidth {
    final box = _fieldKey.currentContext?.findRenderObject() as RenderBox?;
    return box?.size.width ?? 280;
  }

  void _openOverlay() {
    if (widget.items.isEmpty) return;
    final width = _fieldWidth;
    _overlay = OverlayEntry(
      builder: (ctx) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _close,
              ),
            ),
            CompositedTransformFollower(
              link: _link,
              showWhenUnlinked: false,
              targetAnchor: Alignment.bottomLeft,
              followerAnchor: Alignment.topLeft,
              offset: const Offset(0, 6),
              child: Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 6,
                  borderRadius: BorderRadius.circular(12),
                  color: AppColors.white,
                  child: SizedBox(
                    width: width,
                    child: _SearchablePanel<T>(
                      searchHint: widget.searchHint,
                      items: widget.items,
                      labelOf: widget.labelOf,
                      selected: widget.value,
                      onSelected: _select,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
    Overlay.of(context).insert(_overlay!);
    setState(() => _open = true);
  }

  void _close() {
    _removeOverlay();
    if (mounted) setState(() => _open = false);
  }

  void _removeOverlay() {
    _overlay?.remove();
    _overlay = null;
  }

  void _select(T item) {
    widget.onChanged(item);
    _close();
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = widget.value != null;
    final enabled = widget.items.isNotEmpty;
    return CompositedTransformTarget(
      link: _link,
      child: InkWell(
        key: _fieldKey,
        borderRadius: BorderRadius.circular(12),
        onTap: enabled ? _toggle : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _open ? AppColors.steelBlue : AppColors.inputBorder,
              width: _open ? 1.4 : 1.2,
            ),
          ),
          child: Row(
            children: [
              Icon(widget.icon, size: 18, color: AppColors.inputHint),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  hasValue ? widget.labelOf(widget.value as T) : widget.hint,
                  overflow: TextOverflow.ellipsis,
                  style: hasValue ? AppTextStyles.input : AppTextStyles.hint,
                ),
              ),
              Icon(
                _open ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                color: AppColors.inputHint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchablePanel<T> extends StatefulWidget {
  final String searchHint;
  final List<T> items;
  final String Function(T) labelOf;
  final T? selected;
  final ValueChanged<T> onSelected;

  const _SearchablePanel({
    required this.searchHint,
    required this.items,
    required this.labelOf,
    required this.selected,
    required this.onSelected,
  });

  @override
  State<_SearchablePanel<T>> createState() => _SearchablePanelState<T>();
}

class _SearchablePanelState<T> extends State<_SearchablePanel<T>> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final filtrados = q.isEmpty
        ? widget.items
        : widget.items
            .where((item) => widget.labelOf(item).toLowerCase().contains(q))
            .toList();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
          child: TextField(
            controller: _controller,
            autofocus: true,
            style: AppTextStyles.input,
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              isDense: true,
              hintText: widget.searchHint,
              hintStyle: AppTextStyles.hint,
              prefixIcon:
                  const Icon(Icons.search, size: 18, color: AppColors.inputHint),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.inputBorder, width: 1.2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.inputBorder, width: 1.2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.steelBlue, width: 1.4),
              ),
            ),
          ),
        ),
        if (filtrados.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Text('Sin resultados', style: AppTextStyles.hint),
          )
        else
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 240),
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.only(bottom: 6),
              itemCount: filtrados.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color: AppColors.inputBorder.withOpacity(0.5),
              ),
              itemBuilder: (ctx, i) {
                final item = filtrados[i];
                final isSel = item == widget.selected;
                return InkWell(
                  onTap: () => widget.onSelected(item),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    color: isSel
                        ? AppColors.steelBlue.withOpacity(0.08)
                        : Colors.transparent,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.labelOf(item),
                            style: AppTextStyles.input,
                          ),
                        ),
                        if (isSel)
                          const Icon(Icons.check,
                              size: 18, color: AppColors.steelBlue),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}