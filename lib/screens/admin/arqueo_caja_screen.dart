import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/responsive.dart';
import '../../models/cuadre_rendicion.dart';
import '../../repositories/rendicion_admin_repository.dart';
import '../../data/mock_cobranza_data.dart';
import '../../models/arqueo_caja.dart';
import '../../models/usuario_model.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/catalogo_repository.dart';
import '../../repositories/cobranza_repository.dart';
import '../../repositories/network_exception.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/formato.dart';
import '../../widgets/admin/cobranza/arqueo_prestamos_card.dart';
import '../../widgets/admin/cobranza/arqueo_resumen_card.dart';
import '../../widgets/admin/cobranza/cuadre_rendicion_modal.dart';
import '../../widgets/admin/cobranza/fila_comparativa_movil.dart';
import '../../widgets/admin/cobranza/paso_rendicion_card.dart';
import '../../widgets/admin/cobranza/arqueo_tabla.dart';
import '../../widgets/common/carga/zona_carga.dart';
import '../../widgets/common/filtros/filtros.dart';
import '../../core/feedback/app_feedback.dart';

class ArqueoCajaScreen extends StatefulWidget {
  const ArqueoCajaScreen({super.key});

  @override
  State<ArqueoCajaScreen> createState() => _ArqueoCajaScreenState();
}

class _ArqueoCajaScreenState extends State<ArqueoCajaScreen> {
  late final CobranzaRepository _repo;
  late final CatalogoRepository _catalogoRepo;

  List<UsuarioModel> _choferes = [];
  String? _choferId;
  DateTime _fecha = DateTime.now();

  ArqueoCaja? _arqueo;
  bool _loading = false;
  bool _modoEjemplo = false;
  String? _aviso;
  bool _cerrando = false;
  bool _cerrado = false;
  late final RendicionAdminRepository _rendicionRepo;
  CuadreRendicion? _cuadre;
  bool _cargandoCuadre = false;
  bool _errorCuadre = false;

  Set<String> _choferesCerrados = {};

  Future<void> _cargarEstadosCierre() async {
    final fecha = _fecha;
    final choferes = _choferes;
    if (choferes.isEmpty) return;
    final resultados = await Future.wait(choferes.map((c) => _repo
        .getArqueo(idUsuario: c.id, fecha: fecha)
        .then((a) => a.cerrado ? c.id : null)
        .catchError((_) => null)));
    if (!mounted || fecha != _fecha) return;
    setState(() => _choferesCerrados = resultados.whereType<String>().toSet());
  }

  bool get _rendicionAprobada => _cuadre?.aprobadaORutaCerrada ?? false;

  bool get _esHoy {
    final hoy = DateTime.now();
    return _fecha.year == hoy.year && _fecha.month == hoy.month && _fecha.day == hoy.day;
  }

  @override
  void initState() {
    super.initState();
    final apiClient = context.read<AuthProvider>().apiClient;
    _repo = CobranzaRepository(apiClient);
    _catalogoRepo = CatalogoRepository(apiClient);
    _rendicionRepo = RendicionAdminRepository(apiClient);
    _cargarChoferes();
  }

  Future<void> _cargarChoferes() async {
    try {
      final choferes = await _catalogoRepo.listarUsuarios(rol: 'CHOFER');
      if (!mounted) return;
      setState(() {
        _choferes = choferes;
        if (choferes.isNotEmpty && _choferId == null) {
          _choferId = choferes.first.id;
        }
      });
      if (_choferId != null) _cargarArqueo();
      unawaited(_cargarEstadosCierre());
    } catch (_) {
      if (!mounted) return;
      setState(() => _choferes = const []);
    }
  }

  String get _nombreChofer {
    for (final c in _choferes) {
      if (c.id == _choferId) return c.fullName.isNotEmpty ? c.fullName : c.email;
    }
    return 'Chofer';
  }

  Future<void> _cargarCuadre() async {
    final idUsuario = _choferId;
    if (idUsuario == null) return;
    final fecha = _fecha;
    setState(() {
      _cargandoCuadre = true;
      _errorCuadre = false;
    });
    try {
      final cuadre = await _rendicionRepo.getCuadre(idUsuario: idUsuario, fecha: fecha);
      if (!mounted || idUsuario != _choferId || fecha != _fecha) return;
      setState(() {
        _cuadre = cuadre;
        _cargandoCuadre = false;
      });
    } catch (_) {
      if (!mounted || idUsuario != _choferId || fecha != _fecha) return;
      setState(() {
        _cuadre = null;
        _cargandoCuadre = false;
        _errorCuadre = true;
      });
    }
  }

  Future<void> _cargarArqueo() async {
    final idUsuario = _choferId;
    if (idUsuario == null) return;
    _cuadre = null;
    unawaited(_cargarCuadre());
    setState(() {
      _loading = true;
      _aviso = null;
      _cerrado = false;
    });
    try {
      final arqueo = await _repo.getArqueo(idUsuario: idUsuario, fecha: _fecha);
      if (!mounted) return;
      setState(() {
        _arqueo = arqueo;
        _modoEjemplo = false;
        _loading = false;
        // Refleja el estado real que devuelve el backend: si ya estaba cerrado,
        // la pantalla lo muestra como cerrado aunque recién entremos.
        _cerrado = arqueo.cerrado;
      });
    } on NetworkException {
      _usarEjemplo('No se pudo conectar con el servidor: mostrando datos de ejemplo.');
    } on CobranzaRepositoryException catch (e) {
      if (e.endpointNoDisponible) {
        _usarEjemplo('El endpoint de arqueo aún no está disponible: mostrando datos de ejemplo.');
      } else {
        _usarEjemplo(e.message);
      }
    } catch (_) {
      _usarEjemplo('Ocurrió un problema al cargar el arqueo: mostrando datos de ejemplo.');
    }
  }

  void _usarEjemplo(String mensaje) {
    if (!mounted) return;
    setState(() {
      _arqueo = arqueoDeEjemplo(
        idUsuario: _choferId ?? 'demo',
        nombre: _nombreChofer,
        fecha: _fecha,
      );
      _modoEjemplo = true;
      _aviso = mensaje;
      _loading = false;
    });
  }

  void _cambiarFecha(DateTime fecha) {
    setState(() {
      _fecha = fecha;
      _choferesCerrados = {};
    });
    _cargarArqueo();
    unawaited(_cargarEstadosCierre());
  }

  int _totalSistema(String metodo) {
    for (final m in _arqueo?.totalesPorMetodo ?? const <ArqueoMetodoTotal>[]) {
      if (m.metodoPago == metodo) return m.total;
    }
    return 0;
  }

  Future<void> _cerrarArqueo() async {
    final idUsuario = _choferId;
    if (idUsuario == null || _cerrando) return;
    if (!_esHoy) {
      AppFeedback.advertencia(
        'Solo se puede cerrar el arqueo del día de hoy. Los días anteriores quedan solo para consulta.',
        titulo: 'Día anterior',
      );
      return;
    }
    if (!_rendicionAprobada && !_modoEjemplo) {
      AppFeedback.advertencia(
        'Primero revisá y aprobá la rendición del chofer. Después podés cerrar el arqueo.',
        titulo: 'Falta aprobar la rendición',
      );
      return;
    }

    final actual = _cuadre;
    final cuadre = actual != null && actual.hayRendicion ? actual : null;
    final efectivoSistema = _totalSistema('EFECTIVO');
    final chequeSistema = _totalSistema('CHEQUE');
    final transferenciaSistema = _totalSistema('TRANSFERENCIA');
    final declarado = await showDialog<_MontosDeclarados>(
      context: context,
      builder: (_) => _CierreArqueoDialog(
        efectivoSistema: efectivoSistema,
        chequeSistema: chequeSistema,
        transferenciaSistema: transferenciaSistema,
        efectivoDeclarado: cuadre?.efectivoDeclarado ?? efectivoSistema,
        chequeDeclarado: cuadre?.chequesDeclarado ?? chequeSistema,
        transferenciaDeclarada: cuadre?.transferenciasDeclarado ?? transferenciaSistema,
      ),
    );
    if (declarado == null || !mounted) return;

    setState(() => _cerrando = true);
    try {
      if (!_modoEjemplo) {
        await _repo.cerrarArqueo(
          idUsuario: idUsuario,
          fecha: _fecha,
          efectivoDeclarado: declarado.efectivo,
          chequeDeclarado: declarado.cheque,
          transferenciaDeclarada: declarado.transferencia,
          observacion: declarado.observacion,
        );
      }
      if (!mounted) return;
      setState(() {
        _cerrado = true;
        _choferesCerrados = {..._choferesCerrados, idUsuario};
        _cerrando = false;
      });
      _snack('Arqueo cerrado y auditado.');
    } on CobranzaRepositoryException catch (e) {
      if (!mounted) return;
      setState(() {
        _cerrando = false;
        _cerrado = e.endpointNoDisponible;
      });
      _snack(
        e.endpointNoDisponible
            ? 'Cierre local: el endpoint de cierre todavía no está en el backend.'
            : e.message,
        error: !e.endpointNoDisponible,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _cerrando = false);
      _snack('No se pudo cerrar el arqueo.', error: true);
    }
  }

  void _snack(String mensaje, {bool error = false}) {
    if (error) {
      AppFeedback.error(mensaje);
    } else {
      AppFeedback.exito(mensaje);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = Responsive.isDesktop(constraints);
        final dosColumnas = constraints.maxWidth >= 1200;
        final padding = EdgeInsets.all(isDesktop ? 28 : 16);
        return SingleChildScrollView(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ReportarCarga(cargando: _loading),
              _Cabecera(nombreChofer: _nombreChofer),
              const SizedBox(height: 20),
              _Filtros(
                choferes: _choferes,
                choferId: _choferId,
                cerrados: _choferesCerrados,
                fecha: _fecha,
                onChofer: (id) {
                  setState(() => _choferId = id);
                  _cargarArqueo();
                },
                onFecha: _cambiarFecha,
                onRefrescar: _choferId == null
                    ? null
                    : () {
                        _cargarArqueo();
                        _cargarEstadosCierre();
                      },
                cargando: _loading,
              ),
              if (_aviso != null) ...[
                const SizedBox(height: 16),
                _AvisoBanner(mensaje: _aviso!, esEjemplo: _modoEjemplo),
              ],
              const SizedBox(height: 20),
              if (_loading)
                const SizedBox(height: 180)
              else if (_arqueo == null)
                _Placeholder()
              else if (dosColumnas)
                _contenidoDosColumnas()
              else
                _contenidoApilado(),
              if (_arqueo != null && !_loading) ...[
                const SizedBox(height: 20),
                ArqueoPrestamosCard(
                  notas: _arqueo!.notasDebito,
                  garrafasAdeudadas: _arqueo!.garrafasAdeudadas,
                  pendientes: _arqueo!.notasDebitoPendientes,
                  totalCobrado: _arqueo!.totalPrestamos,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _contenidoDosColumnas() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _tarjetaTabla()),
        const SizedBox(width: 20),
        SizedBox(width: 320, child: _resumen()),
      ],
    );
  }

  Widget _contenidoApilado() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _tarjetaTabla(),
        const SizedBox(height: 20),
        _resumen(),
      ],
    );
  }

  Widget _tarjetaTabla() {
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
            padding: Responsive.isMobileContext(context)
                ? const EdgeInsets.fromLTRB(16, 16, 16, 12)
                : const EdgeInsets.fromLTRB(20, 18, 20, 14),
            child: Text(
              'Liquidación Diaria: $_nombreChofer',
              style: AppTextStyles.label.copyWith(fontSize: 15),
            ),
          ),
          ArqueoTabla(movimientos: _arqueo!.movimientos),
        ],
      ),
    );
  }

  Widget _resumen() {
    final arqueo = _arqueo!;
    final puedeCerrar = _esHoy && (_rendicionAprobada || _modoEjemplo);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PasoRendicionCard(
          cuadre: _cuadre,
          cargando: _cargandoCuadre,
          error: _errorCuadre,
          onAbrir: _choferId == null ? null : _abrirCuadre,
        ),
        const SizedBox(height: 16),
        ArqueoResumenCard(
          encabezado: const NumeroPasoArqueo(),
          totales: arqueo.totalesPorMetodo,
          totalGeneral: arqueo.totalGeneral,
          totalVentaSocial: arqueo.totalVentaSocial,
          cerrado: _cerrado,
          cerrando: _cerrando,
          puedeCerrar: puedeCerrar,
          avisoCierre: _esHoy
              ? 'Para cerrar el arqueo primero tenés que aprobar la rendición del chofer (paso 1).'
              : 'Es un día anterior: el arqueo y la rendición solo se pueden consultar, no cerrar ni aprobar.',
          onCerrar: _cerrarArqueo,
        ),
      ],
    );
  }

  Future<void> _abrirCuadre() async {
    final idUsuario = _choferId;
    if (idUsuario == null) return;
    await mostrarCuadreRendicion(
      context,
      apiClient: context.read<AuthProvider>().apiClient,
      idUsuario: idUsuario,
      nombreChofer: _nombreChofer,
      fecha: _fecha,
    );
    if (!mounted) return;
    await _cargarCuadre();
  }
}

class _Cabecera extends StatelessWidget {
  final String nombreChofer;

  const _Cabecera({required this.nombreChofer});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Arqueo de Caja',
          style: Responsive.isMobileContext(context)
              ? AppTextStyles.desktopTitle.copyWith(fontSize: 22)
              : AppTextStyles.desktopTitle,
        ),
        const SizedBox(height: 4),
        Text(
          'Conciliación diaria de fondos por chofer, auditando hora física del cobro vs. hora de sincronización.',
          style: AppTextStyles.desktopSubtitle,
        ),
      ],
    );
  }
}

class _Filtros extends StatelessWidget {
  final List<UsuarioModel> choferes;
  final String? choferId;
  final Set<String> cerrados;
  final DateTime fecha;
  final ValueChanged<String> onChofer;
  final ValueChanged<DateTime> onFecha;
  final VoidCallback? onRefrescar;
  final bool cargando;

  const _Filtros({
    required this.choferes,
    required this.choferId,
    this.cerrados = const {},
    required this.fecha,
    required this.onChofer,
    required this.onFecha,
    required this.onRefrescar,
    required this.cargando,
  });

  @override
  Widget build(BuildContext context) {
    return FiltrosPanel(
      filas: [
        SelectorFechaUnica(
          fecha: fecha,
          primera: DateTime(2023),
          ultima: DateTime(2100),
          onCambio: onFecha,
        ),
        FilaFiltros(
          children: [
            FiltroBuscable(
              etiqueta: 'Chofer',
              icono: Icons.person_outline,
              obligatorio: true,
              hint: 'Seleccionar chofer',
              ancho: 260,
              opciones: [
                for (final c in choferes)
                  OpcionFiltro(
                    c.id,
                    c.fullName.isNotEmpty ? c.fullName : c.email,
                    completado: cerrados.contains(c.id),
                    tooltipCompletado: 'Rendición aprobada y arqueo cerrado',
                  ),
              ],
              seleccion: choferId,
              onCambio: (id) {
                if (id != null) onChofer(id);
              },
            ),
            BotonActualizar(onPressed: onRefrescar, cargando: cargando),
          ],
        ),
      ],
    );
  }
}

class _Placeholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Text(
          'Elegí un chofer y una fecha para ver la liquidación.',
          style: AppTextStyles.link,
          textAlign: TextAlign.center,
        ),
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

class _MontosDeclarados {
  final int efectivo;
  final int cheque;
  final int transferencia;
  final String? observacion;

  const _MontosDeclarados({
    required this.efectivo,
    required this.cheque,
    required this.transferencia,
    this.observacion,
  });
}

class _CierreArqueoDialog extends StatefulWidget {
  final int efectivoSistema;
  final int chequeSistema;
  final int transferenciaSistema;
  final int efectivoDeclarado;
  final int chequeDeclarado;
  final int transferenciaDeclarada;

  const _CierreArqueoDialog({
    required this.efectivoSistema,
    required this.chequeSistema,
    required this.transferenciaSistema,
    required this.efectivoDeclarado,
    required this.chequeDeclarado,
    required this.transferenciaDeclarada,
  });

  @override
  State<_CierreArqueoDialog> createState() => _CierreArqueoDialogState();
}

class _CierreArqueoDialogState extends State<_CierreArqueoDialog> {
  final _observacion = TextEditingController();

  bool get _hayDiferencia =>
      widget.efectivoDeclarado != widget.efectivoSistema ||
      widget.chequeDeclarado != widget.chequeSistema ||
      widget.transferenciaDeclarada != widget.transferenciaSistema;

  bool get _valido => !_hayDiferencia || _observacion.text.trim().isNotEmpty;

  @override
  void dispose() {
    _observacion.dispose();
    super.dispose();
  }

  void _confirmar() {
    if (!_valido) return;
    Navigator.of(context).pop(_MontosDeclarados(
      efectivo: widget.efectivoDeclarado,
      cheque: widget.chequeDeclarado,
      transferencia: widget.transferenciaDeclarada,
      observacion: _observacion.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final movil = Responsive.isMobileContext(context);
    final ancho = movil ? math.min(440.0, MediaQuery.sizeOf(context).width - 64) : 440.0;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: movil
          ? const EdgeInsets.symmetric(horizontal: 16, vertical: 24)
          : const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      titlePadding: movil ? const EdgeInsets.fromLTRB(16, 20, 16, 0) : null,
      contentPadding: movil ? const EdgeInsets.fromLTRB(16, 16, 16, 12) : null,
      title: Text(
        'Cerrar arqueo auditado',
        style: movil ? AppTextStyles.title.copyWith(fontSize: 19) : AppTextStyles.title,
      ),
      content: SizedBox(
        width: ancho,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Los montos salen de la rendición aprobada y no se pueden modificar. '
                'Si hay diferencia con el sistema, dejá un comentario que la explique.',
                style: AppTextStyles.link.copyWith(fontSize: 12.5),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.inputBorder),
                ),
                child: Column(
                  children: [
                    const _FilaMontoArqueo.encabezado(),
                    _FilaMontoArqueo(
                      etiqueta: 'Efectivo',
                      sistema: widget.efectivoSistema,
                      declarado: widget.efectivoDeclarado,
                    ),
                    _FilaMontoArqueo(
                      etiqueta: 'Cheque',
                      sistema: widget.chequeSistema,
                      declarado: widget.chequeDeclarado,
                    ),
                    _FilaMontoArqueo(
                      etiqueta: 'Transferencia',
                      sistema: widget.transferenciaSistema,
                      declarado: widget.transferenciaDeclarada,
                      ultima: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _observacion,
                minLines: 2,
                maxLines: 4,
                maxLength: 500,
                onChanged: (_) => setState(() {}),
                cursorColor: AppColors.orange,
                decoration: InputDecoration(
                  labelText: _hayDiferencia ? 'Comentario (obligatorio)' : 'Comentario (opcional)',
                  hintText: _hayDiferencia ? 'Explicá el faltante o sobrante' : null,
                  isDense: true,
                  counterText: '',
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: _hayDiferencia && _observacion.text.trim().isEmpty
                          ? AppColors.orange.withOpacity(0.6)
                          : AppColors.inputBorder,
                    ),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.orange),
                  ),
                  floatingLabelStyle: const TextStyle(color: AppColors.orange),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancelar',
            style: AppTextStyles.button.copyWith(color: AppColors.graphiteGray),
          ),
        ),
        TextButton(
          onPressed: _valido ? _confirmar : null,
          child: Text(
            'Cerrar arqueo',
            style: AppTextStyles.button.copyWith(
              color: _valido ? AppColors.orange : AppColors.badgeGray,
            ),
          ),
        ),
      ],
    );
  }
}

class _FilaMontoArqueo extends StatelessWidget {
  final String etiqueta;
  final int sistema;
  final int declarado;
  final bool ultima;
  final bool esEncabezado;

  const _FilaMontoArqueo({
    required this.etiqueta,
    required this.sistema,
    required this.declarado,
    this.ultima = false,
  }) : esEncabezado = false;

  const _FilaMontoArqueo.encabezado()
      : etiqueta = 'CONCEPTO',
        sistema = 0,
        declarado = 0,
        ultima = false,
        esEncabezado = true;

  @override
  Widget build(BuildContext context) {
    const estiloEncabezado = TextStyle(
      fontSize: 10.5,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.3,
      color: AppColors.graphiteGray,
    );
    final dif = declarado - sistema;
    final colorDif = dif == 0 ? AppColors.badgeGreen : (dif > 0 ? AppColors.steelBlue : AppColors.error);
    final borde = ultima
        ? null
        : Border(bottom: BorderSide(color: AppColors.inputBorder.withOpacity(0.7)));
    if (Responsive.isMobileContext(context)) {
      if (esEncabezado) return const SizedBox.shrink();
      return Container(
        decoration: BoxDecoration(border: borde),
        child: FilaComparativaMovil(
          concepto: etiqueta,
          sistema: formatMoneda(sistema),
          declarado: formatMoneda(declarado),
          etiquetaDeclarado: 'Rendido',
          diferencia: Text(
            dif == 0 ? 'OK' : formatMoneda(dif),
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: colorDif),
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(border: borde),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              etiqueta,
              style: esEncabezado ? estiloEncabezado : AppTextStyles.label.copyWith(fontSize: 13),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              esEncabezado ? 'SISTEMA' : formatMoneda(sistema),
              textAlign: TextAlign.right,
              style: esEncabezado
                  ? estiloEncabezado
                  : const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.graphiteGray),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              esEncabezado ? 'RENDIDO' : formatMoneda(declarado),
              textAlign: TextAlign.right,
              style: esEncabezado
                  ? estiloEncabezado
                  : const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.steelBlue),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              esEncabezado ? 'DIFERENCIA' : (dif == 0 ? 'OK' : formatMoneda(dif)),
              textAlign: TextAlign.right,
              style: esEncabezado
                  ? estiloEncabezado
                  : TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: colorDif),
            ),
          ),
        ],
      ),
    );
  }
}
