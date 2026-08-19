import 'dart:async' show unawaited;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../local/offline_evento.dart';
import '../../local/offline_queue_service.dart';
import '../../models/cliente_ficha.dart';
import '../../models/evidencia_tipo.dart';
import '../../models/visita_estado.dart';
import '../../models/visita_model.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/evidencia_repository.dart';
import '../../repositories/network_exception.dart';
import '../../repositories/visita_repository.dart';
import '../../services/location_service.dart';
import '../../services/photo_capture_service.dart';
import '../../services/sync_manager.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/chofer/evidencia_captura_card.dart';
import '../../widgets/chofer/visita_checkin_card.dart';
import '../../widgets/primary_button.dart';

const _uuid = Uuid();

enum _FaseVisita { verificandoUbicacion, errorUbicacion, enCurso }

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
  final _photoService = PhotoCaptureService();
  final _locationService = LocationService.instance;

  late VisitaModel _visita;
  _FaseVisita _fase = _FaseVisita.verificandoUbicacion;
  String? _errorMensaje;
  File? _foto;
  bool _capturandoFoto = false;
  bool _finalizando = false;
  bool _cancelando = false;
  bool _evidenciaExistente = false;
  bool _checkInPendienteSync = false;
  VoidCallback? _colaListener;

  @override
  void initState() {
    super.initState();
    _visita = widget.visita;
    final apiClient = context.read<AuthProvider>().apiClient;
    _visitaRepo = VisitaRepository(apiClient);
    _evidenciaRepo = EvidenciaRepository(apiClient);

    _colaListener = _actualizarPendienteSync;
    OfflineQueueService.instance.escuchar().addListener(_colaListener!);

    if (_visita.estadoVisita == VisitaEstado.enCurso) {
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
    _locationService.detenerSeguimientoEnSegundoPlano();
    super.dispose();
  }

  void _actualizarPendienteSync() {
    final idAgendaItem = _visita.idAgendaItem;
    if (idAgendaItem == null) return;
    final sigoPendiente = OfflineQueueService.instance
        .pendientesDeAgendaItem(idAgendaItem)
        .any((e) => e.tipoEvento == OfflineEventoTipo.checkIn);
    if (mounted && sigoPendiente != _checkInPendienteSync) {
      setState(() => _checkInPendienteSync = sigoPendiente);
    }
  }

  Future<void> _iniciarCheckIn() async {
    final idAgendaItem = _visita.idAgendaItem;
    final idVisitaExistente = _visita.idVisita;
    if (idAgendaItem == null && idVisitaExistente == null) {
      setState(() {
        _fase = _FaseVisita.errorUbicacion;
        _errorMensaje = 'La visita no tiene un identificador válido.';
      });
      return;
    }

    setState(() {
      _fase = _FaseVisita.verificandoUbicacion;
      _errorMensaje = null;
    });

    LocationCheckIn? checkIn;
    try {
      checkIn = await _locationService.obtenerUbicacionActual();

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

      // Arranca el seguimiento en segundo plano (no bloquea la UI).
      unawaited(
        _locationService.iniciarSeguimientoEnSegundoPlano(onPosition: (_) {}),
      );
    } on LocationServiceException catch (e) {
      if (!mounted) return;
      setState(() {
        _fase = _FaseVisita.errorUbicacion;
        _errorMensaje = e.message;
      });
    } on NetworkException {
      // Tenemos la posición del GPS (no depende de la red) pero no hay
      // señal para avisarle al backend: guardamos el check-in localmente
      // y seguimos como si hubiera funcionado, para no frenar al chofer.
      final idAgendaItemFallback = _visita.idAgendaItem;
      if (idAgendaItemFallback == null) {
        if (!mounted) return;
        setState(() {
          _fase = _FaseVisita.errorUbicacion;
          _errorMensaje =
              'No hay conexión y la visita no tiene un ítem de agenda asociado para guardarla localmente.';
        });
        return;
      }
      await _iniciarViaColaSincronizacion(
        idAgendaItem: idAgendaItemFallback,
        idVisita: idVisitaExistente,
        checkIn: checkIn,
        porFallaDeRed: true,
      );
    } on VisitaRepositoryException catch (e) {
      if (!mounted) return;
      setState(() {
        _fase = _FaseVisita.errorUbicacion;
        _errorMensaje = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _fase = _FaseVisita.errorUbicacion;
        _errorMensaje = 'No se pudo iniciar la visita. Intentá de nuevo.';
      });
    }
  }

  Future<void> _iniciarViaColaSincronizacion({
    required int idAgendaItem,
    int? idVisita,
    required LocationCheckIn? checkIn,
    bool porFallaDeRed = false,
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
    unawaited(
      _locationService.iniciarSeguimientoEnSegundoPlano(onPosition: (_) {}),
    );
    unawaited(SyncManager.instance.sincronizar());

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

    unawaited(
      _locationService.iniciarSeguimientoEnSegundoPlano(onPosition: (_) {}),
    );

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

  Future<void> _finalizarVisita() async {
    final foto = _foto;
    final idVisita = _visita.idVisita;
    final idAgendaItem = _visita.idAgendaItem;
    if ((foto == null && !_evidenciaExistente) || _finalizando) {
      return;
    }
    if (idVisita == null && idAgendaItem == null) {
      _mostrarError('La visita no tiene un identificador válido.');
      return;
    }

    setState(() => _finalizando = true);

    if (idVisita == null) {
      await _finalizarOffline(idAgendaItem: idAgendaItem!, idVisita: null, foto: foto);
      return;
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
      );
      await _locationService.detenerSeguimientoEnSegundoPlano();

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
      await _locationService.detenerSeguimientoEnSegundoPlano();
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
  }) async {
    final ahora = DateTime.now();

    if (foto != null) {
      final bytes = await foto.readAsBytes();
      await OfflineQueueService.instance.encolar(
        OfflineEvento(
          uuidOffline: _uuid.v4(),
          tipoEvento: OfflineEventoTipo.evidencia,
          idAgendaItem: idAgendaItem,
          idVisita: idVisita,
          timestampOrigen: ahora,
          creadoEn: ahora,
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
        timestampOrigen: ahora,
        creadoEn: ahora,
        timestampFin: ahora,
      ),
    );

    await _locationService.detenerSeguimientoEnSegundoPlano();
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
    return Scaffold(
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
    );
  }

  Widget _buildContenido() {
    switch (_fase) {
      case _FaseVisita.verificandoUbicacion:
        return _EstadoUbicacion(
          nombreCliente: widget.nombreCliente,
          direccionCliente: widget.direccionCliente,
        );
      case _FaseVisita.errorUbicacion:
        return _ErrorUbicacion(
          mensaje: _errorMensaje ?? 'No se pudo verificar tu ubicación.',
          onReintentar: _iniciarCheckIn,
          onCancelar: () => Navigator.of(context).pop(),
        );
      case _FaseVisita.enCurso:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_checkInPendienteSync) ...[
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
            EvidenciaCapturaCard(
              titulo: _evidenciaExistente
                  ? 'Evidencia cargada.\nTocá para reemplazarla'
                  : 'Captura Evidencia\nde Fachada',
              foto: _foto,
              cargando: _capturandoFoto,
              onCapturar: _capturarFoto,
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              text: 'Finalizar Visita',
              isLoading: _finalizando,
              onPressed: ((_foto != null || _evidenciaExistente) && !_finalizando)
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
  final VoidCallback onReintentar;
  final VoidCallback onCancelar;

  const _ErrorUbicacion({
    required this.mensaje,
    required this.onReintentar,
    required this.onCancelar,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 50),
      child: Column(
        children: [
          const Icon(Icons.location_off_outlined, size: 44, color: AppColors.error),
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