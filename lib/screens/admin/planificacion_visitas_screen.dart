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
import '../../widgets/app_alert.dart';
import '../../widgets/labeled_text_field.dart';
import '../../widgets/primary_button.dart';

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
    _loadVisitas();
    _loadCatalogos();
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
        _catalogoRepo.listarSucursales(),
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
            'No se pudieron cargar los catálogos de choferes/sucursales/rutas.';
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
      final data = await _repo.listarTodas();
      if (!mounted) return;
      setState(() {
        _serverVisitas = data;
        _loading = false;
      });
    } on VisitaRepositoryException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadError = 'No se pudo cargar el listado de visitas.';
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
    return 'Sucursal #${v.idSucursal}';
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

  bool _esCancelable(VisitaEstado estado) {
    return estado == VisitaEstado.pendiente ||
        estado == VisitaEstado.enCurso ||
        estado == VisitaEstado.visitado ||
        estado == VisitaEstado.noAsistio;
  }

  bool _esEditable(VisitaEstado estado) {
    return estado != VisitaEstado.visitado &&
        estado != VisitaEstado.completada &&
        estado != VisitaEstado.cancelada &&
        estado != VisitaEstado.noAsistio &&
        estado != VisitaEstado.inactivo;
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
      final nombreChofer = (row.visita.nombreUsuario ?? '').toLowerCase();
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
          return (a.visita.nombreUsuario ?? '')
              .compareTo(b.visita.nombreUsuario ?? '');
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
        'direccion': sucursal.direccion,
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
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.steelBlue,
            content: Text(
              'Visita agregada a la lista como borrador. '
              'Publicá la agenda del día para confirmarla.',
              style: AppTextStyles.input.copyWith(color: Colors.white),
            ),
          ),
        );
    }
  }

  Future<void> _handlePublicar() async {
    if (_draftVisitas.isEmpty) {
      await showAppAlert(
        context: context,
        title: 'Nada para publicar',
        message:
            'No hay visitas nuevas para publicar. Agregá al menos una desde el formulario.',
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
      final errores = result.errores.isEmpty
          ? ''
          : '\n\n${result.errores.join('\n')}';
      await showAppAlert(
        context: context,
        title: 'Visitas publicadas',
        message:
            'Insertadas: ${result.insertadas} · Omitidas: ${result.omitidas}$errores',
      );
    } on VisitaRepositoryException catch (e) {
      if (!mounted) return;
      setState(() => _publishing = false);
      await showAppAlert(context: context, title: 'Error', message: e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _publishing = false);
      await showAppAlert(
        context: context,
        title: 'Error',
        message: 'No se pudieron publicar las visitas.',
      );
    }
  }

  Future<void> _handleSincronizar() async {
    final camposCompletos = [
      _formChofer != null,
      _formFecha != null,
      _formSucursal != null,
      _formRuta != null,
    ];
    final completos = camposCompletos.where((c) => c).length;

    if (completos != camposCompletos.length) {
      setState(() => _formError = completos == 0
          ? 'Completá Chofer, Fecha, Sucursal y Ruta para sincronizar la agenda.'
          : 'Para sincronizar completá todos los campos (Chofer, Fecha, '
              'Sucursal y Ruta) o dejálos todos vacíos.');
      return;
    }
    setState(() => _formError = null);

    final chofer = _formChofer!;
    final fecha = _formFecha!;

    setState(() => _publishing = true);

    try {
      final result = await _repo.sincronizarAgenda(
        choferId: chofer.id,
        fecha: fecha,
      );
      if (!mounted) return;
      setState(() {
        _publishing = false;
        // Los borradores locales de este chofer+fecha quedan redundantes:
        // la sincronización ya los subió (o ya existían) en el servidor.
        _draftVisitas.removeWhere((v) =>
            v.idUsuario == chofer.id &&
            v.fecha != null &&
            _esMismoDia(v.fecha!, fecha));
      });
      await _loadVisitas();
      if (!mounted) return;

      final fechaTexto = _formatDisplayDate(fecha);

      // Todo se pudo insertar: sin duplicados ni errores.
      if (result.omitidas == 0) {
        await showAppAlert(
          context: context,
          title: 'Agenda sincronizada',
          message:
              'Se cargaron ${result.insertadas} visita(s) para ${chofer.fullName} el $fechaTexto.',
        );
        return;
      }

      if (result.insertadas == 0) {
        await showAppAlert(
          context: context,
          title: 'No se pudo sincronizar',
          message:
              'No se ha podido sincronizar a ${chofer.fullName} para el $fechaTexto '
              'porque su agenda ya se encuentra cargada en el sistema.',
        );
        return;
      }

      await showAppAlert(
        context: context,
        title: 'Agenda sincronizada parcialmente',
        message:
            'Se cargaron ${result.insertadas} visita(s) nuevas para ${chofer.fullName} el $fechaTexto. '
            'Las otras ${result.omitidas} ya se encontraban cargadas en el sistema.',
      );
    } on VisitaRepositoryException catch (e) {
      if (!mounted) return;
      setState(() {
        _publishing = false;
        _draftVisitas.removeWhere((v) =>
            v.idUsuario == chofer.id &&
            v.fecha != null &&
            _esMismoDia(v.fecha!, fecha));
      });
      await showAppAlert(context: context, title: 'Error', message: e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _publishing = false;
        _draftVisitas.removeWhere((v) =>
            v.idUsuario == chofer.id &&
            v.fecha != null &&
            _esMismoDia(v.fecha!, fecha));
      });
      await showAppAlert(
        context: context,
        title: 'Error',
        message: 'No se pudo sincronizar la agenda del chofer.',
      );
    }
  }

  Future<void> _handleEditar(_AgendaRow row) async {
    final hoy = _hoyFechaSola();
    final fechaInicial = row.visita.fecha ?? DateTime.now();
    final nuevaFecha = await showDatePicker(
      context: context,
      initialDate: fechaInicial.isBefore(hoy) ? hoy : fechaInicial,
      firstDate: hoy,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (nuevaFecha == null) return;

    if (row.esBorrador) {
      setState(() {
        final index = _draftVisitas.indexOf(row.visita);
        if (index != -1) {
          _draftVisitas[index] = row.visita.copyWith(fecha: nuevaFecha);
        }
      });
      return;
    }

    final idVisita = row.visita.idVisita;
    if (idVisita == null) return;

    try {
      await _repo.actualizarParcial(idVisita, fecha: nuevaFecha);
      await _loadVisitas();
    } on VisitaRepositoryException catch (e) {
      if (!mounted) return;
      await showAppAlert(context: context, title: 'Error', message: e.message);
    }
  }

  Future<void> _handleEliminar(_AgendaRow row) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancelar visita', style: AppTextStyles.title),
        content: Text(
          '¿Confirmás cancelar la visita de "${_clienteNombre(row.visita)}"?',
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
              'Cancelar visita',
              style: AppTextStyles.button.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (row.esBorrador) {
      setState(() => _draftVisitas.remove(row.visita));
      return;
    }

    final idVisita = row.visita.idVisita;
    if (idVisita == null) return;

    try {
      await _repo.cancelar(idVisita);
      await _loadVisitas();
    } on VisitaRepositoryException catch (e) {
      if (!mounted) return;
      await showAppAlert(context: context, title: 'Error', message: e.message);
    }
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
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomSafePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Planificación Diaria de Visitas', style: AppTextStyles.desktopTitle),
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
            onFechaChanged: (d) => setState(() => _fechaFilter = d),
            porCreacion: _fechaPorCreacion,
            onModoChanged: (v) => setState(() => _fechaPorCreacion = v),
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
                esCancelable: _esCancelable,
                esEditable: _esEditable,
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
                children: [
                  listado,
                  const SizedBox(height: 20),
                  formulario,
                  const SizedBox(height: 24),
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
      padding: const EdgeInsets.all(20),
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

  const _FiltrosCard({
    required this.choferCtrl,
    required this.clienteCtrl,
    required this.fecha,
    required this.onFechaChanged,
    required this.porCreacion,
    required this.onModoChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Filtros de Búsqueda', style: AppTextStyles.title.copyWith(fontSize: 17)),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Filtrar fecha por:',
                style: AppTextStyles.link.copyWith(fontSize: 12.5, color: AppColors.graphiteGray),
              ),
              const SizedBox(width: 10),
              _ModoFechaChip(
                texto: 'Planificada',
                activo: !porCreacion,
                onTap: () => onModoChanged(false),
              ),
              const SizedBox(width: 8),
              _ModoFechaChip(
                texto: 'Creación',
                activo: porCreacion,
                onTap: () => onModoChanged(true),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 760;
              final fields = [
                LabeledTextField(
                  label: 'Buscador por Chofer',
                  hint: 'Nombre del chofer',
                  icon: Icons.search,
                  controller: choferCtrl,
                ),
                _DatePickerField(
                  label: porCreacion ? 'Fecha de creación' : 'Fecha planificada',
                  value: fecha,
                  hint: 'Todas las fechas',
                  onChanged: onFechaChanged,
                  clearable: true,
                  permitirPasado: true,
                ),
                LabeledTextField(
                  label: 'Buscador de Cliente',
                  hint: 'Nombre del cliente o sucursal',
                  icon: Icons.search,
                  controller: clienteCtrl,
                ),
              ];

              if (wide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: fields[0]),
                    const SizedBox(width: 16),
                    Expanded(child: fields[1]),
                    const SizedBox(width: 16),
                    Expanded(child: fields[2]),
                  ],
                );
              }

              return Column(
                children: [
                  fields[0],
                  const SizedBox(height: 14),
                  fields[1],
                  const SizedBox(height: 14),
                  fields[2],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ModoFechaChip extends StatelessWidget {
  final String texto;
  final bool activo;
  final VoidCallback onTap;

  const _ModoFechaChip({required this.texto, required this.activo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: activo ? AppColors.orange.withOpacity(0.10) : AppColors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: activo ? AppColors.orange : AppColors.inputBorder,
            width: activo ? 1.4 : 1,
          ),
        ),
        child: Text(
          texto,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: activo ? AppColors.orange : AppColors.graphiteGray,
          ),
        ),
      ),
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
  final bool Function(VisitaEstado) esCancelable;
  final bool Function(VisitaEstado) esEditable;
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
    required this.esCancelable,
    required this.esEditable,
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
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator(color: AppColors.orange)),
            )
          else if (error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Column(
                children: [
                  Text(error!, style: AppTextStyles.errorText, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  OutlinedButton(onPressed: onRetry, child: const Text('Reintentar')),
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
                      final nombreChofer = row.visita.nombreUsuario ?? 'Sin asignar';
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
                            if (row.esBorrador ||
                                esEditable(row.visita.estadoVisita))
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 19),
                                color: AppColors.steelBlue,
                                onPressed: () => onEditar(row),
                              ),
                            if (row.esBorrador ||
                                esCancelable(row.visita.estadoVisita))
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
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 480),
      child: Scrollbar(
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: rows.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final row = rows[index];
            final nombreChofer = row.visita.nombreUsuario ?? 'Sin asignar';
            final fecha = row.visita.fecha;

            return Container(
              padding: const EdgeInsets.all(14),
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
                  if (row.esBorrador ||
                      esEditable(row.visita.estadoVisita) ||
                      esCancelable(row.visita.estadoVisita)) ...[
                    const SizedBox(height: 8),
                    const Divider(height: 1),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (row.esBorrador ||
                            esEditable(row.visita.estadoVisita))
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 19),
                            color: AppColors.steelBlue,
                            onPressed: () => onEditar(row),
                          ),
                        if (row.esBorrador ||
                            esCancelable(row.visita.estadoVisita))
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
          },
        ),
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
  });

  @override
  Widget build(BuildContext context) {
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
                    '"Agregar a la lista": deja como borrador en el listado.'
                    ' Usá "Publicar Visitas del Día" para confirmarlas en el sistema.',
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
          if (loadingCatalogos) ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.orange),
              ),
            ),
          ] else if (catalogoError != null) ...[
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
            _StyledDropdown<UsuarioModel>(
              hint: 'Selección de Chofer',
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
            _StyledDropdown<SucursalModel>(
              hint: 'Selección de Sucursal/Cliente',
              icon: Icons.storefront_outlined,
              value: sucursal,
              items: sucursales,
              labelOf: (s) => s.nombre,
              onChanged: onSucursalChanged,
            ),
            const SizedBox(height: 14),
            _StyledDropdown<RutaModel>(
              hint: 'Selección de Ruta',
              icon: Icons.alt_route_outlined,
              value: ruta,
              items: rutas,
              labelOf: (r) => r.nombre,
              onChanged: onRutaChanged,
            ),
          ],
          if (error != null) ...[
            const SizedBox(height: 10),
            Text(error!, style: AppTextStyles.errorText),
          ],
          const SizedBox(height: 18),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
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
              ),
              ElevatedButton.icon(
                onPressed: onGuardar,
                icon: const Icon(Icons.playlist_add, size: 18),
                label: const Text('Agregar a la lista'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.steelBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
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

class _StyledDropdown<T> extends StatelessWidget {
  final String hint;
  final IconData icon;
  final T? value;
  final List<T> items;
  final String Function(T) labelOf;
  final ValueChanged<T?> onChanged;

  const _StyledDropdown({
    required this.hint,
    required this.icon,
    required this.value,
    required this.items,
    required this.labelOf,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.inputBorder, width: 1.2),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          isExpanded: true,
          value: value,
          hint: Row(
            children: [
              Icon(icon, size: 18, color: AppColors.inputHint),
              const SizedBox(width: 10),
              Text(hint, style: AppTextStyles.hint),
            ],
          ),
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.inputHint),
          style: AppTextStyles.input,
          items: items
              .map((item) => DropdownMenuItem<T>(
                    value: item,
                    child: Text(labelOf(item)),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
