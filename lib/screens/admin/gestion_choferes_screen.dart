import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/feedback/app_feedback.dart';
import '../../core/responsive.dart';
import '../../models/chofer_cuenta.dart';
import '../../models/chofer_externo.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/gestion_choferes_repository.dart';
import '../../repositories/network_exception.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/admin/choferes/chofer_cuenta_dialog.dart';
import '../../widgets/admin/choferes/choferes_lista.dart';
import '../../widgets/admin/flota/flota_stat_card.dart';
import '../../widgets/common/carga/zona_carga.dart';
import '../../widgets/common/filtros/filtros.dart';

class GestionChoferesScreen extends StatefulWidget {
  const GestionChoferesScreen({super.key});

  @override
  State<GestionChoferesScreen> createState() => _GestionChoferesScreenState();
}

class _GestionChoferesScreenState extends State<GestionChoferesScreen> {
  late final GestionChoferesRepository _repo;
  final _busqueda = TextEditingController();

  List<ChoferCuenta> _cuentas = const [];
  List<ChoferExterno> _externos = const [];
  bool _cargando = true;
  bool _guardando = false;
  String? _error;
  String? _avisoExternos;

  @override
  void initState() {
    super.initState();
    _repo = GestionChoferesRepository(context.read<AuthProvider>().apiClient);
    _busqueda.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _cargar();
    });
  }

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    String? avisoExternos;
    final externosFuture = _repo.listarExternos().catchError((Object e) {
      avisoExternos = e is GestionChoferesException && e.endpointNoDisponible
          ? 'El backend todavía no expone la lista de choferes de la API.'
          : 'No se pudo cargar la lista de choferes de la API.';
      return <ChoferExterno>[];
    });
    try {
      final cuentas = await _repo.listarCuentas();
      final externos = await externosFuture;
      if (!mounted) return;
      cuentas.sort((a, b) => a.nombreMostrado.toLowerCase().compareTo(b.nombreMostrado.toLowerCase()));
      setState(() {
        _cuentas = cuentas;
        _externos = externos;
        _avisoExternos = avisoExternos;
        _cargando = false;
      });
    } on NetworkException {
      _fallo('Sin conexión: no se pudieron cargar los choferes.');
    } on GestionChoferesException catch (e) {
      _fallo(e.message);
    } catch (_) {
      _fallo('No se pudieron cargar los choferes.');
    }
  }

  void _fallo(String mensaje) {
    if (!mounted) return;
    setState(() {
      _error = mensaje;
      _cargando = false;
    });
  }

  List<ChoferExterno> get _disponibles {
    final idsAsignados = {
      for (final c in _cuentas)
        if (c.idChoferExterno != null) c.idChoferExterno!,
    };
    final nombresAsignados = {for (final c in _cuentas) normalizarNombreChofer(c.nombre)};
    final lista = _externos
        .where((e) =>
            !e.asignado &&
            !idsAsignados.contains(e.idChoferExterno) &&
            !nombresAsignados.contains(e.claveNombre))
        .toList()
      ..sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
    return lista;
  }

  List<ChoferCuenta> get _filtradas {
    final q = _busqueda.text.trim().toLowerCase();
    if (q.isEmpty) return _cuentas;
    return _cuentas
        .where((c) => c.nombre.toLowerCase().contains(q) || c.email.toLowerCase().contains(q))
        .toList();
  }

  Future<void> _crear() async {
    if (_guardando) return;
    final datos = await ChoferCuentaDialog.crear(
      context,
      disponibles: _disponibles,
      aviso: _avisoExternos,
    );
    final chofer = datos?.chofer;
    if (datos == null || chofer == null || !mounted) return;
    await _guardar(
      () => _repo.crear(email: datos.email, password: datos.password, chofer: chofer),
      'Cuenta creada para ${chofer.nombre}.',
    );
  }

  Future<void> _editar(ChoferCuenta cuenta) async {
    if (_guardando) return;
    final datos = await ChoferCuentaDialog.editar(context, cuenta);
    if (datos == null || !mounted) return;
    final cambiaEmail = datos.email.toLowerCase() != cuenta.email.trim().toLowerCase();
    await _guardar(
      () => _repo.editar(
        idUsuario: cuenta.idUsuario,
        email: cambiaEmail ? datos.email : null,
        password: datos.password.isEmpty ? null : datos.password,
      ),
      'Cuenta de ${cuenta.nombreMostrado} actualizada.',
    );
  }

  Future<void> _guardar(Future<Object?> Function() accion, String exito) async {
    setState(() => _guardando = true);
    try {
      await accion();
      if (!mounted) return;
      setState(() => _guardando = false);
      AppFeedback.exito(exito);
      await _cargar();
    } on NetworkException {
      if (!mounted) return;
      setState(() => _guardando = false);
      AppFeedback.error('Sin conexión: no se guardaron los cambios.');
    } on GestionChoferesException catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      AppFeedback.error(e.endpointNoDisponible
          ? 'Esta acción todavía no está disponible en el backend.'
          : e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _guardando = false);
      AppFeedback.error('No se pudieron guardar los cambios.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final movil = Responsive.isMobile(constraints);
        final padding = EdgeInsets.all(Responsive.isDesktop(constraints) ? 28 : 16);
        final filtradas = _filtradas;
        return SingleChildScrollView(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ReportarCarga(cargando: _cargando || _guardando),
              _Cabecera(
                movil: movil,
                habilitado: !_cargando && !_guardando,
                onNuevo: _crear,
              ),
              const SizedBox(height: 18),
              _Indicadores(
                cuentas: _cuentas.length,
                sinCuenta: _disponibles.length,
                externosDisponibles: _avisoExternos == null,
                movil: movil,
              ),
              const SizedBox(height: 18),
              FiltrosPanel(
                aviso: _avisoExternos,
                filas: [
                  FilaFiltros(
                    children: [
                      CampoBusquedaFiltro(
                        controller: _busqueda,
                        etiqueta: 'Buscar',
                        hint: 'Nombre o correo',
                        ancho: 320,
                      ),
                      if (_busqueda.text.trim().isNotEmpty)
                        BotonLimpiarFiltros(onPressed: _busqueda.clear),
                      BotonActualizar(onPressed: _cargar, cargando: _cargando),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.inputBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(movil ? 14 : 20, 16, movil ? 14 : 20, 12),
                      child: Row(
                        children: [
                          const Text('Choferes con cuenta', style: AppTextStyles.label),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.steelBlue.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${filtradas.length}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: AppColors.steelBlue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_cargando)
                      const SizedBox(height: 140)
                    else if (_error != null)
                      _ErrorCarga(mensaje: _error!, onReintentar: _cargar)
                    else
                      ChoferesLista(
                        cuentas: filtradas,
                        onEditar: _editar,
                        mensajeVacio: _cuentas.isEmpty
                            ? 'Todavía no hay choferes con cuenta. Creá la primera con "Nuevo chofer".'
                            : 'Ningún chofer coincide con la búsqueda.',
                      ),
                  ],
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
  final bool movil;
  final bool habilitado;
  final VoidCallback onNuevo;

  const _Cabecera({required this.movil, required this.habilitado, required this.onNuevo});

  @override
  Widget build(BuildContext context) {
    final textos = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gestión de Choferes',
          style: movil ? AppTextStyles.desktopTitle.copyWith(fontSize: 22) : AppTextStyles.desktopTitle,
        ),
        const SizedBox(height: 4),
        Text(
          'Cuentas de acceso a la app de los choferes que vienen de la API.',
          style: AppTextStyles.desktopSubtitle,
        ),
      ],
    );
    final boton = ElevatedButton.icon(
      onPressed: habilitado ? onNuevo : null,
      icon: const Icon(Icons.person_add_alt_1_outlined, size: 19),
      label: const Text('Nuevo chofer'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.orange,
        foregroundColor: AppColors.white,
        disabledBackgroundColor: AppColors.orange.withOpacity(0.4),
        disabledForegroundColor: AppColors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    if (movil) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [textos, const SizedBox(height: 14), boton],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: textos),
        const SizedBox(width: 16),
        boton,
      ],
    );
  }
}

class _Indicadores extends StatelessWidget {
  final int cuentas;
  final int sinCuenta;
  final bool externosDisponibles;
  final bool movil;

  const _Indicadores({
    required this.cuentas,
    required this.sinCuenta,
    required this.externosDisponibles,
    required this.movil,
  });

  @override
  Widget build(BuildContext context) {
    final tarjetas = [
      FlotaStatCard(
        icon: Icons.verified_user_outlined,
        etiqueta: 'Choferes con cuenta',
        valor: '$cuentas',
        acento: AppColors.steelBlue,
      ),
      FlotaStatCard(
        icon: Icons.person_add_alt_outlined,
        etiqueta: 'Choferes de la API sin cuenta',
        valor: externosDisponibles ? '$sinCuenta' : '—',
        acento: AppColors.orange,
      ),
    ];
    if (movil) {
      return Column(children: [tarjetas[0], const SizedBox(height: 12), tarjetas[1]]);
    }
    return Row(
      children: [
        Expanded(child: tarjetas[0]),
        const SizedBox(width: 16),
        Expanded(child: tarjetas[1]),
      ],
    );
  }
}

class _ErrorCarga extends StatelessWidget {
  final String mensaje;
  final VoidCallback onReintentar;

  const _ErrorCarga({required this.mensaje, required this.onReintentar});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_outlined, size: 40, color: AppColors.badgeGray),
          const SizedBox(height: 12),
          Text(mensaje, textAlign: TextAlign.center, style: AppTextStyles.input),
          const SizedBox(height: 14),
          OutlinedButton(
            onPressed: onReintentar,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.steelBlue,
              side: const BorderSide(color: AppColors.steelBlue),
            ),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
