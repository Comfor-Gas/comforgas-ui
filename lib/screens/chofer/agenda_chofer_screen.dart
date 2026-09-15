import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import '../../data/mock_chofer_data.dart';
import '../../local/agenda_cache_service.dart';
import '../../local/offline_evento.dart';
import '../../local/offline_queue_service.dart';
import '../../models/cliente_ficha.dart';
import '../../models/visita_estado.dart';
import '../../models/visita_model.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/network_exception.dart';
import '../../repositories/visita_repository.dart';
import '../../services/sync_manager.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/chofer/clientes_visitados_section.dart';
import '../../widgets/chofer/comodato_badge.dart';
import '../../widgets/chofer/sync_pendiente_banner.dart';
import '../../widgets/chofer/ultima_bajada_indicator.dart';
import '../../widgets/chofer/visita_cliente_card.dart';
import '../../widgets/chofer/visita_estado_chip.dart';
import '../../widgets/chofer/visitas_pausadas_section.dart';
import '../../widgets/common/estado_conexion_badge.dart';
import '../../widgets/primary_button.dart';
import 'visita_activa_screen.dart';

const List<String> _diasSemana = [
  'Lunes',
  'Martes',
  'Miércoles',
  'Jueves',
  'Viernes',
  'Sábado',
  'Domingo',
];

const List<String> _meses = [
  'Enero',
  'Febrero',
  'Marzo',
  'Abril',
  'Mayo',
  'Junio',
  'Julio',
  'Agosto',
  'Septiembre',
  'Octubre',
  'Noviembre',
  'Diciembre',
];

class AgendaChoferScreen extends StatefulWidget {
  const AgendaChoferScreen({super.key});

  @override
  State<AgendaChoferScreen> createState() => _AgendaChoferScreenState();
}

class _AgendaChoferScreenState extends State<AgendaChoferScreen> {
  late final VisitaRepository _repo;
  final _searchCtrl = TextEditingController();

  bool _loading = true;
  String? _error;
  List<VisitaModel> _visitas = [];
  bool _visitadosExpanded = false;
  bool _pausadasExpanded = false;
  bool _iniciandoVisita = false;
  bool _sincronizando = false;
  bool _mostrandoCache = false;
  String? _avisoCache;
  StreamSubscription<bool>? _syncEstadoSub;
  String? _idUsuarioCargado;
  DateTime? _fechaCargada;

  @override
  void initState() {
    super.initState();
    _repo = VisitaRepository(context.read<AuthProvider>().apiClient);
    _searchCtrl.addListener(() => setState(() {}));
    _syncEstadoSub = SyncManager.instance.sincronizando.listen((sincronizando) {
      if (mounted) setState(() => _sincronizando = sincronizando);
    });
    unawaited(SyncManager.instance.sincronizar());
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _syncEstadoSub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final auth = context.read<AuthProvider>();
    final idUsuario = auth.user?.id;
    if (idUsuario == null || idUsuario.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'No se pudo identificar al chofer autenticado.';
      });
      return;
    }

    final hoy = DateTime.now();
    _idUsuarioCargado = idUsuario;
    _fechaCargada = hoy;

    try {
      final agendaItems = await _repo.getVisitasPorUsuarioYFecha(
        idUsuario: idUsuario,
        fecha: hoy,
      );
      final data = agendaItems.map((item) => item.toVisitaModel(idUsuario)).toList()
      
        ..sort((a, b) => a.ordenVisita.compareTo(b.ordenVisita));
      if (!mounted) return;
      setState(() {
        _visitas = data;
        _loading = false;
        _mostrandoCache = false;
        _avisoCache = null;
      });
      unawaited(AgendaCacheService.instance.guardar(idUsuario, hoy, data));
    } on NetworkException {
      _cargarDesdeCache(
        idUsuario,
        hoy,
        'Sin conexión: mostrando la última ruta guardada en el dispositivo.',
      );
    } on VisitaRepositoryException catch (e) {
      _cargarDesdeCache(idUsuario, hoy, e.message);
    } catch (_) {
      _cargarDesdeCache(idUsuario, hoy, 'No se pudo cargar la ruta del día.');
    }
  }

  void _cargarDesdeCache(String idUsuario, DateTime fecha, String mensaje) {
    if (!mounted) return;
    final cache = AgendaCacheService.instance.obtener(idUsuario, fecha);
    if (cache != null) {
      setState(() {
        _visitas = cache;
        _loading = false;
        _error = null;
        _mostrandoCache = true;
        _avisoCache = mensaje;
      });
    } else {
      setState(() {
        _loading = false;
        _error = mensaje;
        _mostrandoCache = false;
      });
    }
  }

  void _guardarCacheActual() {
    final idUsuario = _idUsuarioCargado;
    final fecha = _fechaCargada;
    if (idUsuario == null || fecha == null) return;
    unawaited(AgendaCacheService.instance.guardar(idUsuario, fecha, _visitas));
  }

  String _nombreCliente(VisitaModel v) {
    for (final key in ['nombre', 'nombreSucursal', 'razonSocial', 'cliente']) {
      final value = v.sucursalSnapshot[key];
      if (value is String && value.trim().isNotEmpty) return value;
    }
    return 'Sucursal #${v.idSucursal}';
  }

  String _direccionCliente(VisitaModel v) {
    for (final key in ['direccion', 'domicilio', 'address']) {
      final value = v.sucursalSnapshot[key];
      if (value is String && value.trim().isNotEmpty) return value;
    }
    return 'Sin dirección registrada';
  }

  List<VisitaModel> _filtrar(List<VisitaModel> lista) {
    final query = _searchCtrl.text.trim().toLowerCase();
    if (query.isEmpty) return lista;
    return lista.where((v) {
      return _nombreCliente(v).toLowerCase().contains(query) ||
          _direccionCliente(v).toLowerCase().contains(query);
    }).toList();
  }

  List<VisitaModel> get _pendientesFiltradas => _filtrar(
        _visitas
            .where((v) =>
                !VisitaEstadoMapper.esTerminadaEnCampo(v.estadoVisita) &&
                v.estadoVisita != VisitaEstado.pausadaSocial)
            .toList(),
      );

  List<VisitaModel> get _pausadasFiltradas => _filtrar(
        _visitas.where((v) => v.estadoVisita == VisitaEstado.pausadaSocial).toList(),
      );

  List<VisitaModel> get _completadasFiltradas => _filtrar(
        _visitas.where((v) => VisitaEstadoMapper.esTerminadaEnCampo(v.estadoVisita)).toList(),
      );

  VisitaModel? get _visitaEnCurso {
    for (final v in _visitas) {
      if (v.estadoVisita == VisitaEstado.enCurso) return v;
    }
    return null;
  }

  VisitaModel? get _siguientePendiente {
    for (final v in _visitas) {
      if (v.estadoVisita == VisitaEstado.pendiente) return v;
    }
    return null;
  }

  VisitaModel? get _visitaAccionable => _visitaEnCurso ?? _siguientePendiente;

  void _handleIniciarSiguiente() {
    final accionable = _visitaAccionable;
    if (accionable == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No quedan visitas pendientes por hoy.')),
      );
      return;
    }
    _iniciarVisita(accionable);
  }

  void _handleCardTap(VisitaModel visita) {
    _mostrarDetalle(visita);
  }

  Future<void> _confirmarDescartarPendientes(int cantidad) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Descartar cambios pendientes'),
        content: Text(
          'Se van a eliminar $cantidad cambio(s) guardado(s) en el dispositivo '
          'que todavía no se enviaron al servidor. Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );

    if (confirmado != true) return;
    await OfflineQueueService.instance.vaciar();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cambios pendientes descartados.')),
    );
  }

  Future<void> _iniciarVisita(VisitaModel visita) async {
    if (_iniciandoVisita) return;
    setState(() => _iniciandoVisita = true);

    final resultado = await Navigator.of(context).push<VisitaModel>(
      MaterialPageRoute(
        builder: (_) => VisitaActivaScreen(
          visita: visita,
          nombreCliente: _nombreCliente(visita),
          direccionCliente: _direccionCliente(visita),
        ),
      ),
    );

    if (!mounted) return;
    setState(() {
      _iniciandoVisita = false;
      if (resultado != null) {
        final index = _visitas.indexWhere((v) => v.idAgendaItem == resultado.idAgendaItem);
        if (index != -1) {
          final previo = _visitas[index];
          final esCheckOut = resultado.estadoVisita == VisitaEstado.visitado;
          final snapshotActualizado = esCheckOut
              ? <String, dynamic>{
                  ...previo.sucursalSnapshot,
                  'ultimaBajada':
                      (resultado.fecha ?? previo.fecha ?? DateTime.now()).toIso8601String(),
                }
              : previo.sucursalSnapshot;
          _visitas[index] = previo.copyWith(
            idVisita: resultado.idVisita ?? previo.idVisita,
            estadoVisita: resultado.estadoVisita,
            timestampInicio: resultado.timestampInicio ?? previo.timestampInicio,
            timestampFin: resultado.timestampFin ?? previo.timestampFin,
            sucursalSnapshot: snapshotActualizado,
          );
        }
        if (VisitaEstadoMapper.esTerminadaEnCampo(resultado.estadoVisita)) {
          _visitadosExpanded = true;
        }
        if (resultado.estadoVisita == VisitaEstado.pausadaSocial) {
          _pausadasExpanded = true;
        }
      }
    });
    if (resultado != null) {
      _guardarCacheActual();
    }
  }

  void _mostrarDetalle(VisitaModel visita) {
    final accionable = _visitaAccionable;
    final esAccionable =
        accionable != null && accionable.idAgendaItem == visita.idAgendaItem;
    final yaVisitada = VisitaEstadoMapper.esTerminadaEnCampo(visita.estadoVisita);
    final enCurso = _visitaEnCurso;

    String? mensajeBloqueo;
    if (!esAccionable && !yaVisitada) {
      mensajeBloqueo = enCurso != null
          ? 'Tenés una visita en curso. Finalizala antes de iniciar esta.'
          : 'Vas a poder iniciarla cuando completes las paradas anteriores.';
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => _DetalleVisitaSheet(
        visita: visita,
        nombreCliente: _nombreCliente(visita),
        direccionCliente: _direccionCliente(visita),
        textoAccion: visita.estadoVisita == VisitaEstado.enCurso
            ? 'Continuar Visita'
            : 'Iniciar Visita',
        mensajeBloqueo: mensajeBloqueo,
        onIniciar: esAccionable
            ? () {
                Navigator.of(sheetContext).pop();
                _iniciarVisita(visita);
              }
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final nombreChofer = auth.user?.fullName?.trim().isNotEmpty == true
        ? auth.user!.fullName!
        : (auth.user?.email ?? 'Chofer');
    final patente = mockPatenteFor(auth.user?.id ?? nombreChofer);

    final now = DateTime.now();
    final fechaTexto =
        '${_diasSemana[now.weekday - 1]}, ${now.day} de ${_meses[now.month - 1]} ${now.year}';

    final pendientes = _pendientesFiltradas;
    final pausadasVisibles = _pausadasFiltradas;
    final completadasVisibles = _completadasFiltradas;
    final completadas = _visitas
        .where((v) => VisitaEstadoMapper.esTerminadaEnCampo(v.estadoVisita))
        .length;
    final recaudacion = completadas * mockMontoPromedioPorVisita;
    final siguiente = _visitaAccionable;
    final huboFiltro = _searchCtrl.text.trim().isNotEmpty;
    final sinResultados = pendientes.isEmpty &&
        pausadasVisibles.isEmpty &&
        completadasVisibles.isEmpty &&
        !_loading &&
        _error == null;

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
            _AgendaHeader(nombreChofer: nombreChofer, patente: patente),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.orange,
                onRefresh: _load,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ruta del Día', style: AppTextStyles.title.copyWith(fontSize: 24)),
                      const SizedBox(height: 2),
                      Text(fechaTexto, style: AppTextStyles.link),
                      const SizedBox(height: 16),
                      _StatsCard(
                        clientes: _visitas.length,
                        pedidos: completadas,
                        recaudacion: recaudacion,
                      ),
                      const SizedBox(height: 16),
                      _SearchField(controller: _searchCtrl),
                      const SizedBox(height: 12),
                      if (_mostrandoCache && _avisoCache != null) ...[
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.badgeBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.badgeBlue.withOpacity(0.35)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline, size: 18, color: AppColors.badgeBlue),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _avisoCache!,
                                  style: AppTextStyles.link
                                      .copyWith(fontSize: 12.5, color: AppColors.graphiteGray),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      ValueListenableBuilder<Box<OfflineEvento>>(
                        valueListenable: OfflineQueueService.instance.escuchar(),
                        builder: (context, box, _) {
                          return SyncPendienteBanner(
                            cantidadPendiente: box.length,
                            sincronizando: _sincronizando,
                            onReintentar: () => SyncManager.instance.sincronizar(),
                            onDescartar: box.length > 0
                                ? () => _confirmarDescartarPendientes(box.length)
                                : null,
                          );
                        },
                      ),
                      const SizedBox(height: 4),
                      if (_loading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(child: CircularProgressIndicator(color: AppColors.orange)),
                        )
                      else if (_error != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 30),
                          child: Column(
                            children: [
                              Text(
                                _error!,
                                style: AppTextStyles.errorText,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton(
                                onPressed: _load,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.steelBlue,
                                  side: const BorderSide(color: AppColors.steelBlue),
                                ),
                                child: const Text('Reintentar'),
                              ),
                            ],
                          ),
                        )
                      else if (sinResultados)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 30),
                          child: Center(
                            child: Text(
                              _visitas.isEmpty
                                  ? 'No tenés visitas asignadas para hoy.'
                                  : 'No encontramos clientes con ese criterio.',
                              style: AppTextStyles.link,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      else ...[
                        ...pendientes.map(
                          (v) => VisitaClienteCard(
                            visita: v,
                            nombreCliente: _nombreCliente(v),
                            direccionCliente: _direccionCliente(v),
                            esSiguiente: siguiente != null && siguiente.idAgendaItem == v.idAgendaItem,
                            etiquetaDestacada:
                                v.estadoVisita == VisitaEstado.enCurso ? 'EN CURSO' : 'NEXT',
                            onTap: () => _handleCardTap(v),
                          ),
                        ),
                        if (pausadasVisibles.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          VisitasPausadasSection(
                            pausadas: pausadasVisibles,
                            expandido: _pausadasExpanded,
                            onToggle: (value) => setState(() => _pausadasExpanded = value),
                            nombreCliente: _nombreCliente,
                            direccionCliente: _direccionCliente,
                            onTapVisita: _iniciarVisita,
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (completadasVisibles.isNotEmpty || (!huboFiltro && completadas > 0)) ...[
                          const SizedBox(height: 4),
                          ClientesVisitadosSection(
                            visitados: completadasVisibles,
                            expandido: _visitadosExpanded,
                            onToggle: (value) => setState(() => _visitadosExpanded = value),
                            nombreCliente: _nombreCliente,
                            direccionCliente: _direccionCliente,
                            onTapVisita: _mostrarDetalle,
                          ),
                        ],
                      ],
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: PrimaryButton(
                text: siguiente?.estadoVisita == VisitaEstado.enCurso
                    ? 'Continuar Visita'
                    : 'Iniciar Siguiente Visita',
                isLoading: _iniciandoVisita,
                onPressed: (_loading || _iniciandoVisita) ? null : _handleIniciarSiguiente,
              ),
            ),
          ],
        ),
      );
  }
}

class _AgendaHeader extends StatelessWidget {
  final String nombreChofer;
  final String patente;

  const _AgendaHeader({required this.nombreChofer, required this.patente});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
      decoration: const BoxDecoration(
        color: AppColors.steelBlue,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            padding: const EdgeInsets.all(5),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Image.asset(
              'assets/images/logomolecula.png',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 13, color: Colors.white),
                    children: [
                      const TextSpan(text: 'Chofer: '),
                      TextSpan(
                        text: nombreChofer,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 13, color: Colors.white),
                    children: [
                      const TextSpan(text: 'Transporte Patente: '),
                      TextSpan(
                        text: patente,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const EstadoConexionBadge(compacto: true, claro: true),
        ],
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final int clientes;
  final int pedidos;
  final double recaudacion;

  const _StatsCard({
    required this.clientes,
    required this.pedidos,
    required this.recaudacion,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatItem(label: 'Clientes a\nVisitar', value: '$clientes'),
          ),
          const _StatDivider(),
          Expanded(
            child: _StatItem(label: 'Pedidos\nRealizados', value: '$pedidos'),
          ),
          const _StatDivider(),
          Expanded(
            child: _StatItem(
              label: 'Recaudación:',
              value: '\$${recaudacion.toStringAsFixed(0)}',
            ),
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 44, color: AppColors.inputBorder);
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyles.link.copyWith(fontSize: 12),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: AppTextStyles.title.copyWith(fontSize: 18),
        ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;

  const _SearchField({required this.controller});

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
          hintText: 'Buscar cliente o dirección',
          hintStyle: AppTextStyles.hint,
          prefixIcon: const Icon(Icons.search, color: AppColors.inputHint),
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

class _DetalleVisitaSheet extends StatelessWidget {
  final VisitaModel visita;
  final String nombreCliente;
  final String direccionCliente;
  final String textoAccion;
  final String? mensajeBloqueo;
  final VoidCallback? onIniciar;

  const _DetalleVisitaSheet({
    required this.visita,
    required this.nombreCliente,
    required this.direccionCliente,
    required this.textoAccion,
    this.mensajeBloqueo,
    this.onIniciar,
  });

  @override
  Widget build(BuildContext context) {
    final ficha = ClienteFicha.fromVisita(
      visita,
      nombreResuelto: nombreCliente,
      domicilioResuelto: direccionCliente,
    );

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        28 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.inputBorder,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Text('Parada N° ${ficha.orden}', style: AppTextStyles.link),
              ),
              _DetalleIdTag(clienteId: ficha.clienteId),
            ],
          ),
          const SizedBox(height: 4),
          Text(ficha.nombre, style: AppTextStyles.title.copyWith(fontSize: 20)),
          const SizedBox(height: 10),
          _DetalleLinea(icon: Icons.location_on_outlined, texto: ficha.domicilio),
          if (ficha.tieneBarrio) ...[
            const SizedBox(height: 6),
            _DetalleLinea(icon: Icons.map_outlined, texto: 'Barrio ${ficha.barrio}'),
          ],
          if (ficha.tieneTelefono) ...[
            const SizedBox(height: 6),
            _DetalleLinea(icon: Icons.phone_outlined, texto: ficha.telefono),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              VisitaEstadoChip(estado: visita.estadoVisita),
              if (ficha.tieneComodatoActivo)
                const ComodatoBadge(),
            ],
          ),
          const SizedBox(height: 12),
          UltimaBajadaIndicator(fecha: ficha.ultimaBajada),
          if (mensajeBloqueo != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.badgeAmber.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.badgeAmber.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 18, color: AppColors.badgeAmber),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      mensajeBloqueo!,
                      style: AppTextStyles.link
                          .copyWith(fontSize: 12.5, color: AppColors.graphiteGray),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          if (onIniciar != null) ...[
            PrimaryButton(text: textoAccion, onPressed: onIniciar),
            const SizedBox(height: 10),
          ],
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.steelBlue,
                side: const BorderSide(color: AppColors.steelBlue),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Cerrar'),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetalleIdTag extends StatelessWidget {
  final String clienteId;

  const _DetalleIdTag({required this.clienteId});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.steelBlue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Cliente ID $clienteId',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.steelBlue,
        ),
      ),
    );
  }
}

class _DetalleLinea extends StatelessWidget {
  final IconData icon;
  final String texto;

  const _DetalleLinea({required this.icon, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.graphiteGray),
        const SizedBox(width: 8),
        Expanded(child: Text(texto, style: AppTextStyles.input)),
      ],
    );
  }
}
