import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../../local/recaudacion_diaria_service.dart';
import '../../../local/rendicion_local_service.dart';
import '../../../models/rendicion_ruta.dart';
import '../../../models/stock_rodante_chofer.dart';
import '../../../providers/auth_provider.dart';
import '../../../repositories/network_exception.dart';
import '../../../repositories/rendicion_repository.dart';
import '../../../repositories/stock_rodante_repository.dart';
import '../../../repositories/visita_repository.dart';
import '../../../services/connectivity_service.dart';
import '../../../services/rendicion_sync_manager.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../utils/formato.dart';
import '../../../widgets/chofer/comodato/contador_envases.dart';
import '../../../widgets/common/estado_conexion_badge.dart';
import '../../../widgets/common/carga/zona_carga.dart';
import '../../../widgets/primary_button.dart';
import '../../../core/feedback/app_feedback.dart';

class _Conteo {
  int vacios;
  int llenos;
  int averiados;
  _Conteo({this.vacios = 0, this.llenos = 0, this.averiados = 0});
}

class _ResumenProducto {
  final String etiqueta;
  final int vacios;
  final int llenos;
  final int averiados;
  const _ResumenProducto({
    required this.etiqueta,
    this.vacios = 0,
    this.llenos = 0,
    this.averiados = 0,
  });
}

const List<StockRodanteProducto> _productosPorDefecto = [
  StockRodanteProducto(idProducto: 'GARRAFA-10', sku: 'GARRAFA-10'),
  StockRodanteProducto(idProducto: 'GARRAFA-15', sku: 'GARRAFA-15'),
  StockRodanteProducto(idProducto: 'GARRAFA-45', sku: 'GARRAFA-45'),
];

class RendicionRutaScreen extends StatefulWidget {
  final bool visible;

  const RendicionRutaScreen({super.key, this.visible = true});

  @override
  State<RendicionRutaScreen> createState() => _RendicionRutaScreenState();
}

class _RendicionRutaScreenState extends State<RendicionRutaScreen> {
  static const _uuid = Uuid();
  static const Duration _vigencia = Duration(seconds: 20);

  final _efectivo = TextEditingController();
  final _cheques = TextEditingController();
  final _transferencias = TextEditingController();
  final _observaciones = TextEditingController();

  List<StockRodanteProducto> _productos = const [];
  final Map<String, _Conteo> _conteos = {};
  Set<String> _clavesNota = <String>{};
  bool _rendicionEnviada = false;

  bool _cargando = true;
  bool _enviando = false;
  bool _pendienteLocal = false;
  bool _precargado = false;
  bool _editado = false;
  DateTime? _cargadoEn;
  bool _online = true;
  RendicionRegistrada? _registrada;

  bool get _bloqueada => _rendicionEnviada || _pendienteLocal;

  DateTime get _hoy => DateTime.now();

  @override
  void initState() {
    super.initState();
    _cargar();
    ConnectivityService.instance.tieneConexion().then((online) {
      if (mounted) setState(() => _online = online);
    });
  }

  @override
  void didUpdateWidget(covariant RendicionRutaScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.visible || oldWidget.visible || _cargando || _enviando) return;
    final ultimo = _cargadoEn;
    final vencido = ultimo == null || DateTime.now().difference(ultimo) > _vigencia;
    if (!vencido) return;
    if (_bloqueada || !_editado) _cargar();
  }

  void _marcarEditado() {
    setState(() => _editado = true);
  }

  Future<void> _recalcular() async {
    if (_editado) {
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('¿Volver a precargar?', style: AppTextStyles.title.copyWith(fontSize: 18)),
          content: Text(
            'Se reemplazan los valores y garrafas que cargaste a mano por los registrados hoy.',
            style: AppTextStyles.link.copyWith(fontSize: 13.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar', style: TextStyle(color: AppColors.graphiteGray)),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text(
                'Precargar',
                style: TextStyle(color: AppColors.orange, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      );
      if (confirmar != true || !mounted) return;
    }
    await _cargar();
  }

  @override
  void dispose() {
    _efectivo.dispose();
    _cheques.dispose();
    _transferencias.dispose();
    _observaciones.dispose();
    super.dispose();
  }

  String _clave(StockRodanteProducto p) =>
      p.idProducto.isNotEmpty ? p.idProducto : p.sku;

  List<StockRodanteProducto> _completarCatalogo(
      List<StockRodanteProducto> base) {
    final completos = [...base];
    final kgsPresentes = completos.map((p) => p.kg).whereType<int>().toSet();
    for (final def in _productosPorDefecto) {
      if (def.kg != null && !kgsPresentes.contains(def.kg)) {
        completos.add(def);
      }
    }
    completos.sort((a, b) => (a.kg ?? 0).compareTo(b.kg ?? 0));
    return completos;
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    final auth = context.read<AuthProvider>();
    List<StockRodanteProducto> productos = const [];
    var jornadaCerrada = false;
    try {
      final stock = await StockRodanteRepository(auth.apiClient).getMiStock(
        idUsuario: auth.user?.id ?? '',
        fecha: _hoy,
      );
      productos = stock?.ordenados ?? const [];
      jornadaCerrada = stock?.jornadaCerrada ?? false;
    } catch (_) {
      productos = const [];
    }
    final clavesNota = productos.map(_clave).toSet();
    if (productos.isEmpty) {
      productos = _completarCatalogo(productos);
    }

    final pendiente = RendicionLocalService.instance.obtener(_hoy);
    final enviadaLocal = RendicionLocalService.instance.obtenerEnviada(_hoy);
    final idUsuario = auth.user?.id ?? '';

    RendicionRegistrada? registrada;
    try {
      registrada = await RendicionRepository(auth.apiClient).obtenerMia(_hoy);
    } catch (_) {
      registrada = null;
    }

    final local = RecaudacionDiariaService.instance.obtener(idUsuario, _hoy);
    var efectivoServidor = 0;
    var chequeServidor = 0;
    var transferenciaServidor = 0;
    try {
      final items = await VisitaRepository(auth.apiClient)
          .getVisitasPorUsuarioYFecha(idUsuario: idUsuario, fecha: _hoy);
      for (final item in items) {
        efectivoServidor += item.cobrosPorMetodo['EFECTIVO'] ?? 0;
        chequeServidor += item.cobrosPorMetodo['CHEQUE'] ?? 0;
        transferenciaServidor += item.cobrosPorMetodo['TRANSFERENCIA'] ?? 0;
      }
    } catch (_) {}
    final efectivoPrecarga = efectivoServidor > local.efectivo ? efectivoServidor : local.efectivo;
    final chequePrecarga = chequeServidor > local.cheque ? chequeServidor : local.cheque;
    final transferenciaPrecarga =
        transferenciaServidor > local.transferencia ? transferenciaServidor : local.transferencia;

    if (!mounted) return;
    setState(() {
      _productos = productos;
      _clavesNota = clavesNota;
      _registrada = registrada;
      _rendicionEnviada = jornadaCerrada || registrada != null || enviadaLocal != null;
      _pendienteLocal = false;
      _precargado = false;
      _editado = false;
      _cargadoEn = DateTime.now();
      _conteos.clear();
      for (final p in productos) {
        _conteos[_clave(p)] = _Conteo();
      }
      final copiaEnviada = enviadaLocal ?? (registrada == null ? null : pendiente);
      if (_rendicionEnviada && copiaEnviada != null) {
        _cargarDesdeDraft(copiaEnviada);
      } else if (_rendicionEnviada) {
        final r = registrada;
        _efectivo.text = r == null || r.efectivo == 0 ? '' : '${r.efectivo}';
        _cheques.text = r == null || r.cheques == 0 ? '' : '${r.cheques}';
        _transferencias.text = r == null || r.transferencias == 0 ? '' : '${r.transferencias}';
        _observaciones.text = r?.observaciones ?? '';
        for (final p in productos) {
          _conteos[_clave(p)] = _Conteo(
            vacios: p.vaciosEntrada,
            llenos: p.llenosEntrada,
            averiados: p.averiadosActuales,
          );
        }
      } else if (pendiente != null) {
        _efectivo.text = pendiente.efectivo > 0 ? '${pendiente.efectivo}' : '';
        _cheques.text = pendiente.cheques > 0 ? '${pendiente.cheques}' : '';
        _transferencias.text =
            pendiente.transferencias > 0 ? '${pendiente.transferencias}' : '';
        _cargarDesdeDraft(pendiente);
        _pendienteLocal = true;
      } else {
        if (efectivoPrecarga > 0) _efectivo.text = '$efectivoPrecarga';
        if (chequePrecarga > 0) _cheques.text = '$chequePrecarga';
        if (transferenciaPrecarga > 0) {
          _transferencias.text = '$transferenciaPrecarga';
        }
        var precargoGarrafas = false;
        for (final p in productos) {
          final vacios = p.vaciosEnCamion > 0 ? p.vaciosEnCamion : p.vaciosEntrada;
          final llenos = p.llenosEntrada > 0 ? p.llenosEntrada : p.disponiblesParaVenta;
          final averiados = p.averiadosActuales;
          if (vacios > 0 || llenos > 0 || averiados > 0) {
            _conteos[_clave(p)] = _Conteo(
              vacios: vacios,
              llenos: llenos,
              averiados: averiados,
            );
            precargoGarrafas = true;
          }
        }
        final totalValoresPrecarga =
            efectivoPrecarga + chequePrecarga + transferenciaPrecarga;
        _precargado = totalValoresPrecarga > 0 || precargoGarrafas;
      }
      _cargando = false;
    });
  }

  void _cargarDesdeDraft(RendicionDraft draft) {
    _efectivo.text = draft.efectivo > 0 ? '${draft.efectivo}' : '';
    _cheques.text = draft.cheques > 0 ? '${draft.cheques}' : '';
    _transferencias.text = draft.transferencias > 0 ? '${draft.transferencias}' : '';
    _observaciones.text = draft.observaciones;
    for (final e in draft.envases) {
      _conteos[e.idProducto.isNotEmpty ? e.idProducto : e.sku] = _Conteo(
        vacios: e.vaciosRecuperados,
        llenos: e.llenosNoVendidos,
        averiados: e.averiados,
      );
    }
  }

  int _leer(TextEditingController c) => int.tryParse(c.text.trim()) ?? 0;

  int get _totalValores =>
      _leer(_efectivo) + _leer(_cheques) + _leer(_transferencias);

  int get _totalVacios =>
      _conteos.values.fold(0, (a, c) => a + c.vacios);
  int get _totalLlenos =>
      _conteos.values.fold(0, (a, c) => a + c.llenos);
  int get _totalAveriados =>
      _conteos.values.fold(0, (a, c) => a + c.averiados);
  int get _totalGarrafas => _totalVacios + _totalLlenos + _totalAveriados;

  bool get _valido => (_totalValores > 0 || _totalGarrafas > 0) && !_enviando && !_bloqueada;

  RendicionDraft _armarDraft() {
    final envases = <RendicionEnvaseItem>[];
    for (final p in _productos) {
      final c = _conteos[_clave(p)] ?? _Conteo();
      final esDeLaNota = _clavesNota.contains(_clave(p));
      if (esDeLaNota || c.vacios > 0 || c.llenos > 0 || c.averiados > 0) {
        envases.add(RendicionEnvaseItem(
          idProducto: p.idProducto,
          sku: p.sku,
          etiqueta: p.etiqueta,
          vaciosRecuperados: c.vacios,
          llenosNoVendidos: c.llenos,
          averiados: c.averiados,
        ));
      }
    }
    return RendicionDraft(
      uuidOffline: _uuid.v4(),
      fecha: _hoy,
      timestamp: DateTime.now(),
      efectivo: _leer(_efectivo),
      cheques: _leer(_cheques),
      transferencias: _leer(_transferencias),
      observaciones: _observaciones.text.trim(),
      envases: envases,
    );
  }

  Future<void> _enviar() async {
    if (!_valido) return;
    final apiClient = context.read<AuthProvider>().apiClient;
    setState(() => _enviando = true);
    final draft = _armarDraft();
    await RendicionLocalService.instance.guardar(draft);

    try {
      await RendicionRepository(apiClient).enviar(draft);
      await RendicionLocalService.instance.marcarEnviada(draft);
      if (!mounted) return;
      setState(() {
        _enviando = false;
        _pendienteLocal = false;
        _rendicionEnviada = true;
      });
      _mostrar('Rendición enviada. Queda pendiente de conciliación del administrador.');
    } on NetworkException {
      unawaited(RendicionSyncManager.instance.sincronizar());
      if (!mounted) return;
      setState(() {
        _enviando = false;
        _pendienteLocal = true;
      });
      _mostrar('Sin conexión: la rendición se guardó y se enviará cuando haya señal.');
    } on RendicionRepositoryException catch (e) {
      if (e.yaRegistrada) {
        await RendicionLocalService.instance.eliminar(draft.fecha);
        if (!mounted) return;
        setState(() => _enviando = false);
        _mostrar('Ya habías enviado la rendición de hoy. Te mostramos los datos registrados.', error: true);
        await _cargar();
        return;
      }
      if (!e.endpointNoDisponible) {
        await RendicionLocalService.instance.eliminar(draft.fecha);
      }
      if (!mounted) return;
      setState(() {
        _enviando = false;
        _pendienteLocal = e.endpointNoDisponible;
      });
      _mostrar(
        e.endpointNoDisponible
            ? 'Guardada en el dispositivo: el backend de rendición todavía no está disponible.'
            : e.message,
        error: !e.endpointNoDisponible,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _enviando = false;
        _pendienteLocal = true;
      });
      _mostrar('No se pudo enviar la rendición. Quedó guardada para reintentar.', error: true);
    }
  }

  void _mostrar(String mensaje, {bool error = false}) {
    if (error) {
      AppFeedback.error(mensaje);
    } else {
      AppFeedback.exito(mensaje);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Cabecera(),
          Expanded(
            child: ZonaCarga(
              child: ReportarCarga(
                cargando: _cargando,
                child: _cargando
                    ? const SizedBox.shrink()
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        children: [
                          if (_rendicionEnviada) ...[
                            _RendicionEnviadaAviso(conciliada: _registrada?.conciliada ?? false),
                            const SizedBox(height: 12),
                          ],
                          if (!_rendicionEnviada && _pendienteLocal)
                            const _AvisoPendiente(),
                          if (!_rendicionEnviada && !_pendienteLocal)
                            _AvisoPrecargado(
                              precargado: _precargado,
                              editado: _editado,
                              onRecalcular: _recalcular,
                            ),
                          _SeccionValores(
                            efectivo: _efectivo,
                            cheques: _cheques,
                            transferencias: _transferencias,
                            habilitado: !_enviando && !_bloqueada,
                            resumen: _totalValores > 0
                                ? formatMoneda(_totalValores)
                                : 'Sin valores cargados',
                            onChanged: _marcarEditado,
                          ),
                          const SizedBox(height: 16),
                          _SeccionEnvases(
                            productos: _productos,
                            conteos: _conteos,
                            habilitado: !_enviando && !_bloqueada,
                            resumen: _totalGarrafas > 0
                                ? '$_totalGarrafas garrafas'
                                : 'Sin garrafas cargadas',
                            onChanged: _marcarEditado,
                            claveDe: _clave,
                          ),
                          const SizedBox(height: 16),
                          _SeccionObservaciones(
                            controller: _observaciones,
                            habilitado: !_enviando && !_bloqueada,
                            resumen: _observaciones.text.trim().isEmpty
                                ? 'Sin observaciones'
                                : 'Con observaciones',
                          ),
                          const SizedBox(height: 16),
                          _Resumen(
                            efectivo: _leer(_efectivo),
                            cheques: _leer(_cheques),
                            transferencias: _leer(_transferencias),
                            productos: [
                              for (final p in _productos)
                                _ResumenProducto(
                                  etiqueta: p.etiqueta,
                                  vacios: _conteos[_clave(p)]?.vacios ?? 0,
                                  llenos: _conteos[_clave(p)]?.llenos ?? 0,
                                  averiados: _conteos[_clave(p)]?.averiados ?? 0,
                                ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          if (_rendicionEnviada)
                            const _DatosBloqueadosNota()
                          else if (_pendienteLocal)
                            const _DatosBloqueadosNota(pendiente: true)
                          else
                            PrimaryButton(
                              text: 'Enviar Rendición',
                              isLoading: _enviando,
                              onPressed: _valido ? _enviar : null,
                            ),
                          const SizedBox(height: 8),
                          if (!_online)
                            Text(
                              'Estás sin conexión: la rendición se guarda y se envía sola cuando vuelva la señal.',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.footer.copyWith(color: AppColors.graphiteGray),
                            ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Cabecera extends StatelessWidget {
  const _Cabecera();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 18),
      decoration: const BoxDecoration(
        color: AppColors.steelBlue,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rendición de Ruta',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.white),
                ),
                SizedBox(height: 2),
                Text(
                  'Declará los valores entregados y las garrafas recuperadas al cerrar la jornada.',
                  style: TextStyle(fontSize: 12.5, color: AppColors.white),
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

class _AvisoPrecargado extends StatelessWidget {
  final bool precargado;
  final bool editado;
  final VoidCallback onRecalcular;

  const _AvisoPrecargado({
    required this.precargado,
    required this.editado,
    required this.onRecalcular,
  });

  @override
  Widget build(BuildContext context) {
    final texto = !precargado
        ? 'Todavía no hay cobros ni garrafas registrados hoy para precargar. '
            'Si ya cobraste, tocá "Precargar" para traer lo último.'
        : editado
            ? 'Modificaste los valores precargados. Revisá que coincidan con lo que entregás.'
            : 'Precargamos los valores cobrados y las garrafas del camión de hoy. '
                'Revisá los números y ajustá lo que haga falta antes de enviar.';
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.steelBlue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.steelBlue.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome_outlined, size: 18, color: AppColors.steelBlue),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texto,
              style: AppTextStyles.footer.copyWith(color: AppColors.graphiteGray),
            ),
          ),
          const SizedBox(width: 6),
          TextButton.icon(
            onPressed: onRecalcular,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Precargar'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.orange,
              textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }
}

class _RendicionEnviadaAviso extends StatelessWidget {
  final bool conciliada;

  const _RendicionEnviadaAviso({this.conciliada = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.badgeGreen.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.badgeGreen.withOpacity(0.45)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, size: 26, color: AppColors.badgeGreen),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ya enviaste la rendición de hoy',
                  style: AppTextStyles.label.copyWith(
                    fontSize: 15,
                    color: AppColors.badgeGreen,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  conciliada
                      ? 'El administrador ya aprobó tu rendición. Estos son los datos que enviaste.'
                      : 'Estos son los datos que enviaste. Quedan bloqueados hasta que el administrador la revise.',
                  style: AppTextStyles.footer.copyWith(color: AppColors.graphiteGray),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AvisoPendiente extends StatelessWidget {
  const _AvisoPendiente();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.badgeAmber.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.badgeAmber.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.sync, size: 18, color: AppColors.badgeAmber),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Tenés una rendición guardada sin enviar. Revisá los datos y reenviala.',
              style: AppTextStyles.footer.copyWith(color: AppColors.graphiteGray),
            ),
          ),
        ],
      ),
    );
  }
}

class _SeccionValores extends StatelessWidget {
  final TextEditingController efectivo;
  final TextEditingController cheques;
  final TextEditingController transferencias;
  final String resumen;
  final VoidCallback onChanged;
  final bool habilitado;

  const _SeccionValores({
    required this.efectivo,
    required this.cheques,
    required this.transferencias,
    required this.resumen,
    required this.onChanged,
    this.habilitado = true,
  });

  @override
  Widget build(BuildContext context) {
    return _SeccionPlegable(
      icono: Icons.payments_outlined,
      titulo: 'Rendición de Valores',
      subtitulo: 'Declará el efectivo físico entregado, los sobres de cheques y los comprobantes de transferencias.',
      resumen: resumen,
      child: Column(
        children: [
          _CampoMoneda(label: 'Efectivo entregado', controller: efectivo, onChanged: onChanged, habilitado: habilitado),
          const SizedBox(height: 12),
          _CampoMoneda(label: 'Sobres de cheques', controller: cheques, onChanged: onChanged, habilitado: habilitado),
          const SizedBox(height: 12),
          _CampoMoneda(
            label: 'Comprobantes de transferencias',
            controller: transferencias,
            onChanged: onChanged,
            habilitado: habilitado,
          ),
        ],
      ),
    );
  }
}

class _SeccionEnvases extends StatelessWidget {
  final List<StockRodanteProducto> productos;
  final Map<String, _Conteo> conteos;
  final bool habilitado;
  final String resumen;
  final VoidCallback onChanged;
  final String Function(StockRodanteProducto) claveDe;

  const _SeccionEnvases({
    required this.productos,
    required this.conteos,
    required this.habilitado,
    required this.resumen,
    required this.onChanged,
    required this.claveDe,
  });

  @override
  Widget build(BuildContext context) {
    return _SeccionPlegable(
      icono: Icons.propane_tank_outlined,
      titulo: 'Recuperar Garrafas / Rendición de Envases',
      subtitulo: 'Contá las vacías recuperadas, las llenas no vendidas que vuelven al camión y las dañadas o canjeadas.',
      resumen: resumen,
      child: Column(
        children: [
          for (final p in productos) ...[
            _ProductoPlegable(
              producto: p,
              conteo: conteos[claveDe(p)] ?? _Conteo(),
              habilitado: habilitado,
              onChanged: onChanged,
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _ProductoPlegable extends StatefulWidget {
  final StockRodanteProducto producto;
  final _Conteo conteo;
  final bool habilitado;
  final VoidCallback onChanged;

  const _ProductoPlegable({
    required this.producto,
    required this.conteo,
    required this.habilitado,
    required this.onChanged,
  });

  @override
  State<_ProductoPlegable> createState() => _ProductoPlegableState();
}

class _ProductoPlegableState extends State<_ProductoPlegable> {
  bool _abierta = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.conteo;
    final total = c.vacios + c.llenos + c.averiados;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: total > 0 ? AppColors.orange.withOpacity(0.4) : AppColors.inputBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => _abierta = !_abierta),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.propane_tank_rounded, size: 18, color: AppColors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Garrafa ${widget.producto.etiqueta}',
                          style: AppTextStyles.label.copyWith(fontSize: 14),
                        ),
                        if (!_abierta) ...[
                          const SizedBox(height: 2),
                          Text(
                            total > 0
                                ? 'Vacías ${c.vacios} · Llenas ${c.llenos} · Dañadas ${c.averiados}'
                                : 'Sin conteo',
                            style: AppTextStyles.footer.copyWith(color: AppColors.graphiteGray),
                          ),
                        ],
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _abierta ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: const Icon(Icons.keyboard_arrow_down, color: AppColors.graphiteGray),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 180),
            crossFadeState: _abierta ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            firstChild: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                children: [
                  _LineaConteo(
                    etiqueta: 'Vacías recuperadas',
                    valor: c.vacios,
                    habilitado: widget.habilitado,
                    onChanged: (v) {
                      c.vacios = v;
                      widget.onChanged();
                    },
                  ),
                  const SizedBox(height: 8),
                  _LineaConteo(
                    etiqueta: 'Llenas no vendidas',
                    valor: c.llenos,
                    habilitado: widget.habilitado,
                    onChanged: (v) {
                      c.llenos = v;
                      widget.onChanged();
                    },
                  ),
                  const SizedBox(height: 8),
                  _LineaConteo(
                    etiqueta: 'Dañadas / canjeadas',
                    valor: c.averiados,
                    habilitado: widget.habilitado,
                    onChanged: (v) {
                      c.averiados = v;
                      widget.onChanged();
                    },
                  ),
                ],
              ),
            ),
            secondChild: const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _LineaConteo extends StatelessWidget {
  final String etiqueta;
  final int valor;
  final bool habilitado;
  final ValueChanged<int> onChanged;

  const _LineaConteo({
    required this.etiqueta,
    required this.valor,
    required this.habilitado,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(etiqueta, style: AppTextStyles.input.copyWith(fontSize: 13.5)),
        ),
        ContadorEnvases(
          value: valor,
          enabled: habilitado,
          min: 0,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _SeccionObservaciones extends StatelessWidget {
  final TextEditingController controller;
  final String resumen;
  final bool habilitado;

  const _SeccionObservaciones({required this.controller, required this.resumen, this.habilitado = true});

  @override
  Widget build(BuildContext context) {
    return _SeccionPlegable(
      icono: Icons.notes_outlined,
      titulo: 'Observaciones',
      subtitulo: 'Aclaraciones para la planta o el administrador (opcional).',
      resumen: resumen,
      child: TextField(
        controller: controller,
        enabled: habilitado,
        maxLines: 3,
        cursorColor: AppColors.orange,
        style: AppTextStyles.input,
        decoration: const InputDecoration(
          hintText: 'Escribí una nota…',
          isDense: true,
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.inputBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.orange),
          ),
        ),
      ),
    );
  }
}

class _Resumen extends StatelessWidget {
  final int efectivo;
  final int cheques;
  final int transferencias;
  final List<_ResumenProducto> productos;

  const _Resumen({
    required this.efectivo,
    required this.cheques,
    required this.transferencias,
    required this.productos,
  });

  @override
  Widget build(BuildContext context) {
    final totalValores = efectivo + cheques + transferencias;
    final vacios = productos.fold(0, (a, p) => a + p.vacios);
    final llenos = productos.fold(0, (a, p) => a + p.llenos);
    final averiados = productos.fold(0, (a, p) => a + p.averiados);
    final totalGarrafas = vacios + llenos + averiados;

    final detalleValores = <MapEntry<String, String>>[
      if (efectivo > 0) MapEntry('Efectivo', formatMoneda(efectivo)),
      if (cheques > 0) MapEntry('Cheques', formatMoneda(cheques)),
      if (transferencias > 0) MapEntry('Transferencias', formatMoneda(transferencias)),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.steelBlue.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.steelBlue.withOpacity(0.30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Resumen a enviar', style: AppTextStyles.label.copyWith(fontSize: 15)),
          const SizedBox(height: 12),
          _LineaResumenPlegable(
            etiqueta: 'Total valores declarados',
            valor: formatMoneda(totalValores),
            acento: AppColors.orange,
            detalle: detalleValores,
          ),
          const SizedBox(height: 8),
          _LineaResumenPlegable(
            etiqueta: 'Vacías recuperadas',
            valor: '$vacios',
            detalle: _detallePorKilaje((p) => p.vacios),
          ),
          const SizedBox(height: 8),
          _LineaResumenPlegable(
            etiqueta: 'Llenas que vuelven',
            valor: '$llenos',
            detalle: _detallePorKilaje((p) => p.llenos),
          ),
          const SizedBox(height: 8),
          _LineaResumenPlegable(
            etiqueta: 'Dañadas / canjeadas',
            valor: '$averiados',
            detalle: _detallePorKilaje((p) => p.averiados),
          ),
          const Divider(height: 20, color: AppColors.inputBorder),
          _LineaResumen(
            etiqueta: 'Total garrafas rendidas',
            valor: '$totalGarrafas',
            acento: AppColors.steelBlue,
          ),
        ],
      ),
    );
  }

  List<MapEntry<String, String>> _detallePorKilaje(int Function(_ResumenProducto) selector) {
    return [
      for (final p in productos)
        if (selector(p) > 0) MapEntry(p.etiqueta, '${selector(p)}'),
    ];
  }
}

class _LineaResumen extends StatelessWidget {
  final String etiqueta;
  final String valor;
  final Color? acento;

  const _LineaResumen({required this.etiqueta, required this.valor, this.acento});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(etiqueta, style: AppTextStyles.link.copyWith(fontSize: 13.5)),
        ),
        Text(
          valor,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: acento ?? AppColors.graphiteGray,
          ),
        ),
      ],
    );
  }
}

class _LineaResumenPlegable extends StatefulWidget {
  final String etiqueta;
  final String valor;
  final Color? acento;
  final List<MapEntry<String, String>> detalle;

  const _LineaResumenPlegable({
    required this.etiqueta,
    required this.valor,
    required this.detalle,
    this.acento,
  });

  @override
  State<_LineaResumenPlegable> createState() => _LineaResumenPlegableState();
}

class _LineaResumenPlegableState extends State<_LineaResumenPlegable> {
  bool _abierta = false;

  @override
  Widget build(BuildContext context) {
    final plegable = widget.detalle.isNotEmpty;
    final color = widget.acento ?? AppColors.graphiteGray;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: plegable ? () => setState(() => _abierta = !_abierta) : null,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Expanded(
                  child: Text(widget.etiqueta, style: AppTextStyles.link.copyWith(fontSize: 13.5)),
                ),
                Text(
                  widget.valor,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color),
                ),
                if (plegable) ...[
                  const SizedBox(width: 4),
                  AnimatedRotation(
                    turns: _abierta ? 0.5 : 0,
                    duration: const Duration(milliseconds: 160),
                    child: const Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.graphiteGray),
                  ),
                ],
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 160),
          crossFadeState: _abierta ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          firstChild: Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 0, 2),
            child: Column(
              children: [
                for (final d in widget.detalle)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.circle, size: 5, color: AppColors.graphiteGray),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            d.key,
                            style: AppTextStyles.footer.copyWith(color: AppColors.graphiteGray),
                          ),
                        ),
                        Text(
                          d.value,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.steelBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          secondChild: const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

class _SeccionPlegable extends StatefulWidget {
  final IconData icono;
  final String titulo;
  final String subtitulo;
  final String resumen;
  final Widget child;

  const _SeccionPlegable({
    required this.icono,
    required this.titulo,
    required this.subtitulo,
    required this.resumen,
    required this.child,
  });

  @override
  State<_SeccionPlegable> createState() => _SeccionPlegableState();
}

class _SeccionPlegableState extends State<_SeccionPlegable> {
  bool _abierta = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => setState(() => _abierta = !_abierta),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(widget.icono, size: 20, color: AppColors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.titulo, style: AppTextStyles.label.copyWith(fontSize: 15)),
                        if (!_abierta && widget.resumen.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            widget.resumen,
                            style: AppTextStyles.footer.copyWith(color: AppColors.graphiteGray),
                          ),
                        ],
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _abierta ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: const Icon(Icons.keyboard_arrow_down, color: AppColors.graphiteGray),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 180),
            crossFadeState: _abierta ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            firstChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    widget.subtitulo,
                    style: AppTextStyles.footer.copyWith(color: AppColors.graphiteGray),
                  ),
                  const SizedBox(height: 14),
                  widget.child,
                ],
              ),
            ),
            secondChild: const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _CampoMoneda extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final VoidCallback onChanged;
  final bool habilitado;

  const _CampoMoneda({
    required this.label,
    required this.controller,
    required this.onChanged,
    this.habilitado = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.input.copyWith(fontSize: 13.5)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          enabled: habilitado,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (_) => onChanged(),
          cursorColor: AppColors.orange,
          style: AppTextStyles.input,
          decoration: const InputDecoration(
            prefixText: '\$ ',
            isDense: true,
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.inputBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.orange),
            ),
          ),
        ),
      ],
    );
  }
}

class _DatosBloqueadosNota extends StatelessWidget {
  final bool pendiente;

  const _DatosBloqueadosNota({this.pendiente = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.lock_outline, size: 16, color: AppColors.graphiteGray),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            pendiente
                ? 'Rendición guardada: se envía sola cuando vuelva la señal.'
                : 'Rendición enviada: los datos no se pueden modificar.',
            textAlign: TextAlign.center,
            style: AppTextStyles.footer.copyWith(color: AppColors.graphiteGray),
          ),
        ),
      ],
    );
  }
}
