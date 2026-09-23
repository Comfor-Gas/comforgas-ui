import 'dart:async' show StreamSubscription, unawaited;
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../local/canje_offline_service.dart';
import '../../local/canje_pendiente.dart';
import '../../local/comodato_offline_service.dart';
import '../../local/comodato_pendiente.dart';
import '../../local/offline_evento.dart';
import '../../local/offline_queue_service.dart';
import '../../local/stock_rodante_cache_service.dart';
import '../../local/venta_social_local_service.dart';
import '../../models/canje_garrafa.dart';
import '../../models/cliente_ficha.dart';
import '../../models/control_comodato.dart';
import '../../models/evidencia_tipo.dart';
import '../../models/producto_sku.dart';
import '../../models/nota_debito_resumen.dart';
import '../../models/venta_draft.dart';
import '../../models/venta_en_visita.dart';
import '../../models/venta_social.dart';
import '../../models/visita_estado.dart';
import '../../models/visita_model.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/canje_repository.dart';
import '../../repositories/comodato_repository.dart';
import '../../repositories/evidencia_repository.dart';
import '../../repositories/network_exception.dart';
import '../../repositories/venta_repository.dart';
import '../../repositories/stock_rodante_repository.dart';
import '../../repositories/visita_repository.dart';
import '../../services/canje_sync_manager.dart';
import '../../services/comodato_sync_manager.dart';
import '../../services/connectivity_service.dart';
import '../../services/location_service.dart';
import '../../services/photo_capture_service.dart';
import '../../services/sync_manager.dart';
import '../../services/ubicacion_tracking_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/formato.dart';
import '../../utils/json_parsing.dart';
import '../../models/credito_cliente.dart';
import '../../widgets/chofer/canje/canje_garrafa_card.dart';
import '../../widgets/chofer/comodato/control_comodato_card.dart';
import '../../widgets/chofer/cobro/morosidad_banner.dart';
import '../../widgets/chofer/datos_desactivados_card.dart';
import '../../widgets/chofer/evidencia_captura_card.dart';
import '../../widgets/chofer/inicio_sin_conexion_card.dart';
import '../../widgets/chofer/visita_checkin_card.dart';
import '../../widgets/common/estado_conexion_badge.dart';
import '../../widgets/primary_button.dart';
import 'canje/canje_garrafa_screen.dart';
import 'comodato/auditoria_comodato_screen.dart';
import 'cobro/registro_cobro_screen.dart';
import 'venta/registro_venta_screen.dart';
import 'venta_social/finalizar_venta_social_screen.dart';

const _uuid = Uuid();

enum _FaseVisita {
  verificandoUbicacion,
  datosDesactivados,
  sinConexion,
  errorUbicacion,
  enCurso,
}

class VisitaActivaScreen extends StatefulWidget {
  final VisitaModel visita;
  final String nombreCliente;
  final String direccionCliente;

  const VisitaActivaScreen({
    super.key,
    required this.visita,
    required this.nombreCliente,
    required this.direccionCliente,
  });

  @override
  State<VisitaActivaScreen> createState() => _VisitaActivaScreenState();
}

class _VisitaActivaScreenState extends State<VisitaActivaScreen> {
  late final VisitaRepository _visitaRepo;
  late final EvidenciaRepository _evidenciaRepo;
  late final VentaRepository _ventaRepo;
  late final ComodatoRepository _comodatoRepo;
  late final CanjeRepository _canjeRepo;
  late final StockRodanteRepository _rodanteChoferRepo;
  late final http.Client _apiClient;
  final _photoService = PhotoCaptureService();
  final _locationService = LocationService.instance;

  static const String _mensajeSinCarga =
      'Todavía no tenés stock asignado para hoy. Pedile al administrador que cargue tu stock del camión para poder iniciar las visitas.';
  IconData _iconoError = Icons.location_off_outlined;
  bool? _rutaHabilitada;

  late VisitaModel _visita;
  _FaseVisita _fase = _FaseVisita.verificandoUbicacion;
  String? _errorMensaje;
  File? _foto;
  bool _capturandoFoto = false;
  bool _finalizando = false;
  bool _cancelando = false;
  bool _evidenciaExistente = false;
  bool _checkInPendienteSync = false;
  bool _reintentandoConexion = false;
  bool _reintentandoDatos = false;
  bool _continuandoOffline = false;
  final List<VentaEnVisita> _ventas = [];
  PausaSocialDraft? _pausaSocial;
  bool _procesandoSocial = false;
  bool _ventaSocialFinalizada = false;
  bool _ventaSocialPendienteSync = false;

  int get _montoVentaSocial =>
      _ventas.where((v) => v.esSocial).fold(0, (a, v) => a + v.monto);

  bool get _yaTieneVentaSocial =>
      _pausaSocial != null ||
      _ventaSocialFinalizada ||
      _visita.estadoVisita == VisitaEstado.pausadaSocial ||
      _ventas.any((v) => v.esSocial);
  ContratoComodato? _contratoComodato;
  bool _cargandoContrato = false;
  ControlComodatoDraft? _controlComodato;
  bool _comodatoPendienteSync = false;
  bool _comodatoPreparado = false;
  List<CanjeGarrafaDraft> _canjes = [];
  List<CanjeGarrafaDraft> _canjesServidor = [];
  bool _canjePendienteSync = false;
  bool _online = true;
  bool _ventaSocialInconsistente = false;
  final _motivoFaltanteCtrl = TextEditingController();
  VoidCallback? _colaListener;
  VoidCallback? _comodatoListener;
  VoidCallback? _canjeListener;
  StreamSubscription<bool>? _conexionSub;

  @override
  void initState() {
    super.initState();
    _visita = widget.visita;
    final apiClient = context.read<AuthProvider>().apiClient;
    _visitaRepo = VisitaRepository(apiClient);
    _rodanteChoferRepo = StockRodanteRepository(apiClient);
    _evidenciaRepo = EvidenciaRepository(apiClient);
    _ventaRepo = VentaRepository(apiClient);
    _comodatoRepo = ComodatoRepository(apiClient);
    _canjeRepo = CanjeRepository(apiClient);
    _apiClient = apiClient;

    _motivoFaltanteCtrl.addListener(() {
      if (mounted) setState(() {});
    });

    _colaListener = _actualizarPendienteSync;
    OfflineQueueService.instance.escuchar().addListener(_colaListener!);

    _comodatoListener = _actualizarComodatoPendienteSync;
    ComodatoOfflineService.instance.escuchar().addListener(_comodatoListener!);

    _canjeListener = _actualizarCanjes;
    CanjeOfflineService.instance.escuchar().addListener(_canjeListener!);

    final idAgendaItemSocial = _visita.idAgendaItem;
    if (idAgendaItemSocial != null) {
      if (_visita.estadoVisita == VisitaEstado.pausadaSocial) {
        _pausaSocial = VentaSocialLocalService.instance.obtener(idAgendaItemSocial);
      }
      _ventaSocialFinalizada =
          VentaSocialLocalService.instance.estaFinalizada(idAgendaItemSocial);
      _ventaSocialPendienteSync = OfflineQueueService.instance
          .pendientesDeAgendaItem(idAgendaItemSocial)
          .any((e) =>
              e.tipoEvento == OfflineEventoTipo.pausarSocial ||
              e.tipoEvento == OfflineEventoTipo.reanudarSocial);
    }

    _conexionSub = ConnectivityService.instance.observarConexion().listen((online) {
      if (mounted && online != _online) {
        setState(() => _online = online);
      }
      if (online && _fase == _FaseVisita.datosDesactivados) {
        _iniciarCheckIn();
      }
    });
    unawaited(_actualizarConexionInicial());

    if (_visita.estadoVisita == VisitaEstado.enCurso ||
        _visita.estadoVisita == VisitaEstado.pausadaSocial) {
      _reanudarVisita();
    } else {
      _iniciarCheckIn();
    }
  }

  @override
  void dispose() {
    if (_colaListener != null) {
      OfflineQueueService.instance.escuchar().removeListener(_colaListener!);
    }
    if (_comodatoListener != null) {
      ComodatoOfflineService.instance.escuchar().removeListener(_comodatoListener!);
    }
    if (_canjeListener != null) {
      CanjeOfflineService.instance.escuchar().removeListener(_canjeListener!);
    }
    _conexionSub?.cancel();
    _motivoFaltanteCtrl.dispose();
    UbicacionTrackingService.instance.setVisitaActual(null);
    super.dispose();
  }

  bool get _hayFaltante {
    final ventaConFaltante =
        _ventas.any((v) => v.draft?.hayInconsistencias == true);
    return ventaConFaltante || _ventaSocialInconsistente;
  }

  String get _motivoFaltante => _motivoFaltanteCtrl.text.trim();

  bool get _faltanteResuelto => !_hayFaltante || _motivoFaltante.isNotEmpty;

  Future<void> _actualizarConexionInicial() async {
    final online = await ConnectivityService.instance.tieneConexion();
    if (mounted && online != _online) {
      setState(() => _online = online);
    }
  }

  void _actualizarPendienteSync() {
    final idAgendaItem = _visita.idAgendaItem;
    if (idAgendaItem == null) return;
    final pendientes =
        OfflineQueueService.instance.pendientesDeAgendaItem(idAgendaItem);
    final sigoPendiente =
        pendientes.any((e) => e.tipoEvento == OfflineEventoTipo.checkIn);
    final socialPendiente = pendientes.any((e) =>
        e.tipoEvento == OfflineEventoTipo.pausarSocial ||
        e.tipoEvento == OfflineEventoTipo.reanudarSocial);
    if (!mounted) return;
    if (sigoPendiente != _checkInPendienteSync ||
        socialPendiente != _ventaSocialPendienteSync) {
      setState(() {
        _checkInPendienteSync = sigoPendiente;
        _ventaSocialPendienteSync = socialPendiente;
      });
    }
  }

  ClienteFicha get _ficha => ClienteFicha.fromVisita(
        _visita,
        nombreResuelto: widget.nombreCliente,
        domicilioResuelto: widget.direccionCliente,
      );

  void _actualizarComodatoPendienteSync() {
    final idVisita = _visita.idVisita;
    final idAgendaItem = _visita.idAgendaItem;
    ComodatoPendiente? pendiente;
    if (idVisita != null) {
      pendiente = ComodatoOfflineService.instance.pendienteDeVisita(idVisita);
    }
    if (pendiente == null && idAgendaItem != null) {
      pendiente = ComodatoOfflineService.instance.pendienteDeAgendaItem(idAgendaItem);
    }
    final sigue = pendiente != null;
    if (mounted && sigue != _comodatoPendienteSync) {
      setState(() => _comodatoPendienteSync = sigue);
    }
  }

  Future<void> _prepararComodato() async {
    if (_comodatoPreparado) return;
    _comodatoPreparado = true;
    unawaited(_hidratarCanjes());
    await _hidratarControlComodato();
    await _cargarContratoComodato();
  }

  int? get _idClienteExt {
    final snapshot = _visita.sucursalSnapshot;
    return parseInt(snapshot['idClienteExt']) ??
        parseInt(snapshot['clienteId']) ??
        int.tryParse(_ficha.clienteId);
  }

  bool get _mostrarComodato =>
      _controlComodato != null ||
      (_contratoComodato?.tieneComodato ?? false) ||
      (_ficha.tieneComodatoActivo && _cargandoContrato);

  Future<void> _hidratarControlComodato() async {
    final idAgendaItem = _visita.idAgendaItem;
    final idVisita = _visita.idVisita;

    ComodatoPendiente? pendiente;
    if (idVisita != null) {
      pendiente = ComodatoOfflineService.instance.pendienteDeVisita(idVisita);
    }
    if (pendiente == null && idAgendaItem != null) {
      pendiente = ComodatoOfflineService.instance.pendienteDeAgendaItem(idAgendaItem);
    }
    if (pendiente != null) {
      if (!mounted) return;
      setState(() {
        _controlComodato = _draftDePendiente(pendiente!);
        _comodatoPendienteSync = true;
      });
      return;
    }

    if (idVisita == null) return;
    try {
      final control = await _comodatoRepo.getControlDeVisita(idVisita);
      if (!mounted || control == null) return;
      setState(() {
        _controlComodato = _draftDeControl(control);
        _comodatoPendienteSync = false;
      });
    } on NetworkException {
      return;
    } on ComodatoRepositoryException {
      return;
    }
  }

  Future<void> _cargarContratoComodato() async {
    final idExt = _idClienteExt;
    if (idExt == null) return;
    if (mounted) setState(() => _cargandoContrato = true);
    try {
      final contrato = await _comodatoRepo.getContratoCliente(idExt);
      if (!mounted) return;
      setState(() => _contratoComodato = contrato);
    } on NetworkException {
      return;
    } on ComodatoRepositoryException {
      return;
    } finally {
      if (mounted) setState(() => _cargandoContrato = false);
    }
  }

  ControlComodatoDraft _draftDeControl(ControlComodato c) {
    return ControlComodatoDraft(
      idVisita: c.idVisita ?? _visita.idVisita,
      idAgendaItem: _visita.idAgendaItem,
      idUsuario: _visita.idUsuario,
      fecha: _visita.fecha,
      idClienteExt: c.idClienteExt ?? _idClienteExt,
      uuidOffline: c.uuidOffline ?? '',
      timestampControl: c.timestampControl ?? DateTime.now(),
      observaciones: c.observaciones,
      cantidadContratada: c.cantidadContratada,
      cantidadFisicaActual: c.cantidadFisicaActual,
    );
  }

  ControlComodatoDraft _draftDePendiente(ComodatoPendiente p) {
    return ControlComodatoDraft(
      idVisita: p.idVisita,
      idAgendaItem: p.idAgendaItem,
      idUsuario: p.idUsuario,
      fecha: p.fecha,
      idClienteExt: p.idClienteExt,
      uuidOffline: p.uuidOffline,
      timestampControl: p.timestampControl,
      observaciones: p.observaciones,
      cantidadContratada: p.cantidadContratada,
      cantidadFisicaActual: p.cantidadFisicaActual,
    );
  }

  Future<void> _abrirAuditoriaComodato() async {
    var contrato = _contratoComodato;
    if (contrato == null) {
      await _cargarContratoComodato();
      contrato = _contratoComodato;
    }
    if (!mounted) return;
    if (contrato == null || !contrato.tieneComodato) {
      _mostrarError(
        'No se pudo cargar el contrato de comodato del cliente. Reintentá cuando tengas conexión.',
      );
      return;
    }
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AuditoriaComodatoScreen(
          nombreCliente: widget.nombreCliente,
          contrato: contrato!,
          controlPrevio: _controlComodato,
          onGuardar: _registrarControlComodato,
        ),
      ),
    );
  }

  Future<void> _registrarControlComodato(
    int cantidadFisicaActual,
    String? observaciones,
  ) async {
    final idVisita = await _asegurarIdVisita();
    final idAgendaItem = _visita.idAgendaItem;
    final ahora = DateTime.now();
    final draft = ControlComodatoDraft(
      idVisita: idVisita,
      idAgendaItem: idAgendaItem,
      idUsuario: _visita.idUsuario,
      fecha: _visita.fecha,
      idClienteExt: _contratoComodato?.idClienteExt ?? _idClienteExt,
      uuidOffline: _uuid.v4(),
      timestampControl: ahora,
      observaciones: observaciones,
      cantidadContratada: _contratoComodato?.cantidadContratada ?? 0,
      cantidadFisicaActual: cantidadFisicaActual,
    );

    if (idVisita != null) {
      try {
        final control = await _comodatoRepo.registrarControl(draft);
        if (!mounted) return;
        setState(() {
          _controlComodato = _draftDeControl(control);
          _comodatoPendienteSync = false;
        });
        return;
      } on NetworkException {}
    }

    if (idAgendaItem == null) {
      throw ComodatoRepositoryException(
        'La visita no tiene un ítem de agenda para guardar el control localmente.',
      );
    }

    await _encolarControlComodato(draft: draft, idAgendaItem: idAgendaItem);
    if (!mounted) return;
    setState(() {
      _controlComodato = draft;
      _comodatoPendienteSync = true;
    });
  }

  Future<void> _encolarControlComodato({
    required ControlComodatoDraft draft,
    required int idAgendaItem,
  }) async {
    final ahora = DateTime.now();
    await ComodatoOfflineService.instance.encolar(
      ComodatoPendiente(
        uuidOffline: draft.uuidOffline,
        idVisita: draft.idVisita,
        idAgendaItem: idAgendaItem,
        idUsuario: draft.idUsuario,
        fecha: draft.fecha,
        idClienteExt: draft.idClienteExt,
        timestampControl: draft.timestampControl,
        observaciones: draft.observaciones,
        cantidadContratada: draft.cantidadContratada,
        cantidadFisicaActual: draft.cantidadFisicaActual,
        creadoEn: ahora,
      ),
    );
    unawaited(ComodatoSyncManager.instance.sincronizar());
  }

  void _actualizarCanjes() => _recomputarCanjes();

  List<CanjeGarrafaDraft> _canjesPendientesActuales() {
    final idVisita = _visita.idVisita;
    final idAgendaItem = _visita.idAgendaItem;
    final servicio = CanjeOfflineService.instance;
    List<CanjePendiente> pendientes = const [];
    if (idVisita != null) {
      pendientes = servicio.pendientesDeVisita(idVisita);
    }
    if (pendientes.isEmpty && idAgendaItem != null) {
      pendientes = servicio.pendientesDeAgendaItem(idAgendaItem);
    }
    return pendientes.map(_draftDeCanjePendiente).toList();
  }

  void _recomputarCanjes() {
    final pendientes = _canjesPendientesActuales();
    final uuidsPendientes = pendientes.map((c) => c.uuidOffline).toSet();
    final servidor = _canjesServidor
        .where((c) => !uuidsPendientes.contains(c.uuidOffline))
        .toList();
    if (!mounted) return;
    setState(() {
      _canjes = [...servidor, ...pendientes];
      _canjePendienteSync = pendientes.isNotEmpty;
    });
  }

  Future<void> _hidratarCanjes() async {
    final idVisita = _visita.idVisita;
    if (idVisita != null) {
      try {
        final canjes = await _canjeRepo.getCanjesDeVisita(idVisita);
        if (!mounted) return;
        _canjesServidor = canjes.map(_draftDeCanje).toList();
      } on NetworkException {
      } on CanjeRepositoryException {}
    }
    _recomputarCanjes();
  }

  Future<void> _abrirCanje() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CanjeGarrafaScreen(
          visita: _visita,
          nombreCliente: widget.nombreCliente,
          onGuardar: _registrarCanje,
        ),
      ),
    );
  }

  Future<int?> _asegurarIdVisita() async {
    final actual = _visita.idVisita;
    if (actual != null) return actual;
    final idAgendaItem = _visita.idAgendaItem;
    final fecha = _visita.fecha;
    if (idAgendaItem == null || fecha == null) return null;
    try {
      final items = await _visitaRepo.getVisitasPorUsuarioYFecha(
        idUsuario: _visita.idUsuario,
        fecha: fecha,
      );
      for (final item in items) {
        if (item.idAgendaItem == idAgendaItem && item.idVisita != null) {
          if (mounted) {
            setState(() => _visita = _visita.copyWith(idVisita: item.idVisita));
          }
          return item.idVisita;
        }
      }
    } on NetworkException {
      return null;
    } catch (_) {
      return null;
    }
    return null;
  }

  Future<void> _registrarCanje(ProductoSku producto, String descripcionDanio) async {
    final idVisita = await _asegurarIdVisita();
    final idAgendaItem = _visita.idAgendaItem;
    final draft = CanjeGarrafaDraft(
      idVisita: idVisita,
      idAgendaItem: idAgendaItem,
      idUsuario: _visita.idUsuario,
      fecha: _visita.fecha,
      idClienteExt: _idClienteExt,
      uuidOffline: _uuid.v4(),
      productoId: producto.idProducto,
      sku: producto.sku,
      descripcion: producto.descripcion,
      kg: producto.kg,
      descripcionDanio: descripcionDanio,
      timestamp: DateTime.now(),
    );

    if (idVisita != null) {
      try {
        await _canjeRepo.registrarCanje(idVisita, draft);
        await StockRodanteCacheService.instance
            .aplicarSalidas(_visita.idUsuario, {producto.idProducto: 1});
        if (!mounted) return;
        _canjesServidor = [..._canjesServidor, draft];
        _recomputarCanjes();
        return;
      } on NetworkException {}
    }

    if (idAgendaItem == null) {
      throw CanjeRepositoryException(
        'La visita no tiene un ítem de agenda para guardar el canje localmente.',
      );
    }

    await _encolarCanje(draft: draft, idAgendaItem: idAgendaItem);
    await StockRodanteCacheService.instance
        .aplicarSalidas(_visita.idUsuario, {producto.idProducto: 1});
  }

  Future<void> _encolarCanje({
    required CanjeGarrafaDraft draft,
    required int idAgendaItem,
  }) async {
    final ahora = DateTime.now();
    await CanjeOfflineService.instance.encolar(
      CanjePendiente(
        uuidOffline: draft.uuidOffline,
        idVisita: draft.idVisita,
        idAgendaItem: idAgendaItem,
        idUsuario: draft.idUsuario,
        fecha: draft.fecha,
        idClienteExt: draft.idClienteExt,
        productoId: draft.productoId,
        sku: draft.sku,
        descripcion: draft.descripcion,
        kg: draft.kg,
        descripcionDanio: draft.descripcionDanio,
        timestamp: draft.timestamp,
        creadoEn: ahora,
      ),
    );
    unawaited(CanjeSyncManager.instance.sincronizar());
  }

  CanjeGarrafaDraft _draftDeCanje(CanjeGarrafa c) {
    return CanjeGarrafaDraft(
      idVisita: c.idVisita ?? _visita.idVisita,
      idAgendaItem: _visita.idAgendaItem,
      idUsuario: _visita.idUsuario,
      fecha: _visita.fecha,
      idClienteExt: _idClienteExt,
      uuidOffline: c.uuidOffline ?? '',
      productoId: c.productoId ?? '',
      sku: c.sku ?? '',
      descripcion: c.descripcion,
      kg: c.kg,
      descripcionDanio: c.descripcionDanio,
      timestamp: c.timestamp ?? DateTime.now(),
    );
  }

  CanjeGarrafaDraft _draftDeCanjePendiente(CanjePendiente p) {
    return CanjeGarrafaDraft(
      idVisita: p.idVisita,
      idAgendaItem: p.idAgendaItem,
      idUsuario: p.idUsuario,
      fecha: p.fecha,
      idClienteExt: p.idClienteExt,
      uuidOffline: p.uuidOffline,
      productoId: p.productoId,
      sku: p.sku,
      descripcion: p.descripcion,
      kg: p.kg,
      descripcionDanio: p.descripcionDanio,
      timestamp: p.timestamp,
    );
  }

  void _entrarEnErrorUbicacion(
    String mensaje, {
    IconData icono = Icons.location_off_outlined,
  }) {
    setState(() {
      _fase = _FaseVisita.errorUbicacion;
      _errorMensaje = mensaje;
      _iconoError = icono;
    });
  }

  Future<EstadoRutaChofer?> _verificarRutaHabilitada() async {
    try {
      final estado = await _rodanteChoferRepo.estadoRuta(fecha: _visita.fecha);
      if (estado == null) return null;
      _rutaHabilitada = estado.habilitado;
      return estado;
    } on NetworkException {
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _iniciarCheckIn() async {
    final idAgendaItem = _visita.idAgendaItem;
    final idVisitaExistente = _visita.idVisita;
    if (idAgendaItem == null && idVisitaExistente == null) {
      _entrarEnErrorUbicacion('La visita no tiene un identificador válido.');
      return;
    }

    setState(() {
      _fase = _FaseVisita.verificandoUbicacion;
      _errorMensaje = null;
    });

    final hayConexion = await ConnectivityService.instance.tieneConexion();
    if (!mounted) return;
    if (!hayConexion) {
      setState(() => _fase = _FaseVisita.datosDesactivados);
      return;
    }

    final estadoRuta = await _verificarRutaHabilitada();
    if (!mounted) return;
    if (estadoRuta != null && !estadoRuta.habilitado) {
      final mensaje = estadoRuta.tieneNota &&
              estadoRuta.mensaje != null &&
              estadoRuta.mensaje!.isNotEmpty
          ? estadoRuta.mensaje!
          : _mensajeSinCarga;
      _entrarEnErrorUbicacion(mensaje, icono: Icons.inventory_2_outlined);
      return;
    }

    LocationCheckIn? checkIn;
    try {
      checkIn = await _locationService.obtenerUbicacionActual();

      final latObjetivo = _visita.sucursalLatitud;
      final lonObjetivo = _visita.sucursalLongitud;
      debugPrint(
        '[CHECKIN] device=(${checkIn.latitud}, ${checkIn.longitud}) '
        'precision=${checkIn.precisionMetros}m '
        'objetivo=($latObjetivo, $lonObjetivo) '
        'distancia=${(latObjetivo != null && lonObjetivo != null) ? _locationService.distanciaMetros(checkIn.latitud, checkIn.longitud, latObjetivo, lonObjetivo).toStringAsFixed(1) : 'sin-objetivo'}m',
      );
      if (latObjetivo != null &&
          lonObjetivo != null &&
          !_locationService.estaCercaDe(checkIn, latObjetivo, lonObjetivo)) {
        if (!mounted) return;
        _entrarEnErrorUbicacion(
          'No estás cerca de la ubicación del cliente. Acercate al domicilio para poder registrar el check-in.',
        );
        return;
      }

      if (idVisitaExistente == null) {
        await _iniciarViaColaSincronizacion(
          idAgendaItem: idAgendaItem!,
          idVisita: null,
          checkIn: checkIn,
        );
        return;
      }

      final actualizada = await _visitaRepo.iniciarVisita(
        idVisitaExistente,
        latitud: checkIn.latitud,
        longitud: checkIn.longitud,
        timestampDispositivo: checkIn.timestamp,
        precisionMetros: checkIn.precisionMetros,
      );

      if (!mounted) return;
      setState(() {
        _visita = actualizada.copyWith(idAgendaItem: _visita.idAgendaItem);
        _fase = _FaseVisita.enCurso;
      });

      unawaited(UbicacionTrackingService.instance.iniciar(_apiClient));
      UbicacionTrackingService.instance.setVisitaActual(_visita.idVisita);
      unawaited(_prepararComodato());
    } on LocationServiceException catch (e) {
      if (!mounted) return;
      _entrarEnErrorUbicacion(e.message);
    } on NetworkException {
      if (!mounted) return;
      if (_visita.idAgendaItem == null) {
        _entrarEnErrorUbicacion(
          'No hay conexión y la visita no tiene un ítem de agenda asociado para guardarla localmente.',
        );
        return;
      }
      setState(() => _fase = _FaseVisita.sinConexion);
    } on VisitaRepositoryException catch (e) {
      if (!mounted) return;
      final esFaltaDeCarga = e.message.contains('Nota de Control de Stock') ||
          e.message.toLowerCase().contains('iniciar ruta');
      if (esFaltaDeCarga) {
        _rutaHabilitada = false;
        _entrarEnErrorUbicacion(_mensajeSinCarga, icono: Icons.inventory_2_outlined);
      } else {
        _entrarEnErrorUbicacion(e.message);
      }
    } catch (_) {
      if (!mounted) return;
      _entrarEnErrorUbicacion('No se pudo iniciar la visita. Intentá de nuevo.');
    }
  }

  Future<void> _reintentarConexion() async {
    if (_reintentandoConexion || _continuandoOffline) return;
    setState(() => _reintentandoConexion = true);
    // Mantenemos la rueda girando 3s en cada reintento para dar un feedback
    // visible al chofer antes de volver a chequear la conexión.
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    final hayConexion = await ConnectivityService.instance.tieneConexion();
    if (!mounted) return;
    setState(() => _reintentandoConexion = false);
    if (hayConexion) {
      _iniciarCheckIn();
    } else {
      _mostrarAviso(
        'Seguís sin conexión. Podés continuar offline o volver a intentar.',
      );
    }
  }

  Future<void> _reintentarDatos() async {
    if (_reintentandoDatos) return;
    setState(() => _reintentandoDatos = true);
    // La rueda gira 3s en cada reintento antes de volver a chequear los datos
    // móviles / WiFi y reiniciar el check-in.
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    setState(() => _reintentandoDatos = false);
    _iniciarCheckIn();
  }

  Future<void> _continuarOffline() async {
    final idAgendaItem = _visita.idAgendaItem;
    if (idAgendaItem == null) {
      _mostrarError(
        'La visita no tiene un ítem de agenda para guardarla localmente.',
      );
      return;
    }
    if (_rutaHabilitada == false) {
      _entrarEnErrorUbicacion(_mensajeSinCarga, icono: Icons.inventory_2_outlined);
      return;
    }
    if (_continuandoOffline || _reintentandoConexion) return;
    setState(() => _continuandoOffline = true);
    final checkIn = await _obtenerUbicacionBestEffort();
    await _iniciarViaColaSincronizacion(
      idAgendaItem: idAgendaItem,
      idVisita: _visita.idVisita,
      checkIn: checkIn,
      porFallaDeRed: true,
      forzado: true,
    );
    if (mounted) setState(() => _continuandoOffline = false);
  }

  Future<LocationCheckIn?> _obtenerUbicacionBestEffort() async {
    try {
      return await _locationService.obtenerUbicacionActual();
    } catch (_) {
      return _locationService.ultimoCheckInConocido;
    }
  }

  Future<void> _iniciarViaColaSincronizacion({
    required int idAgendaItem,
    int? idVisita,
    required LocationCheckIn? checkIn,
    bool porFallaDeRed = false,
    bool forzado = false,
  }) async {
    final ahora = DateTime.now();

    await OfflineQueueService.instance.encolar(
      OfflineEvento(
        uuidOffline: _uuid.v4(),
        tipoEvento: OfflineEventoTipo.checkIn,
        idAgendaItem: idAgendaItem,
        idVisita: idVisita,
        timestampOrigen: ahora,
        creadoEn: ahora,
        latitud: checkIn?.latitud,
        longitud: checkIn?.longitud,
        checkInForzado: forzado,
      ),
    );

    if (!mounted) return;
    setState(() {
      _visita = _visita.copyWith(
        estadoVisita: VisitaEstado.enCurso,
        timestampInicio: ahora,
        latitudInicio: checkIn?.latitud,
        longitudInicio: checkIn?.longitud,
        geolocalizacionValida: false,
      );
      _fase = _FaseVisita.enCurso;
      _checkInPendienteSync = true;
    });

    // Arranca igual el seguimiento en segundo plano; si la señal vuelve
    // durante la visita, el SyncManager va a mandar la cola sin que el
    // chofer tenga que hacer nada.
    unawaited(UbicacionTrackingService.instance.iniciar(_apiClient));
    UbicacionTrackingService.instance.setVisitaActual(_visita.idVisita);
    unawaited(SyncManager.instance.sincronizar());
    unawaited(_prepararComodato());

    _mostrarAviso(
      porFallaDeRed
          ? 'Sin conexión: el check-in se guardó en el dispositivo y se enviará cuando haya señal.'
          : 'Check-in guardado. Se está confirmando con el servidor…',
    );
  }

  /// Reanuda una visita que ya estaba EN_CURSO (el check-in ya se hizo en
  /// una sesión anterior): no vuelve a pedir geolocalización de inicio,
  /// solo retoma el tracking en segundo plano y revisa si ya había una
  /// evidencia fotográfica cargada.
  Future<void> _reanudarVisita() async {
    setState(() {
      _fase = _FaseVisita.enCurso;
      _errorMensaje = null;
      _checkInPendienteSync = _visita.idAgendaItem != null &&
          OfflineQueueService.instance
              .pendientesDeAgendaItem(_visita.idAgendaItem!)
              .any((e) => e.tipoEvento == OfflineEventoTipo.checkIn);
    });

    unawaited(UbicacionTrackingService.instance.iniciar(_apiClient));
    UbicacionTrackingService.instance.setVisitaActual(_visita.idVisita);
    unawaited(_prepararComodato());
    unawaited(_hidratarVentas());

    final idVisita = _visita.idVisita;
    if (idVisita == null) return;
    try {
      final evidencias = await _evidenciaRepo.listarPorVisita(idVisita);
      if (!mounted) return;
      if (evidencias.isNotEmpty) {
        setState(() => _evidenciaExistente = true);
      }
    } on NetworkException {
      // Sin conexión no podemos saber si ya había evidencia cargada; no
      // bloqueamos la pantalla, el chofer puede sacar una foto nueva.
    } on EvidenciaRepositoryException {
      // Si falla la consulta no bloqueamos la pantalla: el chofer puede
      // igual sacar una foto nueva para poder finalizar.
    }
  }

  Future<void> _hidratarVentas() async {
    final idVisita = _visita.idVisita ?? await _asegurarIdVisita();
    if (idVisita == null) return;
    List<VentaEnVisita> servidor;
    try {
      servidor = await _ventaRepo.getVentasDeVisita(idVisita);
    } on NetworkException {
      return;
    } on VentaRepositoryException {
      return;
    } catch (_) {
      return;
    }
    if (!mounted || servidor.isEmpty) return;
    setState(() {
      final idsServidor = servidor.map((v) => v.idVenta).whereType<int>().toSet();
      final locales = _ventas
          .where((v) => v.idVenta == null || !idsServidor.contains(v.idVenta))
          .toList();
      _ventas
        ..clear()
        ..addAll(servidor)
        ..addAll(locales);
      if (servidor.any((v) => v.esSocial)) {
        _ventaSocialFinalizada = true;
      }
    });
  }

  Future<void> _abrirRegistroVenta() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => RegistroVentaScreen(
          visita: _visita,
          nombreCliente: widget.nombreCliente,
          direccionCliente: widget.direccionCliente,
          inicial: null,
          ventaSocialBloqueada: _yaTieneVentaSocial,
          ventasPrevias: [
            for (final v in _ventas)
              if (!v.esSocial)
                VentaPreviaResumen(
                  etiqueta: v.etiqueta,
                  monto: v.monto,
                  detalle: detalleGarrafasDeVenta(v),
                ),
          ],
          onRegistrar: _registrarVentaMixta,
        ),
      ),
    );
  }

  Future<void> _registrarVentaMixta(VentaDraft venta) async {
    final sociales = venta.lineasSociales;
    final normales = venta.lineasVenta;

    if (normales.isNotEmpty) {
      await _registrarVenta(VentaDraft(lineas: normales.map((l) => l.copy()).toList()));
    }

    if (sociales.isNotEmpty) {
      final pausa = PausaSocialDraft(
        items: sociales
            .map((l) => EnvaseSocialEntregado(
                  idProducto: l.producto.idProducto,
                  sku: l.producto.sku,
                  descripcion: l.producto.descripcion,
                  kg: l.producto.kg,
                  cantidadEntregada: l.cantidadEntregada,
                  precioUnitario: l.producto.precioUnitario,
                ))
            .toList(),
        uuidOffline: _uuid.v4(),
        timestamp: DateTime.now(),
      );
      final ok = await _confirmarPausaSocial(pausa);
      if (!ok && mounted) {
        _mostrarErrorSocial(
          'No se pudo iniciar la Venta Social. Podés volver a intentarlo registrando la venta social de nuevo.',
        );
      }
    }

    final salidas = <String, int>{};
    for (final l in venta.lineas) {
      if (l.cantidadEntregada > 0) {
        salidas[l.producto.idProducto] =
            (salidas[l.producto.idProducto] ?? 0) + l.cantidadEntregada;
      }
    }
    if (salidas.isNotEmpty) {
      await StockRodanteCacheService.instance.aplicarSalidas(_visita.idUsuario, salidas);
    }
  }

  Future<bool> _confirmarPausaSocial(PausaSocialDraft draft) async {
    final idAgendaItem = _visita.idAgendaItem;
    setState(() => _procesandoSocial = true);
    final idVisita = await _asegurarIdVisita();

    if (idVisita != null) {
      try {
        await _visitaRepo.pausarSocial(idVisita, draft);
        if (idAgendaItem != null) {
          await VentaSocialLocalService.instance.guardar(idAgendaItem, draft);
        }
        if (!mounted) return true;
        setState(() {
          _visita = _visita.copyWith(estadoVisita: VisitaEstado.pausadaSocial);
          _pausaSocial = draft;
          _procesandoSocial = false;
          _ventaSocialPendienteSync = false;
        });
        return true;
      } on VisitaRepositoryException catch (e) {
        if (mounted) setState(() => _procesandoSocial = false);
        _mostrarErrorSocial(e.message);
        return false;
      } on NetworkException {
      } catch (_) {
        if (mounted) setState(() => _procesandoSocial = false);
        _mostrarErrorSocial('No se pudo iniciar la Venta Social.');
        return false;
      }
    }

    if (idAgendaItem == null) {
      if (mounted) setState(() => _procesandoSocial = false);
      _mostrarErrorSocial(
        'La visita no tiene un ítem de agenda para guardar la pausa localmente.',
      );
      return false;
    }

    await _encolarPausaSocial(
      idAgendaItem: idAgendaItem,
      idVisita: idVisita,
      draft: draft,
    );
    await VentaSocialLocalService.instance.guardar(idAgendaItem, draft);
    if (!mounted) return true;
    setState(() {
      _visita = _visita.copyWith(estadoVisita: VisitaEstado.pausadaSocial);
      _pausaSocial = draft;
      _procesandoSocial = false;
      _ventaSocialPendienteSync = true;
    });
    _mostrarInfoSocial(
      'Sin conexión: la pausa se guardó en el dispositivo y se enviará cuando haya señal.',
    );
    return true;
  }

  Future<void> _encolarPausaSocial({
    required int idAgendaItem,
    int? idVisita,
    required PausaSocialDraft draft,
  }) async {
    await OfflineQueueService.instance.encolar(
      OfflineEvento(
        uuidOffline: draft.uuidOffline,
        tipoEvento: OfflineEventoTipo.pausarSocial,
        idAgendaItem: idAgendaItem,
        idVisita: idVisita,
        timestampOrigen: draft.timestamp,
        creadoEn: DateTime.now(),
        socialPayloadJson: jsonEncode(draft.toEventoOfflineJson()),
      ),
    );
    unawaited(SyncManager.instance.sincronizar());
  }

  Future<void> _finalizarVentaSocial() async {
    final pausa = _pausaSocial;
    if (pausa == null) {
      _mostrarErrorSocial(
        'No se encontró el detalle de lo entregado en este dispositivo. Reintentá con conexión.',
      );
      return;
    }
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => FinalizarVentaSocialScreen(
          pausa: pausa,
          nombreCliente: widget.nombreCliente,
          onConfirmar: _confirmarReanudarSocial,
        ),
      ),
    );
  }

  Future<bool> _confirmarReanudarSocial(ReanudarSocialDraft draft) async {
    final idAgendaItem = _visita.idAgendaItem;
    setState(() => _procesandoSocial = true);
    final idVisita = _visita.idVisita ?? await _asegurarIdVisita();

    if (idVisita != null) {
      try {
        final res = await _visitaRepo.reanudarSocial(idVisita, draft);
        if (idAgendaItem != null) {
          await VentaSocialLocalService.instance.eliminar(idAgendaItem);
          await VentaSocialLocalService.instance.marcarFinalizada(idAgendaItem);
        }
        if (!mounted) return true;
        setState(() {
          _visita = _visita.copyWith(estadoVisita: VisitaEstado.enCurso);
          _pausaSocial = null;
          _procesandoSocial = false;
          _ventaSocialFinalizada = true;
          _ventaSocialPendienteSync = false;
          _ventaSocialInconsistente = !draft.cuadra;
          _ventas.removeWhere((v) => v.esSocial);
          if (res.tieneVenta) {
            _ventas.add(VentaEnVisita(
              key: draft.uuidOffline,
              idVenta: res.idVenta,
              monto: res.montoTotal,
              esSocial: true,
            ));
          }
        });
        _mostrarInfoSocial(
          res.tieneVenta
              ? 'Venta social liquidada: ${res.envasesVendidos} vendidas. Ya podés registrar el cobro.'
              : 'Cuadre completo. Todos los envases fueron devueltos, no hubo venta.',
        );
        return true;
      } on VisitaRepositoryException catch (e) {
        if (mounted) setState(() => _procesandoSocial = false);
        _mostrarErrorSocial(e.message);
        return false;
      } on NetworkException {
      } catch (_) {
        if (mounted) setState(() => _procesandoSocial = false);
        _mostrarErrorSocial('No se pudo finalizar la Venta Social.');
        return false;
      }
    }

    if (idAgendaItem == null) {
      if (mounted) setState(() => _procesandoSocial = false);
      _mostrarErrorSocial(
        'La visita no tiene un ítem de agenda para guardar la liquidación localmente.',
      );
      return false;
    }

    await _encolarReanudarSocial(
      idAgendaItem: idAgendaItem,
      idVisita: idVisita,
      draft: draft,
    );
    await VentaSocialLocalService.instance.eliminar(idAgendaItem);
    await VentaSocialLocalService.instance.marcarFinalizada(idAgendaItem);
    if (!mounted) return true;
    final hayVenta = draft.totalVendidos > 0;
    setState(() {
      _visita = _visita.copyWith(estadoVisita: VisitaEstado.enCurso);
      _pausaSocial = null;
      _procesandoSocial = false;
      _ventaSocialFinalizada = true;
      _ventaSocialInconsistente = !draft.cuadra;
      _ventas.removeWhere((v) => v.esSocial);
      if (hayVenta) {
        _ventas.add(VentaEnVisita(
          key: draft.uuidOffline,
          uuidOffline: draft.uuidOffline,
          monto: draft.montoVendidoLocal,
          esSocial: true,
          pendienteSync: true,
        ));
        _ventaSocialPendienteSync = true;
      }
    });
    _mostrarInfoSocial(
      hayVenta
          ? 'Sin conexión: la liquidación se guardó (${draft.totalVendidos} vendidas) y se enviará cuando haya señal. Ya podés registrar el cobro.'
          : 'Sin conexión: el cuadre se guardó y se enviará cuando haya señal. No hubo venta.',
    );
    return true;
  }

  Future<void> _encolarReanudarSocial({
    required int idAgendaItem,
    int? idVisita,
    required ReanudarSocialDraft draft,
  }) async {
    await OfflineQueueService.instance.encolar(
      OfflineEvento(
        uuidOffline: draft.uuidOffline,
        tipoEvento: OfflineEventoTipo.reanudarSocial,
        idAgendaItem: idAgendaItem,
        idVisita: idVisita,
        timestampOrigen: draft.timestamp,
        creadoEn: DateTime.now(),
        socialPayloadJson: jsonEncode(draft.toEventoOfflineJson()),
      ),
    );
    unawaited(SyncManager.instance.sincronizar());
  }

  void _mostrarErrorSocial(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: AppColors.error),
    );
  }

  void _mostrarInfoSocial(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: AppColors.steelBlue),
    );
  }

  List<VentaEnVisita> get _ventasCobrables =>
      _ventas.where((v) => v.referenciable && !v.cobrado).toList();

  int get _totalCobrable =>
      _ventasCobrables.fold(0, (a, v) => a + v.monto);

  List<CobroGarrafaItem> _garrafasDeVenta(VentaEnVisita v) {
    final lineas = v.draft?.lineas;
    if (lineas == null) return const [];
    final items = <CobroGarrafaItem>[];
    for (final l in lineas) {
      if (l.cantidadEntregada <= 0) continue;
      final descripcion = l.producto.descripcion.trim().isNotEmpty
          ? l.producto.descripcion.trim()
          : 'Garrafa ${l.producto.kg} kg';
      items.add(CobroGarrafaItem(
        descripcion: descripcion,
        cantidad: l.cantidadEntregada,
        monto: l.subtotal,
      ));
    }
    return items;
  }

  Future<Object?> _abrirCobroCombinado(List<VentaEnVisita> ventas) {
    final credito = CreditoCliente.fromSnapshot(_visita.sucursalSnapshot);
    final refs = ventas
        .map((v) => CobroVentaRef(
              idVenta: v.idVenta,
              uuidVentaOffline: v.idVenta == null ? v.uuidOffline : null,
              monto: v.monto,
              etiqueta: v.etiqueta,
              garrafas: _garrafasDeVenta(v),
            ))
        .toList();
    final montoTotal = ventas.fold(0, (a, v) => a + v.monto);
    final itemsNota = <NotaDebitoItem>[];
    for (final v in ventas) {
      itemsNota.addAll(NotaDebitoResumen.deVenta(v.draft).items);
    }
    return Navigator.of(context).push<Object?>(
      MaterialPageRoute(
        builder: (_) => RegistroCobroScreen(
          nombreCliente: widget.nombreCliente,
          montoSugerido: montoTotal,
          credito: credito,
          canjes: _canjes,
          notaDebito: NotaDebitoResumen(itemsNota),
          ventas: refs,
        ),
      ),
    );
  }

  Future<void> _cobrarTodo() async {
    final pendientes = _ventasCobrables;
    if (pendientes.isEmpty) return;
    final resultado = await _abrirCobroCombinado(pendientes);
    if (!mounted) return;
    if (resultado != null) {
      setState(() {
        for (final v in pendientes) {
          v.cobrado = true;
        }
      });
    }
  }

  Future<void> _registrarVenta(VentaDraft venta) async {
    final idVisita = _visita.idVisita;
    final idAgendaItem = _visita.idAgendaItem;

    if (idVisita != null) {
      try {
        final idVenta = await _ventaRepo.registrarVenta(idVisita: idVisita, venta: venta);
        if (!mounted) return;
        setState(() {
          _ventas.add(VentaEnVisita(
            key: _uuid.v4(),
            idVenta: idVenta,
            monto: venta.montoTotal,
            cantidadLineas: venta.lineas.length,
            draft: venta,
          ));
        });
        return;
      } on NetworkException {
      }
    }

    if (idAgendaItem == null) {
      throw VentaRepositoryException(
        'La visita no tiene un ítem de agenda para guardar la venta localmente.',
      );
    }

    final uuidVenta = await _encolarVenta(
      idAgendaItem: idAgendaItem,
      idVisita: idVisita,
      venta: venta,
    );
    if (!mounted) return;
    setState(() {
      _ventas.add(VentaEnVisita(
        key: uuidVenta,
        uuidOffline: uuidVenta,
        monto: venta.montoTotal,
        cantidadLineas: venta.lineas.length,
        draft: venta,
        pendienteSync: true,
      ));
    });
  }

  Future<String> _encolarVenta({
    required int idAgendaItem,
    int? idVisita,
    required VentaDraft venta,
  }) async {
    final ahora = DateTime.now();
    final items = venta.lineas.map((l) => l.toRequestJson()).toList();
    final uuidVenta = _uuid.v4();
    await OfflineQueueService.instance.encolar(
      OfflineEvento(
        uuidOffline: uuidVenta,
        tipoEvento: OfflineEventoTipo.venta,
        idAgendaItem: idAgendaItem,
        idVisita: idVisita,
        timestampOrigen: ahora,
        creadoEn: ahora,
        ventaItemsJson: jsonEncode(items),
      ),
    );
    unawaited(SyncManager.instance.sincronizar());
    return uuidVenta;
  }

  Future<void> _capturarFoto() async {
    setState(() => _capturandoFoto = true);
    try {
      final archivo = await _photoService.capturarFoto();
      if (!mounted) return;
      if (archivo != null) {
        setState(() => _foto = archivo);
      }
    } on PhotoCaptureException catch (e) {
      if (!mounted) return;
      _mostrarError(e.message);
    } finally {
      if (mounted) setState(() => _capturandoFoto = false);
    }
  }

  Future<int?> _resolverIdVisitaOnline() async {
    final idAgendaItem = _visita.idAgendaItem;
    if (idAgendaItem == null) return null;
    try {
      final items = await _visitaRepo.getVisitasPorUsuarioYFecha(
        idUsuario: _visita.idUsuario,
        fecha: _visita.fecha ?? DateTime.now(),
      );
      for (final item in items) {
        if (item.idAgendaItem == idAgendaItem) {
          return item.idVisita;
        }
      }
    } on NetworkException {
      return null;
    } on VisitaRepositoryException {
      return null;
    } catch (_) {
      return null;
    }
    return null;
  }

  Future<void> _finalizarVisita() async {
    final foto = _foto;
    var idVisita = _visita.idVisita;
    final idAgendaItem = _visita.idAgendaItem;
    if ((foto == null && !_evidenciaExistente) || _finalizando) {
      return;
    }
    if (idVisita == null && idAgendaItem == null) {
      _mostrarError('La visita no tiene un identificador válido.');
      return;
    }
    if (_visita.estadoVisita == VisitaEstado.pausadaSocial) {
      _mostrarError(
        'Tenés una Venta Social en curso. Finalizá la Venta Social antes de cerrar la visita.',
      );
      return;
    }
    if (_hayFaltante && _motivoFaltante.isEmpty) {
      _mostrarError(
        'Registrá el motivo del faltante de garrafas para poder cerrar la visita.',
      );
      return;
    }

    final motivoFaltante = _hayFaltante ? _motivoFaltante : null;

    final porCobrar = _ventasCobrables;
    if (porCobrar.isNotEmpty) {
      final resultado = await _abrirCobroCombinado(porCobrar);
      if (!mounted) return;
      if (resultado != null) {
        setState(() {
          for (final venta in porCobrar) {
            venta.cobrado = true;
          }
        });
      }
    }

    setState(() => _finalizando = true);

    if (idVisita == null) {
      idVisita = await _resolverIdVisitaOnline();
      if (!mounted) return;
      if (idVisita == null) {
        await _finalizarOffline(
          idAgendaItem: idAgendaItem!,
          idVisita: null,
          foto: foto,
          motivoFaltante: motivoFaltante,
        );
        return;
      }
    }

    // Si la evidencia ya estaba confirmada del lado del servidor (de una
    // sesión anterior, o porque la subimos recién en este intento), no
    // hace falta volver a encolarla si más adelante falla el check-out.
    bool evidenciaConfirmadaOnline = _evidenciaExistente;

    try {
      if (foto != null) {
        await _evidenciaRepo.subirEvidencia(
          idVisita: idVisita,
          tipoEvidencia: EvidenciaTipo.fachada,
          archivo: foto,
        );
        evidenciaConfirmadaOnline = true;
      }

      // Intento "best effort" de tomar la ubicación al cierre; el backend
      // la acepta como opcional (latitudFin/longitudFin), así que si el
      // chofer ya no tiene buena señal no bloqueamos el check-out por eso.
      double? latitudFin;
      double? longitudFin;
      try {
        final ubicacionFin = await _locationService.obtenerUbicacionActual();
        latitudFin = ubicacionFin.latitud;
        longitudFin = ubicacionFin.longitud;
      } on LocationServiceException {
        // Sin ubicación de cierre: no es obligatoria para el backend,
        // seguimos el check-out sin latitudFin/longitudFin.
        latitudFin = null;
        longitudFin = null;
      }

      final finalizada = await _visitaRepo.finalizarVisita(
        idVisita,
        latitudFin: latitudFin,
        longitudFin: longitudFin,
        observaciones: motivoFaltante,
        motivoFaltante: motivoFaltante,
      );
      UbicacionTrackingService.instance.setVisitaActual(null);

      if (!mounted) return;
      Navigator.of(context).pop(finalizada.copyWith(idAgendaItem: idAgendaItem));
    } on NetworkException {
      // Sin señal en algún punto del cierre (subida de foto y/o
      // check-out): encolamos lo que falte confirmar y cerramos la
      // visita localmente para no trabar al chofer.
      if (idAgendaItem == null) {
        if (!mounted) return;
        setState(() => _finalizando = false);
        _mostrarError(
          'No hay conexión y la visita no tiene un ítem de agenda asociado para guardarla localmente.',
        );
        return;
      }
      await _finalizarOffline(
        idAgendaItem: idAgendaItem,
        idVisita: idVisita,
        foto: evidenciaConfirmadaOnline ? null : foto,
        motivoFaltante: motivoFaltante,
      );
    } on EvidenciaRepositoryException catch (e) {
      if (!mounted) return;
      setState(() => _finalizando = false);
      _mostrarError(e.message);
    } on VisitaRepositoryException catch (e) {
      if (!mounted) return;
      setState(() => _finalizando = false);
      _mostrarError(e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _finalizando = false);
      _mostrarError('No se pudo finalizar la visita. Intentá de nuevo.');
    }
  }

  Future<void> _cancelarVisita() async {
    if (_cancelando || _finalizando) return;

    final idVisita = _visita.idVisita;
    if (idVisita == null) {
      _mostrarError(
        'No se puede cancelar todavía: el inicio de la visita aún no se '
        'confirmó con el servidor. Reintentá cuando tengas conexión.',
      );
      return;
    }

    final motivo = await _pedirMotivoCancelacion();
    if (motivo == null) return;

    setState(() => _cancelando = true);
    try {
      final cancelada = await _visitaRepo.cerrarVisitaConEstado(
        idVisita,
        'CANCELADA',
        observaciones: motivo.isEmpty ? null : motivo,
      );
      UbicacionTrackingService.instance.setVisitaActual(null);
      if (!mounted) return;
      Navigator.of(context).pop(cancelada.copyWith(idAgendaItem: _visita.idAgendaItem));
    } on NetworkException {
      if (!mounted) return;
      setState(() => _cancelando = false);
      _mostrarError(
        'Sin conexión: no se pudo cancelar la visita. Intentá cuando tengas señal.',
      );
    } on VisitaRepositoryException catch (e) {
      if (!mounted) return;
      setState(() => _cancelando = false);
      _mostrarError(e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _cancelando = false);
      _mostrarError('No se pudo cancelar la visita. Intentá de nuevo.');
    }
  }

  Future<String?> _pedirMotivoCancelacion() async {
    final ctrl = TextEditingController();
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancelar visita'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Confirmá si no se pudo hacer la entrega (no había nadie o no '
              'respondieron). No se va a registrar la última bajada.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Motivo (opcional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Volver'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Cancelar visita'),
          ),
        ],
      ),
    );
    final motivo = ctrl.text.trim();
    ctrl.dispose();
    if (confirmado != true) return null;
    return motivo;
  }

  /// Encola en la cola offline lo que falte del cierre (la foto, si no se
  /// pudo confirmar que ya llegó al servidor, y el check-out en sí), y
  /// deja la visita como VISITADO de forma optimista en el dispositivo.
  Future<void> _finalizarOffline({
    required int idAgendaItem,
    int? idVisita,
    required File? foto,
    String? motivoFaltante,
  }) async {
    final ahora = DateTime.now();
    final tsEvidencia = ahora;
    final tsCheckOut = ahora.add(const Duration(seconds: 1));

    if (foto != null) {
      final bytes = await foto.readAsBytes();
      await OfflineQueueService.instance.encolar(
        OfflineEvento(
          uuidOffline: _uuid.v4(),
          tipoEvento: OfflineEventoTipo.evidencia,
          idAgendaItem: idAgendaItem,
          idVisita: idVisita,
          timestampOrigen: tsEvidencia,
          creadoEn: tsEvidencia,
          archivoBytes: bytes,
          tipoEvidencia: EvidenciaTipo.fachada,
          mimeType: 'image/jpeg',
        ),
      );
    }

    await OfflineQueueService.instance.encolar(
      OfflineEvento(
        uuidOffline: _uuid.v4(),
        tipoEvento: OfflineEventoTipo.checkOut,
        idAgendaItem: idAgendaItem,
        idVisita: idVisita,
        timestampOrigen: tsCheckOut,
        creadoEn: tsCheckOut,
        timestampFin: ahora,
        observaciones:
            (motivoFaltante != null && motivoFaltante.isNotEmpty) ? motivoFaltante : null,
      ),
    );

    UbicacionTrackingService.instance.setVisitaActual(null);
    unawaited(SyncManager.instance.sincronizar());

    // Actualización optimista: reflejamos VISITADO ya mismo para que la
    // agenda mueva la tarjeta a "Clientes Visitados" sin que el chofer
    // tenga que esperar a tener señal.
    final visitaOptimista = _visita.copyWith(
      estadoVisita: VisitaEstado.visitado,
      timestampFin: ahora,
    );

    if (!mounted) return;
    Navigator.of(context).pop(visitaOptimista);
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: AppColors.error),
    );
  }

  void _mostrarAviso(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: AppColors.badgeAmber),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        Navigator.of(context).pop(_visita);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TopBar(orden: _visita.ordenVisita),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: _buildContenido(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVentaSocialSection() {
    final estado = _visita.estadoVisita;
    final esPausada = estado == VisitaEstado.pausadaSocial;

    if (_ventaSocialFinalizada && !esPausada) {
      return Padding(
        padding: const EdgeInsets.only(top: 18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.badgeGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.badgeGreen.withOpacity(0.5)),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle, size: 22, color: AppColors.badgeGreen),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Venta Social realizada con éxito',
                      style: AppTextStyles.label.copyWith(
                        fontSize: 14.5,
                        color: AppColors.badgeGreen,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _montoVentaSocial > 0
                          ? 'La liquidación quedó registrada. Ya podés continuar con el cobro y cerrar la visita.'
                          : 'El cuadre se completó. Ya podés continuar y cerrar la visita.',
                      style: AppTextStyles.footer.copyWith(color: AppColors.graphiteGray),
                    ),
                    if (_ventaSocialPendienteSync && !_online) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: const [
                          Icon(Icons.sync, size: 15, color: AppColors.badgeAmber),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Pendiente de sincronizar con el servidor. Se envía solo cuando hay señal.',
                              style: TextStyle(fontSize: 12, color: AppColors.graphiteGray),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!esPausada) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: esPausada ? AppColors.steelBlue.withOpacity(0.55) : AppColors.inputBorder,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.volunteer_activism_outlined, size: 20, color: AppColors.steelBlue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Venta Social', style: AppTextStyles.label.copyWith(fontSize: 15)),
                ),
                if (esPausada)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.steelBlue.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.pause_circle_outline, size: 14, color: AppColors.steelBlue),
                        const SizedBox(width: 5),
                        Text(
                          'Pausada - En proceso',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.steelBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (esPausada) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.propane_tank_rounded, size: 16, color: AppColors.orange),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _pausaSocial != null
                            ? 'Se dejaron ${_pausaSocial!.totalEntregado} garrafas en el punto. Al volver, contá lo devuelto y liquidá.'
                            : 'Visita pausada por Venta Social. Al volver, contá lo devuelto para liquidar.',
                        style: AppTextStyles.footer.copyWith(color: AppColors.graphiteGray),
                      ),
                    ),
                  ],
                ),
              ),
              if (_ventaSocialPendienteSync && !_online) ...[
                const SizedBox(height: 8),
                Row(
                  children: const [
                    Icon(Icons.sync, size: 15, color: AppColors.badgeAmber),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'La pausa está guardada en el dispositivo y se enviará cuando haya señal.',
                        style: TextStyle(fontSize: 12, color: AppColors.graphiteGray),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              PrimaryButton(
                text: 'Finalizar Venta Social',
                isLoading: _procesandoSocial,
                onPressed: _procesandoSocial ? null : _finalizarVentaSocial,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVentaSection() {
    final estaPausada = _visita.estadoVisita == VisitaEstado.pausadaSocial;
    final totalVentas = _ventas.fold(0, (a, v) => a + v.monto);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.point_of_sale_outlined, size: 20, color: AppColors.orange),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Ventas de la visita',
                  style: AppTextStyles.label.copyWith(fontSize: 15),
                ),
              ),
              if (_ventas.isNotEmpty)
                Text(
                  formatMoneda(totalVentas),
                  style: AppTextStyles.title.copyWith(fontSize: 16, color: AppColors.orange),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (_ventas.isEmpty)
            Text(
              'Cargá las garrafas entregadas (Vacío x Lleno, préstamo o envase). '
              'Podés registrar más de una venta en la misma visita.',
              style: AppTextStyles.footer,
            )
          else
            for (final v in _ventas) ...[
              _FilaVentaRegistrada(venta: v, online: _online),
              const SizedBox(height: 10),
            ],
          const SizedBox(height: 4),
          if (estaPausada)
            const _AvisoVentaPausada()
          else ...[
            OutlinedButton.icon(
              onPressed: _finalizando ? null : _abrirRegistroVenta,
              icon: const Icon(Icons.add, size: 20),
              label: Text(_ventas.isEmpty ? 'Registrar venta' : 'Registrar otra venta'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.orange,
                side: const BorderSide(color: AppColors.orange),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            if (_ventasCobrables.isNotEmpty) ...[
              const SizedBox(height: 10),
              PrimaryButton(
                text: 'Cobrar ${_ventasCobrables.length > 1 ? 'todas las ventas' : 'la venta'} · ${formatMoneda(_totalCobrable)}',
                isLoading: false,
                onPressed: _finalizando ? null : _cobrarTodo,
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildContenido() {
    switch (_fase) {
      case _FaseVisita.verificandoUbicacion:
        return _EstadoUbicacion(
          nombreCliente: widget.nombreCliente,
          direccionCliente: widget.direccionCliente,
        );
      case _FaseVisita.datosDesactivados:
        return DatosDesactivadosCard(
          nombreCliente: widget.nombreCliente,
          direccionCliente: widget.direccionCliente,
          reintentando: _reintentandoDatos,
          onReintentar: _reintentarDatos,
        );
      case _FaseVisita.sinConexion:
        return InicioSinConexionCard(
          nombreCliente: widget.nombreCliente,
          direccionCliente: widget.direccionCliente,
          reintentando: _reintentandoConexion,
          continuando: _continuandoOffline,
          onReintentarConexion: _reintentarConexion,
          onContinuarOffline: _continuarOffline,
        );
      case _FaseVisita.errorUbicacion:
        return _ErrorUbicacion(
          mensaje: _errorMensaje ?? 'No se pudo verificar tu ubicación.',
          icono: _iconoError,
          onReintentar: _iniciarCheckIn,
          onCancelar: () => Navigator.of(context).pop(),
        );
      case _FaseVisita.enCurso:
        final credito = CreditoCliente.fromSnapshot(_visita.sucursalSnapshot);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (credito.tieneAlerta) ...[
              MorosidadBanner(credito: credito),
              const SizedBox(height: 12),
            ],
            if (_checkInPendienteSync && !_online) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.badgeAmber.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.badgeAmber.withOpacity(0.4)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.sync, size: 16, color: AppColors.badgeAmber),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Check-in pendiente de confirmar con el servidor. Se actualiza solo.',
                        style: TextStyle(fontSize: 12, color: AppColors.graphiteGray),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            VisitaCheckinCard(
              nombreCliente: widget.nombreCliente,
              direccionCliente: widget.direccionCliente,
              estado: _visita.estadoVisita,
              horaCheckIn: _visita.timestampInicio,
              ficha: ClienteFicha.fromVisita(
                _visita,
                nombreResuelto: widget.nombreCliente,
                domicilioResuelto: widget.direccionCliente,
              ),
              comodatoTotal: _contratoComodato?.cantidadContratada,
            ),
            if (_evidenciaExistente && _foto == null) ...[
              const SizedBox(height: 12),
              const Row(
                children: [
                  Icon(Icons.check_circle, size: 16, color: AppColors.badgeGreen),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Ya hay una foto de evidencia cargada para esta visita.',
                      style: TextStyle(fontSize: 12, color: AppColors.graphiteGray),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 18),
            _buildVentaSection(),
            _buildVentaSocialSection(),
            if (_mostrarComodato) ...[
              const SizedBox(height: 18),
              ControlComodatoCard(
                contrato: _contratoComodato,
                controlRegistrado: _controlComodato,
                pendienteSync: _comodatoPendienteSync && !_online,
                cargando: _cargandoContrato,
                onAuditar: _finalizando ? null : _abrirAuditoriaComodato,
              ),
            ],
            const SizedBox(height: 18),
            CanjeGarrafaCard(
              canjes: _canjes,
              pendienteSync: _canjePendienteSync && !_online,
              onCanjear: _finalizando ? null : _abrirCanje,
            ),
            const SizedBox(height: 18),
            EvidenciaCapturaCard(
              titulo: _evidenciaExistente
                  ? 'Evidencia cargada.\nTocá para reemplazarla'
                  : 'Captura Evidencia\nde Fachada',
              foto: _foto,
              cargando: _capturandoFoto,
              onCapturar: _capturarFoto,
            ),
            const SizedBox(height: 20),
            if (_visita.estadoVisita == VisitaEstado.pausadaSocial) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.steelBlue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.steelBlue.withOpacity(0.3)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.pause_circle_outline, size: 18, color: AppColors.steelBlue),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Hay una Venta Social en curso. Finalizala arriba para poder cerrar la visita.',
                        style: TextStyle(fontSize: 12.5, color: AppColors.graphiteGray),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (_hayFaltante) ...[
              _MotivoFaltanteCampo(
                controller: _motivoFaltanteCtrl,
                habilitado: !_finalizando,
              ),
              const SizedBox(height: 14),
            ],
            PrimaryButton(
              text: 'Finalizar Visita',
              isLoading: _finalizando,
              onPressed: ((_foto != null || _evidenciaExistente) &&
                      !_finalizando &&
                      _visita.estadoVisita != VisitaEstado.pausadaSocial &&
                      _faltanteResuelto)
                  ? _finalizarVisita
                  : null,
            ),
            if (_foto != null) ...[
              const SizedBox(height: 10),
              Center(
                child: TextButton(
                  onPressed: _finalizando ? null : _capturarFoto,
                  child: const Text(
                    'REHACER FOTO',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.graphiteGray,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                onPressed: (_finalizando || _cancelando) ? null : _cancelarVisita,
                icon: _cancelando
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.error,
                        ),
                      )
                    : const Icon(Icons.cancel_outlined, size: 18, color: AppColors.error),
                label: const Text(
                  'Cancelar visita',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.error,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ),
          ],
        );
    }
  }
}

String? detalleGarrafasDeVenta(VentaEnVisita venta) {
  final lineas = venta.draft?.lineas;
  if (lineas == null || lineas.isEmpty) return null;
  final partes = <String>[];
  for (final l in lineas) {
    if (l.cantidadEntregada <= 0) continue;
    final kg = l.producto.kg;
    final etiqueta = kg > 0
        ? '$kg kg'
        : (l.producto.descripcion.trim().isNotEmpty
            ? l.producto.descripcion.trim()
            : l.producto.sku);
    partes.add('${l.cantidadEntregada}× $etiqueta');
  }
  return partes.isEmpty ? null : partes.join(' · ');
}

class _FilaVentaRegistrada extends StatelessWidget {
  final VentaEnVisita venta;
  final bool online;
  final VoidCallback? onCobrar;

  const _FilaVentaRegistrada({
    required this.venta,
    required this.online,
    this.onCobrar,
  });

  @override
  Widget build(BuildContext context) {
    final Color borde =
        venta.cobrado ? AppColors.badgeGreen : AppColors.inputBorder;
    final detalleGarrafas = _detalleGarrafas();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borde.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                venta.esSocial ? Icons.volunteer_activism_outlined : Icons.point_of_sale_outlined,
                size: 17,
                color: venta.esSocial ? AppColors.steelBlue : AppColors.orange,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  venta.etiqueta,
                  style: AppTextStyles.label.copyWith(fontSize: 13.5),
                ),
              ),
              Text(
                formatMoneda(venta.monto),
                style: AppTextStyles.title.copyWith(fontSize: 15),
              ),
            ],
          ),
          if (detalleGarrafas != null) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.propane_tank_outlined, size: 14, color: AppColors.inputHint),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    detalleGarrafas,
                    style: AppTextStyles.footer.copyWith(
                      fontSize: 12,
                      color: AppColors.graphiteGray,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _estado()),
              if (onCobrar != null)
                TextButton(
                  onPressed: onCobrar,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.orange,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Cobrar',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String? _detalleGarrafas() => detalleGarrafasDeVenta(venta);

  Widget _estado() {
    if (venta.cobrado) {
      return Row(
        children: const [
          Icon(Icons.check_circle, size: 15, color: AppColors.badgeGreen),
          SizedBox(width: 6),
          Text(
            'Cobrada',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.badgeGreen),
          ),
        ],
      );
    }
    if (venta.pendienteSync && !online) {
      return Row(
        children: const [
          Icon(Icons.sync, size: 15, color: AppColors.badgeAmber),
          SizedBox(width: 6),
          Expanded(
            child: Text(
              'Pendiente de sincronizar. Se envía cuando haya señal.',
              style: TextStyle(fontSize: 12, color: AppColors.graphiteGray),
            ),
          ),
        ],
      );
    }
    final detalle = venta.esSocial
        ? 'Liquidación social'
        : (venta.cantidadLineas == 1 ? '1 producto' : '${venta.cantidadLineas} productos');
    return Text(
      '$detalle · Cobro pendiente',
      style: const TextStyle(fontSize: 12, color: AppColors.graphiteGray),
    );
  }
}

class _MotivoFaltanteCampo extends StatelessWidget {
  final TextEditingController controller;
  final bool habilitado;

  const _MotivoFaltanteCampo({required this.controller, required this.habilitado});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.badgeAmber.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.badgeAmber.withOpacity(0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.warning_amber_rounded, size: 20, color: AppColors.badgeAmber),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Hay un faltante de garrafas en esta visita. Podés cerrarla igual, '
                  'pero registrá el motivo para que el administrador lo revise.',
                  style: TextStyle(fontSize: 13, color: AppColors.graphiteGray),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Motivo del faltante',
            style: AppTextStyles.label.copyWith(fontSize: 13),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            enabled: habilitado,
            maxLines: 2,
            style: AppTextStyles.input,
            decoration: InputDecoration(
              hintText: 'Ej: el cliente no devolvió los vacíos, garrafa dañada, etc.',
              hintStyle: AppTextStyles.hint,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              filled: true,
              fillColor: AppColors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.inputBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.inputBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.orange),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvisoVentaPausada extends StatelessWidget {
  const _AvisoVentaPausada();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.steelBlue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.steelBlue.withOpacity(0.30)),
      ),
      child: Row(
        children: [
          const Icon(Icons.pause_circle_outline, size: 17, color: AppColors.steelBlue),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Venta Social en proceso. Finalizala para registrar otras ventas.',
              style: AppTextStyles.footer.copyWith(color: AppColors.graphiteGray),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final int orden;

  const _TopBar({required this.orden});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 16, 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.steelBlue),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: Text(
              'Parada N° $orden',
              style: AppTextStyles.title.copyWith(fontSize: 18),
            ),
          ),
          const EstadoConexionBadge(compacto: true),
        ],
      ),
    );
  }
}

class _EstadoUbicacion extends StatelessWidget {
  final String nombreCliente;
  final String direccionCliente;

  const _EstadoUbicacion({required this.nombreCliente, required this.direccionCliente});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          const SizedBox(
            height: 40,
            width: 40,
            child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.orange),
          ),
          const SizedBox(height: 20),
          Text(nombreCliente, style: AppTextStyles.title.copyWith(fontSize: 18)),
          const SizedBox(height: 6),
          Text(direccionCliente, style: AppTextStyles.link, textAlign: TextAlign.center),
          const SizedBox(height: 18),
          const Text(
            'Verificando tu ubicación para el check-in…',
            style: AppTextStyles.link,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ErrorUbicacion extends StatelessWidget {
  final String mensaje;
  final IconData icono;
  final VoidCallback onReintentar;
  final VoidCallback onCancelar;

  const _ErrorUbicacion({
    required this.mensaje,
    required this.onReintentar,
    required this.onCancelar,
    this.icono = Icons.location_off_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 50),
      child: Column(
        children: [
          Icon(icono, size: 44, color: AppColors.error),
          const SizedBox(height: 16),
          Text(mensaje, style: AppTextStyles.input, textAlign: TextAlign.center),
          const SizedBox(height: 22),
          PrimaryButton(text: 'Reintentar', onPressed: onReintentar),
          const SizedBox(height: 10),
          TextButton(
            onPressed: onCancelar,
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppColors.graphiteGray, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}