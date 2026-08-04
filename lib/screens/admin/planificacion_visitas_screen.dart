import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/mock_planificacion_data.dart';
import '../../models/visita_estado.dart';
import '../../models/visita_model.dart';
import '../../providers/auth_provider.dart';
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

  bool _loading = true;
  bool _publishing = false;
  String? _loadError;

  List<VisitaModel> _serverVisitas = [];
  final List<VisitaModel> _draftVisitas = [];

  final _choferFilterCtrl = TextEditingController();
  final _clienteFilterCtrl = TextEditingController();
  DateTime? _fechaFilter;

  int _sortColumnIndex = 1;
  bool _sortAsc = true;

  MockChofer? _formChofer;
  DateTime? _formFecha;
  MockCliente? _formCliente;
  String? _formError;

  @override
  void initState() {
    super.initState();
    _repo = VisitaRepository(context.read<AuthProvider>().apiClient);
    _choferFilterCtrl.addListener(() => setState(() {}));
    _clienteFilterCtrl.addListener(() => setState(() {}));
    _loadVisitas();
  }

  @override
  void dispose() {
    _choferFilterCtrl.dispose();
    _clienteFilterCtrl.dispose();
    super.dispose();
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

  String _formatDisplayDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd/$mm/${d.year}';
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
        final fecha = row.visita.fecha;
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
    final visitasDelDia = [..._draftVisitas, ..._serverVisitas].where((v) {
      final f = v.fecha;
      return v.idUsuario == idChofer &&
          f != null &&
          f.year == fecha.year &&
          f.month == fecha.month &&
          f.day == fecha.day;
    });
    return visitasDelDia.length + 1;
  }

  void _handleGuardar() {
    if (_formChofer == null || _formFecha == null || _formCliente == null) {
      setState(() => _formError = 'Completá chofer, fecha y sucursal/cliente.');
      return;
    }

    final chofer = _formChofer!;
    final fecha = _formFecha!;
    final cliente = _formCliente!;

    final draft = VisitaModel(
      idUsuario: chofer.id,
      nombreUsuario: chofer.nombre,
      idSucursal: cliente.idSucursal,
      idRuta: cliente.idRuta,
      sucursalSnapshot: {
        'nombre': cliente.nombre,
        'direccion': cliente.direccion,
      },
      rutaSnapshot: {
        'chofer': chofer.nombre,
        'fecha_ruta': formatDateOnly(fecha),
      },
      ordenVisita: _siguienteOrden(chofer.id, fecha),
      estadoVisita: VisitaEstado.pendiente,
      fecha: fecha,
    );

    setState(() {
      _draftVisitas.insert(0, draft);
      _formCliente = null;
      _formError = null;
    });
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

  Future<void> _handleEditar(_AgendaRow row) async {
    final nuevaFecha = await showDatePicker(
      context: context,
      initialDate: row.visita.fecha ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
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
                formatFecha: _formatDisplayDate,
                initialsOf: _initials,
                onEditar: _handleEditar,
                onEliminar: _handleEliminar,
              );
              final formulario = _FormularioCard(
                chofer: _formChofer,
                fecha: _formFecha,
                cliente: _formCliente,
                error: _formError,
                onChoferChanged: (c) => setState(() => _formChofer = c),
                onFechaChanged: (d) => setState(() => _formFecha = d),
                onClienteChanged: (c) => setState(() => _formCliente = c),
                onGuardar: _handleGuardar,
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
                          PrimaryButton(
                            text: 'Publicar Visitas del Día',
                            isLoading: _publishing,
                            onPressed: _handlePublicar,
                          ),
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
                  PrimaryButton(
                    text: 'Publicar Visitas del Día',
                    isLoading: _publishing,
                    onPressed: _handlePublicar,
                  ),
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

  const _FiltrosCard({
    required this.choferCtrl,
    required this.clienteCtrl,
    required this.fecha,
    required this.onFechaChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Filtros de Búsqueda', style: AppTextStyles.title.copyWith(fontSize: 17)),
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
                  label: 'Calendario de Fecha',
                  value: fecha,
                  hint: 'Todas las fechas',
                  onChanged: onFechaChanged,
                  clearable: true,
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

class _ListadoCard extends StatelessWidget {
  final bool loading;
  final String? error;
  final List<_AgendaRow> rows;
  final int sortColumnIndex;
  final bool sortAsc;
  final void Function(int columnIndex, bool asc) onSort;
  final VoidCallback onRetry;
  final String Function(VisitaModel) clienteNombreOf;
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
    required this.formatFecha,
    required this.initialsOf,
    required this.onEditar,
    required this.onEliminar,
  });

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
              child: Center(child: CircularProgressIndicator()),
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
            SizedBox(
              height: 420,
              child: Scrollbar(
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: LayoutBuilder(
                    builder: (context, tableConstraints) {
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minWidth: tableConstraints.maxWidth,
                          ),
                          child: DataTable(
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
                              const DataColumn(label: Text('Estado')),
                              const DataColumn(label: Text('Acciones')),
                            ],
                            rows: rows.map((row) {
                              final nombreChofer = row.visita.nombreUsuario ?? 'Sin asignar';
                              final fecha = row.visita.fecha;
                              return DataRow(cells: [
                                DataCell(Row(
                                  mainAxisSize: MainAxisSize.min,
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
                                    Text(nombreChofer, style: AppTextStyles.input),
                                  ],
                                )),
                                DataCell(Text(
                                  fecha == null ? '—' : formatFecha(fecha),
                                  style: AppTextStyles.input,
                                )),
                                DataCell(Text(clienteNombreOf(row.visita), style: AppTextStyles.input)),
                                DataCell(EstadoVisitaBadge(
                                  estado: row.visita.estadoVisita,
                                  esBorrador: row.esBorrador,
                                )),
                                DataCell(Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, size: 19),
                                      color: AppColors.steelBlue,
                                      onPressed: () => onEditar(row),
                                    ),
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
                      );
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FormularioCard extends StatelessWidget {
  final MockChofer? chofer;
  final DateTime? fecha;
  final MockCliente? cliente;
  final String? error;
  final ValueChanged<MockChofer?> onChoferChanged;
  final ValueChanged<DateTime?> onFechaChanged;
  final ValueChanged<MockCliente?> onClienteChanged;
  final VoidCallback onGuardar;

  const _FormularioCard({
    required this.chofer,
    required this.fecha,
    required this.cliente,
    required this.error,
    required this.onChoferChanged,
    required this.onFechaChanged,
    required this.onClienteChanged,
    required this.onGuardar,
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
          const SizedBox(height: 18),
          Text('Campos', style: AppTextStyles.label),
          const SizedBox(height: 10),
          _StyledDropdown<MockChofer>(
            hint: 'Selección de Chofer',
            icon: Icons.person_outline,
            value: chofer,
            items: mockChoferes,
            labelOf: (c) => c.nombre,
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
          _StyledDropdown<MockCliente>(
            hint: 'Selección de Sucursal/Cliente',
            icon: Icons.storefront_outlined,
            value: cliente,
            items: mockClientes,
            labelOf: (c) => c.nombre,
            onChanged: onClienteChanged,
          ),
          if (error != null) ...[
            const SizedBox(height: 10),
            Text(error!, style: AppTextStyles.errorText),
          ],
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: onGuardar,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.steelBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Guardar'),
            ),
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

  const _DatePickerField({
    required this.label,
    this.hideLabel = false,
    required this.hint,
    required this.value,
    required this.onChanged,
    this.clearable = false,
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
            final picked = await showDatePicker(
              context: context,
              initialDate: value ?? DateTime.now(),
              firstDate: DateTime.now().subtract(const Duration(days: 365)),
              lastDate: DateTime.now().add(const Duration(days: 365)),
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
