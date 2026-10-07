import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/responsive.dart';
import '../../data/mock_cobranza_data.dart';
import '../../models/cuenta_corriente_resumen.dart';
import '../../models/vista_cuentas_corrientes.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/catalogo_repository.dart';
import '../../repositories/cobranza_repository.dart';
import '../../repositories/network_exception.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/formato.dart';
import '../../widgets/admin/cobranza/cuentas_corrientes_tabla.dart';
import '../../widgets/admin/cobranza/editar_limite_dialog.dart';
import '../../widgets/admin/cobranza/limites_credito_card.dart';
import '../../widgets/admin/cobranza/vista_cuentas_selector.dart';
import '../../widgets/admin/flota/flota_form_controls.dart';
import '../../widgets/admin/flota/flota_stat_card.dart';
import '../../widgets/common/aviso_regla_cuenta_corriente.dart';
import '../../widgets/common/carga/zona_carga.dart';
import '../../widgets/common/filtros/filtros.dart';
import '../../core/feedback/app_feedback.dart';

class CuentasCorrientesScreen extends StatefulWidget {
  const CuentasCorrientesScreen({super.key});

  @override
  State<CuentasCorrientesScreen> createState() => _CuentasCorrientesScreenState();
}

class _CuentasCorrientesScreenState extends State<CuentasCorrientesScreen> {
  late final CobranzaRepository _repo;
  late final CatalogoRepository _catalogoRepo;
  final _searchCtrl = TextEditingController();
  List<OpcionFiltro>? _catalogoClientes;
  bool _guardandoLimite = false;

  ReporteCuentasCorrientes _reporte = const ReporteCuentasCorrientes();
  bool _loading = true;
  bool _modoEjemplo = false;
  VistaCuentasCorrientes _vista = VistaCuentasCorrientes.cobranzas;
  final Map<VistaCuentasCorrientes, int?> _contadores = {};
  String? _aviso;

  @override
  void initState() {
    super.initState();
    final client = context.read<AuthProvider>().apiClient;
    _repo = CobranzaRepository(client);
    _catalogoRepo = CatalogoRepository(client);
    _searchCtrl.addListener(() => setState(() {}));
    _cargar();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() {
      _loading = true;
      _aviso = null;
    });
    try {
      final vista = _vista;
      final reporte = await _repo.getReporteCuentasCorrientes(
        soloMorosos: vista.soloMorosos,
        soloDeudores: vista.soloDeudores,
      );
      if (!mounted || vista != _vista) return;
      setState(() {
        _reporte = reporte;
        _contadores[VistaCuentasCorrientes.cobranzas] = reporte.clientesConDeuda;
        _contadores[VistaCuentasCorrientes.morosos] = reporte.clientesMorosos;
        if (vista == VistaCuentasCorrientes.todas) {
          _contadores[VistaCuentasCorrientes.todas] = reporte.totalClientes;
        }
        _modoEjemplo = false;
        _loading = false;
      });
    } on NetworkException {
      _usarEjemplo('No se pudo conectar con el servidor: mostrando datos de ejemplo.');
    } on CobranzaRepositoryException catch (e) {
      if (e.endpointNoDisponible) {
        _usarEjemplo('El reporte de cuentas corrientes aún no está en el backend: mostrando datos de ejemplo.');
      } else {
        _usarEjemplo(e.message);
      }
    } catch (_) {
      _usarEjemplo('Ocurrió un problema al cargar el reporte: mostrando datos de ejemplo.');
    }
  }

  void _usarEjemplo(String mensaje) {
    if (!mounted) return;
    setState(() {
      _reporte = reporteCuentasDeEjemplo();
      _modoEjemplo = true;
      _aviso = mensaje;
      _loading = false;
    });
  }

  List<CuentaCorrienteResumen> get _clientesFiltrados {
    final query = _searchCtrl.text.trim().toLowerCase();
    return _reporte.clientes.where((c) {
      if (_vista.soloMorosos && !c.moroso) return false;
      if (_vista.soloDeudores && c.saldoUsado <= 0) return false;
      if (query.isNotEmpty && !c.nombreCliente.toLowerCase().contains(query)) return false;
      return true;
    }).toList();
  }

  void _verDetalle(CuentaCorrienteResumen cliente) {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Detalle de ${cliente.nombreMostrado}',
      barrierColor: Colors.black.withValues(alpha: 0.35),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (_, __, ___) => Align(
        alignment: Alignment.centerRight,
        child: _DetallePanel(
          cliente: cliente,
          onRegistrarPago: () => _registrarPago(cliente, desdeDetalle: true),
          onEditarLimite: () {
            Navigator.of(context).pop();
            _editarLimite(cliente);
          },
        ),
      ),
      transitionBuilder: (_, animacion, __, child) {
        final curva = CurvedAnimation(parent: animacion, curve: Curves.easeOutCubic);
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(curva),
          child: child,
        );
      },
    );
  }

  void _cambiarVista(VistaCuentasCorrientes vista) {
    if (vista == _vista) return;
    setState(() => _vista = vista);
    _cargar();
  }

  Future<void> _registrarPago(CuentaCorrienteResumen cliente, {bool desdeDetalle = false}) async {
    if (_modoEjemplo) {
      _snack('En modo de ejemplo no se pueden registrar pagos.', error: true);
      return;
    }
    final datos = await showDialog<_DatosPago>(
      context: context,
      builder: (_) => _RegistrarPagoDialog(cliente: cliente),
    );
    if (datos == null || !mounted) return;
    try {
      await _repo.registrarPagoCuentaCorriente(
        idCliente: cliente.idCliente,
        monto: datos.monto,
        referencia: datos.referencia,
        observacion: datos.observacion,
        fechaPago: datos.fechaPago,
        uuidOperacion: datos.uuidOperacion,
      );
      if (!mounted) return;
      if (desdeDetalle) Navigator.of(context).pop();
      _snack('Pago registrado. Saldo actualizado.');
      await _cargar();
    } on NetworkException {
      if (!mounted) return;
      _snack('Sin conexión: no se pudo registrar el pago.', error: true);
    } on CobranzaRepositoryException catch (e) {
      if (!mounted) return;
      _snack(e.message, error: true);
    } catch (_) {
      if (!mounted) return;
      _snack('No se pudo registrar el pago.', error: true);
    }
  }

  Future<List<OpcionFiltro>> _obtenerCatalogo() async {
    final cache = _catalogoClientes;
    if (cache != null) return cache;
    try {
      final clientes = await _catalogoRepo.listarClientes();
      final vistos = <int>{};
      final opciones = <OpcionFiltro>[];
      for (final c in clientes) {
        final id = c.idClienteExt;
        if (id == null || !vistos.add(id)) continue;
        final nombre = c.nombre.trim().isEmpty ? 'Cliente #$id' : c.nombre.trim();
        opciones.add(OpcionFiltro('$id', nombre));
      }
      opciones.sort((a, b) => a.etiqueta.toLowerCase().compareTo(b.etiqueta.toLowerCase()));
      _catalogoClientes = opciones;
      return opciones;
    } catch (_) {
      return const [];
    }
  }

  Future<void> _editarLimite([CuentaCorrienteResumen? cliente]) async {
    if (_modoEjemplo) {
      _snack('En modo de ejemplo no se pueden editar límites.', error: true);
      return;
    }
    if (_guardandoLimite) return;
    var catalogo = const <OpcionFiltro>[];
    if (cliente == null) {
      setState(() => _guardandoLimite = true);
      catalogo = await _obtenerCatalogo();
      if (!mounted) return;
      setState(() => _guardandoLimite = false);
    }
    final elegido = await EditarLimiteDialog.mostrar(
      context,
      cliente: cliente,
      clientesCatalogo: catalogo,
      cuentasExistentes: {for (final c in _reporte.clientes) c.idCliente: c},
    );
    if (elegido == null || !mounted) return;
    setState(() => _guardandoLimite = true);
    try {
      await _repo.configurarLimiteCuentaCorriente(
        idCliente: elegido.idCliente,
        limiteCredito: elegido.limiteCredito,
      );
      if (!mounted) return;
      setState(() => _guardandoLimite = false);
      _snack('Límite de ${elegido.nombreCliente.isEmpty ? 'el cliente' : elegido.nombreCliente} actualizado a ${formatMoneda(elegido.limiteCredito)}.');
      await _cargar();
    } on NetworkException {
      if (!mounted) return;
      setState(() => _guardandoLimite = false);
      _snack('Sin conexión: no se pudo guardar el límite.', error: true);
    } on CobranzaRepositoryException catch (e) {
      if (!mounted) return;
      setState(() => _guardandoLimite = false);
      _snack(e.message, error: true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _guardandoLimite = false);
      _snack('No se pudo guardar el límite.', error: true);
    }
  }

  String get _mensajeVacioVista {
    switch (_vista) {
      case VistaCuentasCorrientes.cobranzas:
        return 'No hay clientes con saldo pendiente para cobrar.';
      case VistaCuentasCorrientes.morosos:
        return 'No hay clientes morosos.';
      case VistaCuentasCorrientes.todas:
        return 'No hay clientes con cuenta corriente.';
    }
  }

  void _snack(String mensaje, {bool error = false}) {
    if (error) {
      AppFeedback.error(mensaje);
    } else {
      AppFeedback.exito(mensaje);
    }
  }

  void _generarPdf() {
    AppFeedback.advertencia('Exportación a PDF: pendiente de habilitar en el backend.');
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
              ReportarCarga(cargando: _loading || _guardandoLimite),
              _Cabecera(onPdf: _generarPdf),
              const SizedBox(height: 20),
              _Stats(reporte: _reporte),
              const SizedBox(height: 12),
              const AvisoReglaCuentaCorriente(),
              const SizedBox(height: 16),
              LimitesCreditoCard(
                clientes: _reporte.clientes,
                cargando: _loading || _guardandoLimite,
                mostrarIndicadores: _vista == VistaCuentasCorrientes.todas,
                onAsignar: () => _editarLimite(),
                onEditar: _editarLimite,
              ),
              const SizedBox(height: 16),
              _Filtros(
                searchCtrl: _searchCtrl,
                vista: _vista,
                contadores: _contadores,
                onVista: _cambiarVista,
                onLimpiar: _searchCtrl.clear,
                onRefrescar: _cargar,
                cargando: _loading,
              ),
              if (_aviso != null) ...[
                const SizedBox(height: 16),
                _AvisoBanner(mensaje: _aviso!, esEjemplo: _modoEjemplo),
              ],
              const SizedBox(height: 20),
              _TarjetaTabla(
                cantidad: _clientesFiltrados.length,
                child: _loading
                    ? const SizedBox(height: 160)
                    : CuentasCorrientesTabla(
                        clientes: _clientesFiltrados,
                        onVerDetalle: _verDetalle,
                        onEditarLimite: _editarLimite,
                        onRegistrarPago: _registrarPago,
                        mensajeVacio: _reporte.clientes.isEmpty
                            ? _mensajeVacioVista
                            : 'No hay clientes que coincidan con los filtros.',
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
  final VoidCallback onPdf;

  const _Cabecera({required this.onPdf});

  @override
  Widget build(BuildContext context) {
    final movil = Responsive.isMobileContext(context);
    final titulos = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reporte de Cuentas Corrientes',
          style: movil ? AppTextStyles.desktopTitle.copyWith(fontSize: 22) : AppTextStyles.desktopTitle,
        ),
        const SizedBox(height: 4),
        Text(
          'Saldos y deuda pendiente por cliente comercial.',
          style: AppTextStyles.desktopSubtitle,
        ),
      ],
    );
    final boton = FlotaBotonPrimario(
      texto: 'Generar Reporte PDF',
      icono: Icons.picture_as_pdf_outlined,
      onTap: onPdf,
    );
    if (movil) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          titulos,
          const SizedBox(height: 14),
          boton,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: titulos),
        const SizedBox(width: 16),
        SizedBox(width: 190, child: boton),
      ],
    );
  }
}

class _Stats extends StatelessWidget {
  final ReporteCuentasCorrientes reporte;

  const _Stats({required this.reporte});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fila = constraints.maxWidth >= 720;
        final cards = [
          FlotaStatCard(
            icon: Icons.account_balance_wallet_outlined,
            etiqueta: 'Total Deuda Clientes',
            valor: formatMoneda(reporte.totalDeuda),
            acento: AppColors.orange,
          ),
          FlotaStatCard(
            icon: Icons.payments_outlined,
            etiqueta: 'Clientes con Deuda',
            valor: '${reporte.clientesConDeuda}',
            acento: AppColors.steelBlue,
          ),
          FlotaStatCard(
            icon: Icons.person_off_outlined,
            etiqueta: 'Clientes Morosos',
            valor: '${reporte.clientesMorosos}',
            acento: AppColors.error,
          ),
        ];
        if (fila) {
          return Row(
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                if (i > 0) const SizedBox(width: 16),
                Expanded(child: cards[i]),
              ],
            ],
          );
        }
        return Column(
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              cards[i],
            ],
          ],
        );
      },
    );
  }
}

class _Filtros extends StatelessWidget {
  final TextEditingController searchCtrl;
  final VistaCuentasCorrientes vista;
  final Map<VistaCuentasCorrientes, int?> contadores;
  final ValueChanged<VistaCuentasCorrientes> onVista;
  final VoidCallback onLimpiar;
  final VoidCallback onRefrescar;
  final bool cargando;

  const _Filtros({
    required this.searchCtrl,
    required this.vista,
    required this.contadores,
    required this.onVista,
    required this.onLimpiar,
    required this.onRefrescar,
    required this.cargando,
  });

  @override
  Widget build(BuildContext context) {
    final hayFiltros = searchCtrl.text.trim().isNotEmpty;
    return FiltrosPanel(
      filas: [
        VistaCuentasSelector(
          seleccion: vista,
          contadores: contadores,
          habilitado: !cargando,
          onCambio: onVista,
        ),
        FilaFiltros(
          children: [
            CampoBusquedaFiltro(
              controller: searchCtrl,
              etiqueta: 'Cliente',
              hint: 'Buscar cliente',
            ),
            if (hayFiltros) BotonLimpiarFiltros(onPressed: onLimpiar),
            BotonActualizar(onPressed: onRefrescar, cargando: cargando),
          ],
        ),
      ],
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
            padding: Responsive.isMobileContext(context)
                ? const EdgeInsets.fromLTRB(16, 16, 16, 12)
                : const EdgeInsets.fromLTRB(20, 18, 20, 14),
            child: Row(
              children: [
                const Text('Clientes', style: AppTextStyles.label),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.steelBlue.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$cantidad',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.steelBlue),
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

class _DetallePanel extends StatelessWidget {
  final CuentaCorrienteResumen cliente;
  final VoidCallback? onRegistrarPago;
  final VoidCallback? onEditarLimite;

  const _DetallePanel({required this.cliente, this.onRegistrarPago, this.onEditarLimite});

  @override
  Widget build(BuildContext context) {
    final disponible = cliente.limiteCredito - cliente.saldoUsado;
    final anchoPantalla = MediaQuery.of(context).size.width;
    final completo = anchoPantalla < 480;
    final ancho = completo
        ? anchoPantalla
        : (anchoPantalla * 0.34).clamp(360.0, 460.0);
    return Material(
      color: Colors.transparent,
      child: Container(
        width: ancho.toDouble(),
        height: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: completo ? null : const BorderRadius.horizontal(left: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Padding(
            padding: completo
                ? const EdgeInsets.fromLTRB(16, 12, 8, 16)
                : const EdgeInsets.fromLTRB(24, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          cliente.nombreMostrado,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.title.copyWith(fontSize: 20),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.graphiteGray),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Cerrar',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _LineaDetalle(etiqueta: 'Límite de crédito', valor: formatMoneda(cliente.limiteCredito)),
                _LineaDetalle(etiqueta: 'Saldo usado', valor: formatMoneda(cliente.saldoUsado)),
                _LineaDetalle(
                  etiqueta: 'Disponible',
                  valor: formatMoneda(disponible),
                  acento: disponible < 0 ? AppColors.error : AppColors.badgeGreen,
                ),
                _LineaDetalle(
                  etiqueta: 'Vencido',
                  valor: cliente.tieneVencido ? formatMoneda(cliente.montoVencido) : '—',
                  acento: cliente.tieneVencido ? AppColors.error : null,
                ),
                const Spacer(),
                if (onEditarLimite != null) ...[
                  FlotaBotonSecundario(
                    texto: 'Editar límite',
                    onTap: onEditarLimite,
                  ),
                  const SizedBox(height: 10),
                ],
                if (onRegistrarPago != null && cliente.saldoUsado > 0)
                  FlotaBotonPrimario(
                    texto: 'Registrar pago',
                    icono: Icons.payments_outlined,
                    onTap: onRegistrarPago,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LineaDetalle extends StatelessWidget {
  final String etiqueta;
  final String valor;
  final Color? acento;

  const _LineaDetalle({required this.etiqueta, required this.valor, this.acento});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(etiqueta, style: AppTextStyles.link.copyWith(fontSize: 13.5))),
          const SizedBox(width: 8),
          Text(
            valor,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: acento ?? AppColors.steelBlue,
            ),
          ),
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
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
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

class _DatosPago {
  final int monto;
  final String? referencia;
  final String? observacion;
  final DateTime fechaPago;
  final String uuidOperacion;

  const _DatosPago({
    required this.monto,
    required this.fechaPago,
    required this.uuidOperacion,
    this.referencia,
    this.observacion,
  });
}

class _RegistrarPagoDialog extends StatefulWidget {
  final CuentaCorrienteResumen cliente;

  const _RegistrarPagoDialog({required this.cliente});

  @override
  State<_RegistrarPagoDialog> createState() => _RegistrarPagoDialogState();
}

class _RegistrarPagoDialogState extends State<_RegistrarPagoDialog> {
  late final TextEditingController _monto;
  final _referencia = TextEditingController();
  final String _uuidOperacion = const Uuid().v4();
  final _observacion = TextEditingController();

  @override
  void initState() {
    super.initState();
    _monto = TextEditingController(
      text: widget.cliente.saldoUsado > 0 ? '${widget.cliente.saldoUsado}' : '',
    );
  }

  @override
  void dispose() {
    _monto.dispose();
    _referencia.dispose();
    _observacion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deuda = widget.cliente.saldoUsado;
    final monto = int.tryParse(_monto.text.trim()) ?? 0;
    final excede = monto > deuda;
    final valido = monto > 0 && !excede;
    final movil = Responsive.isMobileContext(context);
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: movil
          ? const EdgeInsets.symmetric(horizontal: 16, vertical: 24)
          : const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      titlePadding: movil ? const EdgeInsets.fromLTRB(16, 20, 16, 0) : null,
      contentPadding: movil ? const EdgeInsets.fromLTRB(16, 16, 16, 12) : null,
      title: Text(
        'Registrar pago',
        style: movil ? AppTextStyles.title.copyWith(fontSize: 19) : AppTextStyles.title,
      ),
      content: SizedBox(
        width: movil ? MediaQuery.sizeOf(context).width - 64 : null,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.cliente.nombreMostrado,
                style: AppTextStyles.label.copyWith(fontSize: 15),
              ),
              const SizedBox(height: 4),
              Text(
                'Deuda actual: ${formatMoneda(deuda)}',
                style: AppTextStyles.link.copyWith(fontSize: 12.5, color: AppColors.graphiteGray),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _monto,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => setState(() {}),
                cursorColor: AppColors.orange,
                style: AppTextStyles.title.copyWith(fontSize: 22),
                decoration: InputDecoration(
                  labelText: 'Monto del pago',
                  prefixText: '\$ ',
                  isDense: true,
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.inputBorder),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.orange),
                  ),
                  floatingLabelStyle: const TextStyle(color: AppColors.orange),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                excede
                    ? 'No puede superar la deuda (${formatMoneda(deuda)}).'
                    : 'Se descuenta del saldo del cliente.',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: excede ? AppColors.error : AppColors.graphiteGray,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _referencia,
                maxLength: 255,
                cursorColor: AppColors.orange,
                decoration: const InputDecoration(
                  labelText: 'Referencia (opcional)',
                  hintText: 'Ej: transferencia #1234',
                  isDense: true,
                  counterText: '',
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.inputBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.orange),
                  ),
                  floatingLabelStyle: TextStyle(color: AppColors.orange),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _observacion,
                maxLines: 2,
                maxLength: 2000,
                cursorColor: AppColors.orange,
                decoration: const InputDecoration(
                  labelText: 'Observación (opcional)',
                  isDense: true,
                  counterText: '',
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.inputBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.orange),
                  ),
                  floatingLabelStyle: TextStyle(color: AppColors.orange),
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
          onPressed: valido
              ? () => Navigator.of(context).pop(_DatosPago(
                    monto: monto,
                    fechaPago: DateTime.now(),
                    uuidOperacion: _uuidOperacion,
                    referencia: _referencia.text,
                    observacion: _observacion.text,
                  ))
              : null,
          child: Text(
            'Registrar pago',
            style: AppTextStyles.button.copyWith(
              color: valido ? AppColors.orange : AppColors.badgeGray,
            ),
          ),
        ),
      ],
    );
  }
}
