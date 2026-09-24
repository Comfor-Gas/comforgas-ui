import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../../../models/cuadre_rendicion.dart';
import '../../../repositories/network_exception.dart';
import '../../../repositories/rendicion_admin_repository.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../utils/formato.dart';

Future<void> mostrarCuadreRendicion(
  BuildContext context, {
  required http.Client apiClient,
  required String idUsuario,
  required String nombreChofer,
  required DateTime fecha,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (_) => CuadreRendicionModal(
      apiClient: apiClient,
      idUsuario: idUsuario,
      nombreChofer: nombreChofer,
      fecha: fecha,
    ),
  );
}

class CuadreRendicionModal extends StatefulWidget {
  final http.Client apiClient;
  final String idUsuario;
  final String nombreChofer;
  final DateTime fecha;

  const CuadreRendicionModal({
    super.key,
    required this.apiClient,
    required this.idUsuario,
    required this.nombreChofer,
    required this.fecha,
  });

  @override
  State<CuadreRendicionModal> createState() => _CuadreRendicionModalState();
}

class _CuadreRendicionModalState extends State<CuadreRendicionModal> {
  late final RendicionAdminRepository _repo;

  CuadreRendicion? _cuadre;
  bool _loading = true;
  bool _modoEjemplo = false;
  String? _aviso;
  bool _aprobando = false;
  bool _procesandoAjuste = false;
  bool _aprobadaLocal = false;

  @override
  void initState() {
    super.initState();
    _repo = RendicionAdminRepository(widget.apiClient);
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _loading = true);
    try {
      final cuadre = await _repo.getCuadre(idUsuario: widget.idUsuario, fecha: widget.fecha);
      if (!mounted) return;
      setState(() {
        _cuadre = cuadre;
        _modoEjemplo = !cuadre.hayRendicion;
        _aviso = cuadre.hayRendicion
            ? null
            : 'El chofer todavía no envió la rendición del día. Los valores quedan en cero hasta recibirla.';
        _loading = false;
      });
    } on NetworkException {
      _usarVacio('Sin conexión: no se pudo cargar el cuadre.');
    } on RendicionAdminRepositoryException catch (e) {
      _usarVacio(e.message);
    } catch (_) {
      _usarVacio('No se pudo cargar el cuadre.');
    }
  }

  void _usarVacio(String mensaje) {
    if (!mounted) return;
    setState(() {
      _cuadre = CuadreRendicion.vacio(
        idUsuario: widget.idUsuario,
        nombreChofer: widget.nombreChofer,
        fecha: widget.fecha,
      );
      _modoEjemplo = true;
      _aviso = mensaje;
      _loading = false;
    });
  }

  bool get _bloqueada =>
      _aprobadaLocal || (_cuadre?.rutaBloqueada ?? false) || (_cuadre?.aprobada ?? false);

  Future<void> _aprobar() async {
    if (_aprobando || _bloqueada) return;
    final hayDiferencias = _cuadre?.tieneDiferencias ?? false;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dc) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Aprobar conciliación', style: AppTextStyles.title),
        content: Text(
          hayDiferencias
              ? 'Hay diferencias sin ajustar. Si aprobás, quedan registradas como diferencia '
                  'y la ruta del chofer queda cerrada y bloqueada. No se podrán registrar más '
                  'movimientos de esta jornada.'
              : 'Al aprobar, la ruta del chofer queda cerrada y bloqueada. '
                  'No se podrán registrar más movimientos de esta jornada.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dc).pop(false),
            child: Text('Cancelar', style: AppTextStyles.button.copyWith(color: AppColors.graphiteGray)),
          ),
          TextButton(
            onPressed: () => Navigator.of(dc).pop(true),
            child: Text('Aprobar y cerrar', style: AppTextStyles.button.copyWith(color: AppColors.badgeGreen)),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;

    setState(() => _aprobando = true);
    try {
      final idRendicion = _cuadre?.idRendicion;
      if (!_modoEjemplo && idRendicion != null) {
        await _repo.aprobarConciliacion(idRendicion: idRendicion);
      }
      if (!mounted) return;
      setState(() {
        _aprobando = false;
        _aprobadaLocal = true;
      });
      _snack('Conciliación aprobada. La ruta quedó cerrada y bloqueada.');
    } on RendicionAdminRepositoryException catch (e) {
      if (!mounted) return;
      setState(() {
        _aprobando = false;
        _aprobadaLocal = e.endpointNoDisponible;
      });
      _snack(
        e.endpointNoDisponible
            ? 'Aprobación local: el endpoint de cierre todavía no está en el backend.'
            : _mensajeAprobacion(e.message),
        error: !e.endpointNoDisponible,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _aprobando = false);
      _snack('No se pudo aprobar la conciliación.', error: true);
    }
  }

  Future<void> _registrarAjuste() async {
    if (_procesandoAjuste) return;
    final ajuste = await showDialog<_AjusteResult>(
      context: context,
      builder: (_) => const _AjusteDialog(),
    );
    if (ajuste == null || !mounted) return;

    setState(() => _procesandoAjuste = true);
    try {
      if (!_modoEjemplo) {
        await _repo.registrarAjuste(
          idUsuario: widget.idUsuario,
          fecha: widget.fecha,
          observacion: ajuste.observacion,
          montoAjuste: ajuste.monto,
          garrafasAjuste: ajuste.garrafas,
        );
      }
      if (!mounted) return;
      setState(() => _procesandoAjuste = false);
      _snack('Ajuste / observación registrado.');
    } on RendicionAdminRepositoryException catch (e) {
      if (!mounted) return;
      setState(() => _procesandoAjuste = false);
      _snack(
        e.endpointNoDisponible
            ? 'Registro local: el endpoint de ajuste todavía no está en el backend.'
            : e.message,
        error: !e.endpointNoDisponible,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _procesandoAjuste = false);
      _snack('No se pudo registrar el ajuste.', error: true);
    }
  }

  String _mensajeAprobacion(String backend) {
    const marcador = 'aprobar la rendicion:';
    final idx = backend.toLowerCase().indexOf(marcador);
    if (idx >= 0) {
      final codigos = backend.substring(idx + marcador.length).split(';');
      final traducidos = codigos
          .map((c) => traducirBloqueoCuadre(c))
          .where((s) => s.trim().isNotEmpty)
          .toList();
      if (traducidos.isNotEmpty) {
        return 'No se puede aprobar todavía. ${traducidos.join(' ')}';
      }
    }
    return backend;
  }

  void _snack(String mensaje, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: error ? AppColors.error : AppColors.badgeGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 660, maxHeight: 720),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Encabezado(nombreChofer: widget.nombreChofer, bloqueada: _bloqueada, onCerrar: () => Navigator.of(context).pop()),
            const Divider(height: 1, color: AppColors.inputBorder),
            Flexible(
              child: _loading
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Center(child: CircularProgressIndicator(color: AppColors.orange)),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: _contenido(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _contenido() {
    final cuadre = _cuadre!;
    final valores = <_LineaCuadre>[
      _LineaCuadre('Efectivo', cuadre.efectivoSistema, cuadre.efectivoDeclarado, esMoneda: true),
      _LineaCuadre('Cheques', cuadre.chequesSistema, cuadre.chequesDeclarado, esMoneda: true),
      _LineaCuadre('Transferencias', cuadre.transferenciasSistema, cuadre.transferenciasDeclarado, esMoneda: true),
    ];
    final totalSistema = cuadre.totalSistemaValores;

    final totalDeclarado = cuadre.totalDeclaradoValores;
    final cuadraEnvases = cuadre.envases.every((e) => e.cuadra);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_aviso != null) ...[
          _AvisoBanner(mensaje: _aviso!, esEjemplo: _modoEjemplo),
          const SizedBox(height: 16),
        ],
        _SeccionPlegableCuadre(
          icono: Icons.payments_outlined,
          titulo: 'Rendición de Valores',
          trailing: _BadgeDif(diferencia: totalDeclarado - totalSistema, esMoneda: true),
          child: _TablaCuadre(
            lineas: valores,
            totalSistema: totalSistema,
            totalDeclarado: totalDeclarado,
            esMoneda: true,
          ),
        ),
        const SizedBox(height: 14),
        _SeccionPlegableCuadre(
          icono: Icons.propane_tank_outlined,
          titulo: 'Envases (garrafas)',
          trailing: cuadre.envases.isEmpty ? null : _BadgeEstado(cuadra: cuadraEnvases),
          child: cuadre.envases.isEmpty
              ? Text('El chofer no declaró envases en esta rendición.',
                  style: AppTextStyles.footer.copyWith(color: AppColors.graphiteGray))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final e in cuadre.envases) ...[
                      _BloqueEnvase(linea: e),
                      const SizedBox(height: 10),
                    ],
                  ],
                ),
        ),
        const SizedBox(height: 18),
        if (!cuadre.hayRendicion)
          const _RendicionPendienteAviso()
        else if (_bloqueada)
          const _RutaCerradaAviso()
        else ...[
          if (cuadre.bloqueosDuros.isNotEmpty) ...[
            _BloqueosAviso(bloqueos: cuadre.bloqueosDuros),
            const SizedBox(height: 12),
          ],
          if (cuadre.bloqueosBlandos.isNotEmpty) ...[
            _DiferenciasAviso(bloqueos: cuadre.bloqueosBlandos),
            const SizedBox(height: 12),
          ],
          _PanelAcciones(
            aprobando: _aprobando,
            procesandoAjuste: _procesandoAjuste,
            aprobarHabilitado: cuadre.bloqueosDuros.isEmpty,
            onAprobar: _aprobar,
            onAjuste: _registrarAjuste,
          ),
        ],
      ],
    );
  }
}

class _RendicionPendienteAviso extends StatelessWidget {
  const _RendicionPendienteAviso();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.badgeAmber.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.badgeAmber.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.hourglass_empty, size: 18, color: AppColors.badgeAmber),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Todavía no se puede conciliar: el chofer no envió la rendición de esta jornada.',
              style: AppTextStyles.link.copyWith(fontSize: 12.5, color: AppColors.graphiteGray),
            ),
          ),
        ],
      ),
    );
  }
}

class _LineaCuadre {
  final String etiqueta;
  final int sistema;
  final int declarado;
  final bool esMoneda;
  const _LineaCuadre(this.etiqueta, this.sistema, this.declarado, {this.esMoneda = false});
  int get diferencia => declarado - sistema;
}

class _Encabezado extends StatelessWidget {
  final String nombreChofer;
  final bool bloqueada;
  final VoidCallback onCerrar;

  const _Encabezado({required this.nombreChofer, required this.bloqueada, required this.onCerrar});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
      child: Row(
        children: [
          const Icon(Icons.fact_check_outlined, size: 22, color: AppColors.steelBlue),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cuadre de Rendición', style: AppTextStyles.title.copyWith(fontSize: 18)),
                const SizedBox(height: 2),
                Text(nombreChofer, style: AppTextStyles.link.copyWith(fontSize: 13)),
              ],
            ),
          ),
          _EstadoChip(bloqueada: bloqueada),
          IconButton(
            onPressed: onCerrar,
            icon: const Icon(Icons.close, color: AppColors.graphiteGray),
          ),
        ],
      ),
    );
  }
}

class _EstadoChip extends StatelessWidget {
  final bool bloqueada;
  const _EstadoChip({required this.bloqueada});

  @override
  Widget build(BuildContext context) {
    final color = bloqueada ? AppColors.badgeGreen : AppColors.badgeAmber;
    final texto = bloqueada ? 'Ruta cerrada' : 'Pendiente';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        texto,
        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: color),
      ),
    );
  }
}

class _SeccionPlegableCuadre extends StatefulWidget {
  final IconData icono;
  final String titulo;
  final Widget? trailing;
  final Widget child;

  const _SeccionPlegableCuadre({
    required this.icono,
    required this.titulo,
    required this.child,
    this.trailing,
  });

  @override
  State<_SeccionPlegableCuadre> createState() => _SeccionPlegableCuadreState();
}

class _SeccionPlegableCuadreState extends State<_SeccionPlegableCuadre> {
  bool _abierta = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => _abierta = !_abierta),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(widget.icono, size: 18, color: AppColors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(widget.titulo, style: AppTextStyles.label.copyWith(fontSize: 15)),
                  ),
                  if (widget.trailing != null) ...[
                    widget.trailing!,
                    const SizedBox(width: 8),
                  ],
                  AnimatedRotation(
                    turns: _abierta ? 0.5 : 0,
                    duration: const Duration(milliseconds: 160),
                    child: const Icon(Icons.keyboard_arrow_down, color: AppColors.graphiteGray),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 160),
            crossFadeState: _abierta ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            firstChild: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: widget.child,
            ),
            secondChild: const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _BadgeEstado extends StatelessWidget {
  final bool cuadra;
  const _BadgeEstado({required this.cuadra});

  @override
  Widget build(BuildContext context) {
    final color = cuadra ? AppColors.badgeGreen : AppColors.badgeRed;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(cuadra ? Icons.check_circle : Icons.error_outline, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            cuadra ? 'OK' : 'Descalce',
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }
}

class _TablaCuadre extends StatelessWidget {
  final List<_LineaCuadre> lineas;
  final int totalSistema;
  final int totalDeclarado;
  final bool esMoneda;

  const _TablaCuadre({
    required this.lineas,
    required this.totalSistema,
    required this.totalDeclarado,
    required this.esMoneda,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        children: [
          const _EncabezadoTabla(),
          for (final l in lineas) ...[
            const Divider(height: 1, color: AppColors.inputBorder),
            _FilaComparativa(
              concepto: l.etiqueta,
              sistema: l.sistema,
              declarado: l.declarado,
              diferencia: l.diferencia,
              esMoneda: esMoneda,
            ),
          ],
          const Divider(height: 1, color: AppColors.inputBorder),
          _FilaComparativa(
            concepto: 'Total',
            sistema: totalSistema,
            declarado: totalDeclarado,
            diferencia: totalDeclarado - totalSistema,
            esMoneda: esMoneda,
            destacado: true,
          ),
        ],
      ),
    );
  }
}

class _EncabezadoTabla extends StatelessWidget {
  const _EncabezadoTabla();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: const [
          Expanded(flex: 4, child: _CeldaHeader('CONCEPTO')),
          Expanded(flex: 3, child: _CeldaHeader('SISTEMA', alinearFinal: true)),
          Expanded(flex: 3, child: _CeldaHeader('DECLARADO', alinearFinal: true)),
          Expanded(flex: 3, child: _CeldaHeader('DIFERENCIA', alinearFinal: true)),
        ],
      ),
    );
  }
}

class _CeldaHeader extends StatelessWidget {
  final String texto;
  final bool alinearFinal;
  const _CeldaHeader(this.texto, {this.alinearFinal = false});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alinearFinal ? Alignment.centerRight : Alignment.centerLeft,
      child: Text(
        texto,
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: AppColors.graphiteGray,
        ),
      ),
    );
  }
}

class _FilaComparativa extends StatelessWidget {
  final String concepto;
  final int sistema;
  final int declarado;
  final int diferencia;
  final bool esMoneda;
  final bool destacado;

  const _FilaComparativa({
    required this.concepto,
    required this.sistema,
    required this.declarado,
    required this.diferencia,
    required this.esMoneda,
    this.destacado = false,
  });

  String _fmt(int v) => esMoneda ? formatMoneda(v) : '$v';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              concepto,
              style: destacado
                  ? AppTextStyles.label.copyWith(fontSize: 13.5)
                  : AppTextStyles.input.copyWith(fontSize: 13),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(_fmt(sistema),
                textAlign: TextAlign.right,
                style: AppTextStyles.input.copyWith(fontSize: 13)),
          ),
          Expanded(
            flex: 3,
            child: Text(_fmt(declarado),
                textAlign: TextAlign.right,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.steelBlue)),
          ),
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.centerRight,
              child: _BadgeDif(diferencia: diferencia, esMoneda: esMoneda),
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeDif extends StatelessWidget {
  final int diferencia;
  final bool esMoneda;
  const _BadgeDif({required this.diferencia, required this.esMoneda});

  @override
  Widget build(BuildContext context) {
    final cuadra = diferencia == 0;
    final color = cuadra ? AppColors.badgeGreen : AppColors.badgeRed;
    final signo = diferencia > 0 ? '+' : (diferencia < 0 ? '−' : '');
    final valor = esMoneda ? formatMoneda(diferencia.abs()) : '${diferencia.abs()}';
    final texto = cuadra ? 'OK' : '$signo$valor';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(cuadra ? Icons.check_circle : Icons.error_outline, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            texto,
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }
}

class _BloqueEnvase extends StatefulWidget {
  final CuadreEnvaseLinea linea;
  const _BloqueEnvase({required this.linea});

  @override
  State<_BloqueEnvase> createState() => _BloqueEnvaseState();
}

class _BloqueEnvaseState extends State<_BloqueEnvase> {
  bool _abierta = false;

  @override
  Widget build(BuildContext context) {
    final linea = widget.linea;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: linea.cuadra ? AppColors.inputBorder : AppColors.badgeRed.withOpacity(0.5),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => _abierta = !_abierta),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Row(
                children: [
                  const Icon(Icons.propane_tank_rounded, size: 17, color: AppColors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Garrafa ${linea.etiqueta}',
                        style: AppTextStyles.label.copyWith(fontSize: 13.5)),
                  ),
                  _BadgeEstado(cuadra: linea.cuadra),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _abierta ? 0.5 : 0,
                    duration: const Duration(milliseconds: 160),
                    child: const Icon(Icons.keyboard_arrow_down, size: 20, color: AppColors.graphiteGray),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 160),
            crossFadeState: _abierta ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            firstChild: Column(
              children: [
                const Divider(height: 1, color: AppColors.inputBorder),
                const _EncabezadoTabla(),
                const Divider(height: 1, color: AppColors.inputBorder),
                _FilaComparativa(
                  concepto: 'Llenas',
                  sistema: linea.llenosSistema,
                  declarado: linea.llenosDeclarado,
                  diferencia: linea.difLlenos,
                  esMoneda: false,
                ),
                const Divider(height: 1, color: AppColors.inputBorder),
                _FilaComparativa(
                  concepto: 'Vacías',
                  sistema: linea.vaciosSistema,
                  declarado: linea.vaciosDeclarado,
                  diferencia: linea.difVacios,
                  esMoneda: false,
                ),
                if (linea.averiadosDeclarado > 0)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text('Dañadas / canjeadas',
                              style: AppTextStyles.input.copyWith(fontSize: 13)),
                        ),
                        Text('${linea.averiadosDeclarado}',
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.steelBlue)),
                      ],
                    ),
                  ),
              ],
            ),
            secondChild: const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _PanelAcciones extends StatelessWidget {
  final bool aprobando;
  final bool procesandoAjuste;
  final bool aprobarHabilitado;
  final VoidCallback onAprobar;
  final VoidCallback onAjuste;

  const _PanelAcciones({
    required this.aprobando,
    required this.procesandoAjuste,
    this.aprobarHabilitado = true,
    required this.onAprobar,
    required this.onAjuste,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: procesandoAjuste ? null : onAjuste,
            icon: procesandoAjuste
                ? const SizedBox(
                    height: 16, width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2.2, color: AppColors.steelBlue))
                : const Icon(Icons.edit_note_outlined, size: 20),
            label: const Text('Registrar Ajuste / Observación'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.steelBlue,
              side: const BorderSide(color: AppColors.steelBlue),
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: (aprobando || !aprobarHabilitado) ? null : onAprobar,
            icon: aprobando
                ? const SizedBox(
                    height: 16, width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2.2, color: AppColors.white))
                : const Icon(Icons.verified_outlined, size: 20),
            label: const Text('Aprobar Conciliación'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.badgeGreen,
              foregroundColor: AppColors.white,
              disabledBackgroundColor: AppColors.badgeGreen.withOpacity(0.35),
              disabledForegroundColor: AppColors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }
}

class _RutaCerradaAviso extends StatelessWidget {
  const _RutaCerradaAviso();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.badgeGreen.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.badgeGreen.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline, size: 18, color: AppColors.badgeGreen),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Conciliación aprobada. La ruta del chofer quedó cerrada y bloqueada.',
              style: AppTextStyles.link.copyWith(fontSize: 12.5, color: AppColors.graphiteGray),
            ),
          ),
        ],
      ),
    );
  }
}

class _BloqueosAviso extends StatelessWidget {
  final List<String> bloqueos;
  const _BloqueosAviso({required this.bloqueos});

  @override
  Widget build(BuildContext context) {
    final mensajes = <String>[
      for (final b in bloqueos)
        if (traducirBloqueoCuadre(b).trim().isNotEmpty) traducirBloqueoCuadre(b),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.badgeAmber.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.badgeAmber.withOpacity(0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.report_gmailerrorred_outlined, size: 18, color: AppColors.badgeAmber),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Todavía no se puede aprobar la conciliación. Resolvé estos puntos:',
                  style: AppTextStyles.link.copyWith(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.graphiteGray,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final m in mensajes) ...[
            Padding(
              padding: const EdgeInsets.only(left: 28, bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(Icons.fiber_manual_record, size: 7, color: AppColors.badgeAmber),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      m,
                      style: AppTextStyles.footer.copyWith(color: AppColors.graphiteGray),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DiferenciasAviso extends StatelessWidget {
  final List<String> bloqueos;
  const _DiferenciasAviso({required this.bloqueos});

  @override
  Widget build(BuildContext context) {
    final mensajes = <String>[
      for (final b in bloqueos)
        if (traducirBloqueoCuadre(b).trim().isNotEmpty) traducirBloqueoCuadre(b),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.steelBlue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.steelBlue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, size: 18, color: AppColors.steelBlue),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Diferencias sin ajustar. Podés aprobar igual: quedan registradas.',
                  style: AppTextStyles.link.copyWith(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.graphiteGray,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final m in mensajes) ...[
            Padding(
              padding: const EdgeInsets.only(left: 28, bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(Icons.fiber_manual_record, size: 7, color: AppColors.steelBlue),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      m,
                      style: AppTextStyles.footer.copyWith(color: AppColors.graphiteGray),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Icon(esEjemplo ? Icons.info_outline : Icons.error_outline, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(mensaje,
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: color)),
          ),
        ],
      ),
    );
  }
}

class _AjusteResult {
  final String observacion;
  final int? monto;
  final int? garrafas;
  const _AjusteResult({required this.observacion, this.monto, this.garrafas});
}

class _AjusteDialog extends StatefulWidget {
  const _AjusteDialog();

  @override
  State<_AjusteDialog> createState() => _AjusteDialogState();
}

class _AjusteDialogState extends State<_AjusteDialog> {
  final _observacion = TextEditingController();
  final _monto = TextEditingController();
  final _garrafas = TextEditingController();

  @override
  void dispose() {
    _observacion.dispose();
    _monto.dispose();
    _garrafas.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final valido = _observacion.text.trim().isNotEmpty;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Registrar ajuste / observación', style: AppTextStyles.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Dejá registrado el motivo del descalce y, si corresponde, un ajuste de dinero o de garrafas.',
              style: AppTextStyles.link.copyWith(fontSize: 12.5),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _observacion,
              maxLines: 3,
              onChanged: (_) => setState(() {}),
              cursorColor: AppColors.orange,
              decoration: const InputDecoration(
                labelText: 'Observación',
                isDense: true,
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.inputBorder)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.orange)),
                floatingLabelStyle: TextStyle(color: AppColors.orange),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _monto,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    cursorColor: AppColors.orange,
                    decoration: const InputDecoration(
                      labelText: 'Ajuste \$',
                      isDense: true,
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.inputBorder)),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.orange)),
                      floatingLabelStyle: TextStyle(color: AppColors.orange),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _garrafas,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    cursorColor: AppColors.orange,
                    decoration: const InputDecoration(
                      labelText: 'Ajuste garrafas',
                      isDense: true,
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.inputBorder)),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.orange)),
                      floatingLabelStyle: TextStyle(color: AppColors.orange),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancelar', style: AppTextStyles.button.copyWith(color: AppColors.graphiteGray)),
        ),
        TextButton(
          onPressed: valido
              ? () => Navigator.of(context).pop(_AjusteResult(
                    observacion: _observacion.text.trim(),
                    monto: int.tryParse(_monto.text.trim()),
                    garrafas: int.tryParse(_garrafas.text.trim()),
                  ))
              : null,
          child: Text('Registrar',
              style: AppTextStyles.button.copyWith(
                  color: valido ? AppColors.orange : AppColors.badgeGray)),
        ),
      ],
    );
  }
}
