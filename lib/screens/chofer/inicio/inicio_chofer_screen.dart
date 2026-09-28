import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../local/metas_chofer_cache_service.dart';
import '../../../models/metas_dia_chofer.dart';
import '../../../providers/auth_provider.dart';
import '../../../repositories/metas_chofer_repository.dart';
import '../../../repositories/network_exception.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../utils/date_format_utils.dart';
import '../../../widgets/chofer/inicio/metricas_dia_card.dart';
import '../../../widgets/common/carga/zona_carga.dart';

class InicioChoferScreen extends StatefulWidget {
  final bool visible;
  final VoidCallback onIrAgenda;

  const InicioChoferScreen({super.key, required this.visible, required this.onIrAgenda});

  @override
  State<InicioChoferScreen> createState() => _InicioChoferScreenState();
}

class _InicioChoferScreenState extends State<InicioChoferScreen> {
  static const Duration _vigencia = Duration(seconds: 45);

  MetasDiaChofer? _metas;
  DateTime? _actualizado;
  bool _cargando = false;
  bool _desdeCache = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _cargar();
    });
  }

  @override
  void didUpdateWidget(covariant InicioChoferScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible && !oldWidget.visible) {
      final ultimo = _actualizado;
      if (ultimo == null || DateTime.now().difference(ultimo) > _vigencia) _cargar();
    }
  }

  Future<void> _cargar() async {
    if (_cargando) return;
    final auth = context.read<AuthProvider>();
    final idUsuario = auth.user?.id;
    if (idUsuario == null || idUsuario.isEmpty) {
      setState(() => _error = 'No pudimos identificar tu usuario. Volvé a iniciar sesión.');
      return;
    }
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final json = await MetasChoferRepository(auth.apiClient).obtenerMetasDia(idUsuario);
      await MetasChoferCacheService.instance.guardar(idUsuario, json);
      if (!mounted) return;
      setState(() {
        _metas = MetasDiaChofer.fromJson(json);
        _actualizado = DateTime.now();
        _desdeCache = false;
        _cargando = false;
      });
    } on NetworkException {
      final cache = MetasChoferCacheService.instance.obtener(idUsuario);
      if (!mounted) return;
      setState(() {
        if (cache != null) {
          _metas = MetasDiaChofer.fromJson(cache.json);
          _actualizado = cache.obtenidoEn;
          _desdeCache = true;
        } else if (_metas == null) {
          _error = 'Sin conexión. Tus métricas del día se van a mostrar cuando haya señal.';
        } else {
          _desdeCache = true;
        }
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is MetasChoferRepositoryException ? e.message : 'No se pudieron cargar tus métricas del día.';
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final nombreCompleto = auth.user?.fullName?.trim() ?? '';
    final nombre = nombreCompleto.isEmpty ? 'Chofer' : nombreCompleto.split(' ').first;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Encabezado(nombre: nombre),
          Expanded(
            child: ZonaCarga(
              child: RefreshIndicator(
                color: AppColors.orange,
                onRefresh: _cargar,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    ReportarCarga(cargando: _cargando),
                    ..._contenido(),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: widget.onIrAgenda,
                      icon: const Icon(Icons.event_note_outlined),
                      label: const Text('IR A MI AGENDA'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.orange,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        textStyle: AppTextStyles.button,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
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

  List<Widget> _contenido() {
    final metas = _metas;
    if (metas == null) {
      if (_error != null) return [_Aviso(icono: Icons.cloud_off_outlined, texto: _error!, onReintentar: _cargar)];
      return const [SizedBox(height: 280)];
    }
    return [
      if (_desdeCache)
        _Aviso(
          icono: Icons.cloud_off_outlined,
          texto: _actualizado != null
              ? 'Sin conexión: mostrando tus datos de las ${formatHora12(_actualizado!)}.'
              : 'Sin conexión: mostrando los últimos datos guardados.',
        ),
      if (metas.sinAgenda)
        const _Aviso(
          icono: Icons.event_busy_outlined,
          texto: 'Todavía no tenés visitas asignadas para hoy.',
        ),
      MetricasDiaCard(metas: metas),
      if (_actualizado != null && !_desdeCache)
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Text(
            'Actualizado a las ${formatHora12(_actualizado!)} · deslizá hacia abajo para refrescar',
            textAlign: TextAlign.center,
            style: AppTextStyles.footer,
          ),
        ),
    ];
  }
}

class _Encabezado extends StatelessWidget {
  final String nombre;

  const _Encabezado({required this.nombre});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Hola, $nombre', style: AppTextStyles.title.copyWith(fontSize: 22)),
          const SizedBox(height: 2),
          Text(
            'Tu resumen de hoy · ${formatFechaCorta(DateTime.now())}',
            style: AppTextStyles.link.copyWith(fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _Aviso extends StatelessWidget {
  final IconData icono;
  final String texto;
  final VoidCallback? onReintentar;

  const _Aviso({required this.icono, required this.texto, this.onReintentar});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.steelBlue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.steelBlue.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(icono, size: 20, color: AppColors.steelBlue),
          const SizedBox(width: 10),
          Expanded(
            child: Text(texto, style: AppTextStyles.link.copyWith(fontSize: 13, color: AppColors.steelBlue)),
          ),
          if (onReintentar != null)
            TextButton(
              onPressed: onReintentar,
              child: const Text(
                'REINTENTAR',
                style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.orange),
              ),
            ),
        ],
      ),
    );
  }
}
