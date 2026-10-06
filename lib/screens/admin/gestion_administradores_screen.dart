import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/feedback/app_feedback.dart';
import '../../core/responsive.dart';
import '../../models/administrador_cuenta.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/gestion_administradores_repository.dart';
import '../../repositories/network_exception.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/admin/administradores/administrador_dialog.dart';
import '../../widgets/admin/administradores/administradores_lista.dart';
import '../../widgets/admin/administradores/confirmar_baja_administrador_dialog.dart';
import '../../widgets/admin/flota/flota_stat_card.dart';
import '../../widgets/common/carga/zona_carga.dart';
import '../../widgets/common/filtros/filtros.dart';

class GestionAdministradoresScreen extends StatefulWidget {
  const GestionAdministradoresScreen({super.key});

  @override
  State<GestionAdministradoresScreen> createState() => _GestionAdministradoresScreenState();
}

class _GestionAdministradoresScreenState extends State<GestionAdministradoresScreen> {
  late final GestionAdministradoresRepository _repo;
  final _busqueda = TextEditingController();

  List<AdministradorCuenta> _cuentas = const [];
  String? _idPrincipal;
  bool _cargando = true;
  bool _guardando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repo = GestionAdministradoresRepository(context.read<AuthProvider>().apiClient);
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
    try {
      final cuentas = await _repo.listar();
      if (!mounted) return;
      final principal = idAdministradorPrincipal(cuentas);
      cuentas.sort((a, b) {
        if (a.id == principal) return -1;
        if (b.id == principal) return 1;
        return a.nombreMostrado.toLowerCase().compareTo(b.nombreMostrado.toLowerCase());
      });
      setState(() {
        _cuentas = cuentas;
        _idPrincipal = principal;
        _cargando = false;
      });
    } on NetworkException {
      _fallo('Sin conexión: no se pudieron cargar los administradores.');
    } on GestionAdministradoresException catch (e) {
      _fallo(e.message);
    } catch (_) {
      _fallo('No se pudieron cargar los administradores.');
    }
  }

  void _fallo(String mensaje) {
    if (!mounted) return;
    setState(() {
      _error = mensaje;
      _cargando = false;
    });
  }

  List<AdministradorCuenta> get _filtradas {
    final q = _busqueda.text.trim().toLowerCase();
    if (q.isEmpty) return _cuentas;
    return _cuentas
        .where((c) => c.nombre.toLowerCase().contains(q) || c.email.toLowerCase().contains(q))
        .toList();
  }

  AdministradorCuenta? get _principal {
    for (final c in _cuentas) {
      if (c.id == _idPrincipal) return c;
    }
    return null;
  }

  Future<void> _crear() async {
    if (_guardando) return;
    final datos = await AdministradorDialog.crear(context);
    if (datos == null || !mounted) return;
    await _ejecutar(
      () => _repo.crear(nombre: datos.nombre, email: datos.email, password: datos.password),
      'Administrador ${datos.nombre} creado.',
    );
  }

  Future<void> _editar(AdministradorCuenta cuenta) async {
    if (_guardando) return;
    final idActual = context.read<AuthProvider>().user?.id;
    if (cuenta.id == _idPrincipal && idActual != _idPrincipal) {
      AppFeedback.advertencia('Solo la cuenta principal puede editar sus propios datos.');
      return;
    }
    final datos = await AdministradorDialog.editar(context, cuenta);
    if (datos == null || !mounted) return;
    final nombreCambio = datos.nombre.trim() != cuenta.nombre.trim();
    final emailCambio = datos.email.trim().toLowerCase() != cuenta.email.trim().toLowerCase();
    await _ejecutar(
      () => _repo.editar(
        idUsuario: cuenta.id,
        nombre: nombreCambio ? datos.nombre : null,
        email: emailCambio ? datos.email : null,
        password: datos.password.isEmpty ? null : datos.password,
      ),
      'Datos de ${datos.nombre} actualizados.',
    );
  }

  Future<void> _darDeBaja(AdministradorCuenta cuenta) async {
    if (_guardando) return;
    final idActual = context.read<AuthProvider>().user?.id;
    if (cuenta.id == _idPrincipal) {
      AppFeedback.advertencia('La cuenta principal no se puede dar de baja.');
      return;
    }
    if (cuenta.id == idActual) {
      AppFeedback.advertencia('No podés darte de baja a vos mismo.');
      return;
    }
    final ok = await ConfirmarBajaAdministradorDialog.mostrar(context, cuenta);
    if (!ok || !mounted) return;
    await _ejecutar(
      () => _repo.eliminar(cuenta.id),
      '${cuenta.nombreMostrado} fue dado de baja.',
    );
  }

  Future<void> _ejecutar(Future<void> Function() accion, String exito) async {
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
    } on GestionAdministradoresException catch (e) {
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
    final idActual = context.watch<AuthProvider>().user?.id;
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
                total: _cuentas.length,
                principal: _principal?.nombreMostrado,
                movil: movil,
              ),
              const SizedBox(height: 18),
              FiltrosPanel(
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
                          const Text('Administradores', style: AppTextStyles.label),
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
                      AdministradoresLista(
                        cuentas: filtradas,
                        idPrincipal: _idPrincipal,
                        idActual: idActual,
                        habilitado: !_guardando,
                        onDarDeBaja: _darDeBaja,
                        onEditar: _editar,
                        mensajeVacio: _cuentas.isEmpty
                            ? 'Todavía no hay administradores. Creá el primero con "Nuevo administrador".'
                            : 'Ningún administrador coincide con la búsqueda.',
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
          'Gestión de Administradores',
          style: movil ? AppTextStyles.desktopTitle.copyWith(fontSize: 22) : AppTextStyles.desktopTitle,
        ),
        const SizedBox(height: 4),
        Text(
          'Cuentas con acceso al panel web. La cuenta principal no se puede dar de baja.',
          style: AppTextStyles.desktopSubtitle,
        ),
      ],
    );
    final boton = ElevatedButton.icon(
      onPressed: habilitado ? onNuevo : null,
      icon: const Icon(Icons.person_add_alt_1_outlined, size: 19),
      label: const Text('Nuevo administrador'),
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
  final int total;
  final String? principal;
  final bool movil;

  const _Indicadores({required this.total, required this.principal, required this.movil});

  @override
  Widget build(BuildContext context) {
    final tarjetas = [
      FlotaStatCard(
        icon: Icons.admin_panel_settings_outlined,
        etiqueta: 'Administradores activos',
        valor: '$total',
        acento: AppColors.steelBlue,
      ),
      FlotaStatCard(
        icon: Icons.star_outline_rounded,
        etiqueta: 'Cuenta principal',
        valor: principal ?? '—',
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
