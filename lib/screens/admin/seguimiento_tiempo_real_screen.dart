import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../models/alerta_model.dart';
import '../../models/cliente_ficha.dart';
import '../../models/visita_alerta.dart';
import '../../models/visita_estado.dart';
import '../../models/visita_model.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/alerta_repository.dart';
import '../../repositories/ubicacion_repository.dart';
import '../../repositories/visita_repository.dart';
import '../../services/visitas_realtime_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/admin/alerta_visita_badge.dart';
import '../../widgets/admin/estado_visita_badge.dart';
import '../../widgets/chofer/comodato_badge.dart';
import '../../widgets/chofer/ultima_bajada_indicator.dart';
import '../../widgets/labeled_text_field.dart';

const LatLng formosaCenter = LatLng(-26.1849, -58.1731);

const List<Color> _choferPalette = [
  Color(0xFF2F80ED),
  Color(0xFFE05348),
  Color(0xFFE0A030),
  Color(0xFF27AE60),
  Color(0xFF9B51E0),
  Color(0xFF00A896),
];

(Color, IconData) _estadoVisual(VisitaEstado estado) {
  switch (estado) {
    case VisitaEstado.pendiente:
      return (AppColors.badgeBlue, Icons.hourglass_empty);
    case VisitaEstado.enCurso:
      return (AppColors.badgeAmber, Icons.local_shipping_outlined);
    case VisitaEstado.visitado:
      return (AppColors.badgeGreen, Icons.check_circle_outline);
    case VisitaEstado.completada:
      return (AppColors.badgeGreen, Icons.task_alt);
    case VisitaEstado.cancelada:
      return (AppColors.badgeRed, Icons.cancel_outlined);
    case VisitaEstado.noAsistio:
      return (AppColors.badgeRed, Icons.error_outline);
    case VisitaEstado.inactivo:
    case VisitaEstado.unknown:
      return (AppColors.badgeGray, Icons.help_outline);
  }
}

class _ChoferRuta {
  final String choferId;
  final String choferNombre;
  final Color color;
  final List<LatLng> puntos;
  final LatLng? posicionActual;

  const _ChoferRuta({
    required this.choferId,
    required this.choferNombre,
    required this.color,
    required this.puntos,
    required this.posicionActual,
  });
}

class SeguimientoTiempoRealScreen extends StatefulWidget {
  const SeguimientoTiempoRealScreen({super.key});

  @override
  State<SeguimientoTiempoRealScreen> createState() =>
      _SeguimientoTiempoRealScreenState();
}

class _SeguimientoTiempoRealScreenState
    extends State<SeguimientoTiempoRealScreen> {
  late final VisitaRepository _visitaRepo;
  late final AlertaRepository _alertaRepo;
  late final UbicacionRepository _ubicacionRepo;
  late final VisitasRealtimeService _realtime;

  final MapController _mapController = MapController();
  final TextEditingController _choferFilterCtrl = TextEditingController();

  bool _loading = true;
  String? _loadError;
  bool _wsConnected = false;

  List<VisitaModel> _visitas = [];
  final Map<int, VisitaAlertaTipo> _alertaPorVisita = {};
  final Map<String, LatLng> _posicionEnVivo = {};

  int? _selectedVisitaId;
  String? _estadoFilter;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _visitaRepo = VisitaRepository(auth.apiClient);
    _alertaRepo = AlertaRepository(auth.apiClient);
    _ubicacionRepo = UbicacionRepository(auth.apiClient);
    _realtime = VisitasRealtimeService();

    _choferFilterCtrl.addListener(() => setState(() {}));

    _cargarDatos();
    _cargarUbicaciones();

    _realtime.connectionState.listen((connected) {
      if (mounted) setState(() => _wsConnected = connected);
    });
    _realtime.messages.listen(_handleRealtimeMessage);

    final token = auth.accessToken;
    if (token != null && token.isNotEmpty) {
      _realtime.connect(token);
    }
  }

  @override
  void dispose() {
    _realtime.dispose();
    _choferFilterCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarUbicaciones() async {
    final posiciones = await _ubicacionRepo.listarActivas();
    if (!mounted || posiciones.isEmpty) return;
    setState(() {
      for (final p in posiciones) {
        _posicionEnVivo[p.idChofer] = LatLng(p.latitud, p.longitud);
      }
    });
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final results = await Future.wait([
        _visitaRepo.listarTodas(),
        _alertaRepo.listarAbiertas(),
      ]);
      if (!mounted) return;
      final todasLasVisitas = results[0] as List<VisitaModel>;
      final hoy = DateTime.now();
      setState(() {
        _visitas = todasLasVisitas.where((v) {
          final f = v.fecha;
          return f != null &&
              f.year == hoy.year &&
              f.month == hoy.month &&
              f.day == hoy.day;
        }).toList();
        _alertaPorVisita.clear();
        for (final alerta in results[1] as List<AlertaModel>) {
          if (alerta.tipo != null) {
            _alertaPorVisita[alerta.idVisita] = alerta.tipo!;
          }
        }
        _loading = false;
      });
    } on VisitaRepositoryException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.message;
        _loading = false;
      });
    } on AlertaRepositoryException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadError = 'No se pudo cargar el estado de las visitas de hoy.';
        _loading = false;
      });
    }
  }

  void _handleRealtimeMessage(VisitaRealtimeMessage message) {
    if (!mounted) return;
    if (message is VisitaEstadoActualizadoMessage) {
      setState(() {
        final idx = _visitas.indexWhere((v) => v.idVisita == message.idVisita);
        if (idx == -1) return;
        final estado = VisitaEstadoMapper.fromValue(message.estadoNuevo);
        final enCurso = estado == VisitaEstado.enCurso;
        _visitas[idx] = _visitas[idx].copyWith(
          estadoVisita: estado,
          timestampInicio: message.timestampInicio,
          timestampFin: message.timestampFin,
          latitudInicio: enCurso ? message.latitud : null,
          longitudInicio: enCurso ? message.longitud : null,
          latitudFin: enCurso ? null : message.latitud,
          longitudFin: enCurso ? null : message.longitud,
          geolocalizacionValida: message.geolocalizacionValida,
        );
      });
    } else if (message is AlertaCreadaMessage) {
      setState(() {
        if (message.estado == VisitaAlertaEstado.abierta && message.tipo != null) {
          _alertaPorVisita[message.idVisita] = message.tipo!;
        } else {
          _alertaPorVisita.remove(message.idVisita);
        }
      });
    } else if (message is PosicionChoferMessage) {
      setState(() {
        _posicionEnVivo[message.idChofer] =
            LatLng(message.latitud, message.longitud);
      });
    }
  }

  String _clienteNombre(VisitaModel v) {
    final snapshot = v.sucursalSnapshot;
    for (final key in ['nombre', 'nombreSucursal', 'razonSocial', 'cliente']) {
      final value = snapshot[key];
      if (value is String && value.trim().isNotEmpty) return value;
    }
    return 'Sucursal #${v.idSucursal}';
  }

  String _horaProgramada(VisitaModel v) {
    final h = v.horaInicioPlanificada;
    if (h == null || h.isEmpty) return 'Sin horario';
    return h.length >= 5 ? h.substring(0, 5) : h;
  }

  String? _horaCheckIn(VisitaModel v) {
    final t = v.timestampInicio;
    if (t == null) return null;
    final local = t.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  LatLng? _posicionDe(VisitaModel v) {
    final lat = v.latitudFin ?? v.latitudInicio ?? v.sucursalLatitud;
    final lng = v.longitudFin ?? v.longitudInicio ?? v.sucursalLongitud;
    if (lat == null || lng == null) return null;
    return LatLng(lat, lng);
  }

  Color _colorParaChofer(String idChofer) {
    return _choferPalette[idChofer.hashCode.abs() % _choferPalette.length];
  }

  List<VisitaModel> get _filteredVisitas {
    final query = _choferFilterCtrl.text.trim().toLowerCase();
    return _visitas.where((v) {
      final nombre = (v.nombreUsuario ?? '').toLowerCase();
      if (query.isNotEmpty && !nombre.contains(query)) return false;
      if (_estadoFilter != null &&
          VisitaEstadoMapper.toValue(v.estadoVisita) != _estadoFilter) {
        return false;
      }
      return true;
    }).toList();
  }

  Map<String, List<VisitaModel>> get _agrupadasPorChofer {
    final map = <String, List<VisitaModel>>{};
    for (final v in _filteredVisitas) {
      final nombre = v.nombreUsuario ?? 'Sin asignar';
      map.putIfAbsent(nombre, () => []).add(v);
    }
    return map;
  }

  List<_ChoferRuta> get _rutasPorChofer {
    final porChofer = <String, List<VisitaModel>>{};
    for (final v in _visitas) {
      porChofer.putIfAbsent(v.idUsuario, () => []).add(v);
    }

    final rutas = <_ChoferRuta>[];
    porChofer.forEach((idChofer, visitasChofer) {
      visitasChofer.sort((a, b) => a.ordenVisita.compareTo(b.ordenVisita));
      final puntos = <LatLng>[];
      for (final v in visitasChofer) {
        final p = _posicionDe(v);
        if (p != null) puntos.add(p);
      }

      VisitaModel? enCurso;
      for (final v in visitasChofer) {
        if (v.estadoVisita == VisitaEstado.enCurso) {
          enCurso = v;
          break;
        }
      }
      final posicionActual = _posicionEnVivo[idChofer] ??
          (enCurso != null
              ? _posicionDe(enCurso)
              : (puntos.isNotEmpty ? puntos.last : null));

      rutas.add(_ChoferRuta(
        choferId: idChofer,
        choferNombre: visitasChofer.first.nombreUsuario ?? 'Sin asignar',
        color: _colorParaChofer(idChofer),
        puntos: puntos,
        posicionActual: posicionActual,
      ));
    });
    return rutas;
  }

  VisitaModel? get _selectedVisita {
    if (_selectedVisitaId == null) return null;
    for (final v in _visitas) {
      if (v.idVisita == _selectedVisitaId) return v;
    }
    return null;
  }

  void _selectVisita(VisitaModel v) {
    final p = _posicionDe(v);
    setState(() => _selectedVisitaId = v.idVisita);
    if (p != null) _mapController.move(p, 15.5);
  }

  void _cerrarInfo() => setState(() => _selectedVisitaId = null);

  @override
  Widget build(BuildContext context) {
    final bottomSafePadding = MediaQuery.of(context).padding.bottom;

    if (_loading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.orange));
    }

    if (_loadError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_loadError!, style: AppTextStyles.errorText),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _cargarDatos,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Reintentar'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.steelBlue,
                side: const BorderSide(color: AppColors.steelBlue),
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomSafePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(connected: _wsConnected),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 1000;

              final mapa = _MapaCard(
                mapController: _mapController,
                rutas: _rutasPorChofer,
                visitas: _visitas,
                posicionDe: _posicionDe,
                alertaPorVisita: _alertaPorVisita,
                selectedVisita: _selectedVisita,
                selectedVisitaAlerta: _selectedVisitaId != null
                    ? _alertaPorVisita[_selectedVisitaId]
                    : null,
                onMarkerTap: _selectVisita,
                onCerrarInfo: _cerrarInfo,
                clienteNombreOf: _clienteNombre,
              );

              final lista = _ListadoCard(
                choferCtrl: _choferFilterCtrl,
                estadoFilter: _estadoFilter,
                onEstadoChanged: (v) => setState(() => _estadoFilter = v),
                grupos: _agrupadasPorChofer,
                selectedVisitaId: _selectedVisitaId,
                onSelect: _selectVisita,
                clienteNombreOf: _clienteNombre,
                horaProgramadaOf: _horaProgramada,
                horaCheckInOf: _horaCheckIn,
                alertaPorVisita: _alertaPorVisita,
              );

              if (wide) {
                return SizedBox(
                  height: 680,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 45, child: mapa),
                      const SizedBox(width: 20),
                      Expanded(flex: 55, child: lista),
                    ],
                  ),
                );
              }

              return Column(
                children: [
                  SizedBox(height: 360, child: mapa),
                  const SizedBox(height: 20),
                  SizedBox(height: 480, child: lista),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final bool connected;

  const _Header({required this.connected});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Listado de Visitas en Tiempo Real', style: AppTextStyles.desktopTitle),
              const SizedBox(height: 4),
              Text(
                'Seguimiento en vivo de choferes, visitas y alertas de hoy.',
                style: AppTextStyles.desktopSubtitle,
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        _WebSocketStatusChip(connected: connected),
      ],
    );
  }
}

class _WebSocketStatusChip extends StatelessWidget {
  final bool connected;

  const _WebSocketStatusChip({required this.connected});

  @override
  Widget build(BuildContext context) {
    final color = connected ? AppColors.badgeGreen : AppColors.badgeGray;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(connected ? Icons.wifi : Icons.wifi_off, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            connected ? 'Tiempo real: conectado' : 'Tiempo real: reconectando',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}

class _CardContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const _CardContainer({required this.child, this.padding = const EdgeInsets.all(20)});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: child,
    );
  }
}

class _MapaCard extends StatelessWidget {
  final MapController mapController;
  final List<_ChoferRuta> rutas;
  final List<VisitaModel> visitas;
  final LatLng? Function(VisitaModel) posicionDe;
  final Map<int, VisitaAlertaTipo> alertaPorVisita;
  final VisitaModel? selectedVisita;
  final VisitaAlertaTipo? selectedVisitaAlerta;
  final ValueChanged<VisitaModel> onMarkerTap;
  final VoidCallback onCerrarInfo;
  final String Function(VisitaModel) clienteNombreOf;

  const _MapaCard({
    required this.mapController,
    required this.rutas,
    required this.visitas,
    required this.posicionDe,
    required this.alertaPorVisita,
    required this.selectedVisita,
    required this.selectedVisitaAlerta,
    required this.onMarkerTap,
    required this.onCerrarInfo,
    required this.clienteNombreOf,
  });

  @override
  Widget build(BuildContext context) {
    return _CardContainer(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Positioned.fill(
              child: FlutterMap(
                mapController: mapController,
                options: const MapOptions(
                  initialCenter: formosaCenter,
                  initialZoom: 13.5,
                  minZoom: 3,
                  maxZoom: 19,
                  interactionOptions: InteractionOptions(flags: InteractiveFlag.all),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.comforgas.web',
                    tileProvider: CancellableNetworkTileProvider(),
                  ),
                  MarkerLayer(
                    markers: [
                      for (final r in rutas)
                        if (r.posicionActual != null)
                          Marker(
                            point: r.posicionActual!,
                            width: 40,
                            height: 62,
                            alignment: Alignment.bottomCenter,
                            child: _ChoferMarker(color: r.color),
                          ),
                      for (final v in visitas)
                        if (posicionDe(v) != null)
                          Marker(
                            point: posicionDe(v)!,
                            width: 38,
                            height: 38,
                            child: _VisitaMarker(
                              visita: v,
                              alerta: alertaPorVisita[v.idVisita],
                              selected: v.idVisita == selectedVisita?.idVisita,
                              onTap: () => onMarkerTap(v),
                            ),
                          ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(top: 12, left: 12, child: _Leyenda(rutas: rutas)),
            Positioned(
              bottom: selectedVisita != null ? 92 : 12,
              right: 12,
              child: _ZoomControls(mapController: mapController),
            ),
            if (selectedVisita != null)
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: _VisitaInfoPanel(
                  visita: selectedVisita!,
                  alerta: selectedVisitaAlerta,
                  clienteNombre: clienteNombreOf(selectedVisita!),
                  onClose: onCerrarInfo,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ZoomControls extends StatelessWidget {
  final MapController mapController;

  const _ZoomControls({required this.mapController});

  void _zoom(double delta) {
    final camera = mapController.camera;
    mapController.move(camera.center, camera.zoom + delta);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ZoomButton(icon: Icons.add, onTap: () => _zoom(1)),
          Container(height: 1, color: AppColors.inputBorder),
          _ZoomButton(icon: Icons.remove, onTap: () => _zoom(-1)),
        ],
      ),
    );
  }
}

class _ZoomButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ZoomButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(icon, size: 18, color: AppColors.steelBlue),
        ),
      ),
    );
  }
}

class _ChoferMarker extends StatelessWidget {
  final Color color;

  const _ChoferMarker({required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.white, width: 3),
            boxShadow: [BoxShadow(color: color.withOpacity(0.35), blurRadius: 5)],
          ),
          child: const Icon(Icons.local_shipping, color: AppColors.white, size: 18),
        ),
        Container(width: 3, height: 8, color: color),
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.white, width: 2),
          ),
        ),
      ],
    );
  }
}

class _VisitaMarker extends StatelessWidget {
  final VisitaModel visita;
  final VisitaAlertaTipo? alerta;
  final bool selected;
  final VoidCallback onTap;

  const _VisitaMarker({
    required this.visita,
    required this.alerta,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final (color, icon) = _estadoVisual(visita.estadoVisita);
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: selected ? 38 : 30,
              height: selected ? 38 : 30,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: selected ? 3 : 2),
                boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: selected ? 10 : 4)],
              ),
              child: Icon(icon, color: Colors.white, size: selected ? 18 : 14),
            ),
            if (alerta != null)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: alerta == VisitaAlertaTipo.desvioGeografico ||
                            alerta == VisitaAlertaTipo.coordenadasInvalidas ||
                            alerta == VisitaAlertaTipo.incidenciaCampo
                        ? AppColors.badgeRed
                        : AppColors.orange,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Leyenda extends StatelessWidget {
  final List<_ChoferRuta> rutas;

  const _Leyenda({required this.rutas});

  @override
  Widget build(BuildContext context) {
    if (rutas.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < rutas.length; i++) ...[
            if (i > 0) const SizedBox(height: 6),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '●  ',
                    style: TextStyle(fontSize: 12, color: rutas[i].color),
                  ),
                  TextSpan(
                    text: rutas[i].choferNombre,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.steelBlue,
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

class _VisitaInfoPanel extends StatelessWidget {
  final VisitaModel visita;
  final VisitaAlertaTipo? alerta;
  final String clienteNombre;
  final VoidCallback onClose;

  const _VisitaInfoPanel({
    required this.visita,
    required this.alerta,
    required this.clienteNombre,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final (color, icon) = _estadoVisual(visita.estadoVisita);
    final ficha = ClienteFicha.fromVisita(visita, nombreResuelto: clienteNombre);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 14, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  clienteNombre,
                  style: AppTextStyles.title.copyWith(fontSize: 15),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${visita.nombreUsuario ?? 'Sin asignar'} · Cliente ID ${ficha.clienteId}',
                  style: AppTextStyles.desktopSubtitle.copyWith(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (ficha.tieneComodatoActivo)
                      ComodatoBadge(comodatos: ficha.comodatosActivos, compacto: true),
                    UltimaBajadaIndicator(fecha: ficha.ultimaBajada, compacto: true),
                  ],
                ),
                if (alerta != null) ...[
                  const SizedBox(height: 6),
                  AlertaVisitaBadge(tipo: alerta),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close, size: 18, color: AppColors.inputHint),
          ),
        ],
      ),
    );
  }
}

class _ListadoCard extends StatelessWidget {
  final TextEditingController choferCtrl;
  final String? estadoFilter;
  final ValueChanged<String?> onEstadoChanged;
  final Map<String, List<VisitaModel>> grupos;
  final int? selectedVisitaId;
  final ValueChanged<VisitaModel> onSelect;
  final String Function(VisitaModel) clienteNombreOf;
  final String Function(VisitaModel) horaProgramadaOf;
  final String? Function(VisitaModel) horaCheckInOf;
  final Map<int, VisitaAlertaTipo> alertaPorVisita;

  const _ListadoCard({
    required this.choferCtrl,
    required this.estadoFilter,
    required this.onEstadoChanged,
    required this.grupos,
    required this.selectedVisitaId,
    required this.onSelect,
    required this.clienteNombreOf,
    required this.horaProgramadaOf,
    required this.horaCheckInOf,
    required this.alertaPorVisita,
  });

  static const List<(String value, String label)> _estados = [
    ('PENDIENTE', 'Pendiente'),
    ('EN_CURSO', 'En curso'),
    ('VISITADO', 'Visitado'),
    ('COMPLETADA', 'Completada'),
    ('CANCELADA', 'Cancelada'),
    ('NO_ASISTIO', 'No asistió'),
  ];

  @override
  Widget build(BuildContext context) {
    final totalVisitas = grupos.values.fold<int>(0, (a, l) => a + l.length);

    return _CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: LabeledTextField(
                  label: 'Buscador por Chofer',
                  hint: 'Nombre del chofer',
                  icon: Icons.search,
                  controller: choferCtrl,
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 170,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Estado', style: AppTextStyles.label),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.inputBorder, width: 1.2),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String?>(
                          isExpanded: true,
                          value: estadoFilter,
                          hint: Text('Todos', style: AppTextStyles.hint),
                          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.inputHint),
                          style: AppTextStyles.input,
                          items: [
                            const DropdownMenuItem<String?>(value: null, child: Text('Todos')),
                            for (final (value, label) in _estados)
                              DropdownMenuItem<String?>(
                                value: value,
                                child: Text(label),
                              ),
                          ],
                          onChanged: onEstadoChanged,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '$totalVisitas visita(s) de hoy · agrupadas por chofer',
            style: AppTextStyles.desktopSubtitle.copyWith(fontSize: 12),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: AppColors.inputBorder),
          Expanded(
            child: grupos.isEmpty
                ? Center(
                    child: Text(
                      'No hay visitas para los filtros seleccionados.',
                      style: AppTextStyles.desktopSubtitle,
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.only(top: 8),
                    children: [
                      for (final entry in grupos.entries)
                        _GrupoChofer(
                          choferNombre: entry.key,
                          visitas: entry.value,
                          selectedVisitaId: selectedVisitaId,
                          onSelect: onSelect,
                          clienteNombreOf: clienteNombreOf,
                          horaProgramadaOf: horaProgramadaOf,
                          horaCheckInOf: horaCheckInOf,
                          alertaPorVisita: alertaPorVisita,
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _GrupoChofer extends StatelessWidget {
  final String choferNombre;
  final List<VisitaModel> visitas;
  final int? selectedVisitaId;
  final ValueChanged<VisitaModel> onSelect;
  final String Function(VisitaModel) clienteNombreOf;
  final String Function(VisitaModel) horaProgramadaOf;
  final String? Function(VisitaModel) horaCheckInOf;
  final Map<int, VisitaAlertaTipo> alertaPorVisita;

  const _GrupoChofer({
    required this.choferNombre,
    required this.visitas,
    required this.selectedVisitaId,
    required this.onSelect,
    required this.clienteNombreOf,
    required this.horaProgramadaOf,
    required this.horaCheckInOf,
    required this.alertaPorVisita,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              const Icon(Icons.person_outline, size: 16, color: AppColors.steelBlue),
              const SizedBox(width: 6),
              Text(choferNombre, style: AppTextStyles.label.copyWith(fontSize: 13)),
            ],
          ),
        ),
        for (final v in visitas)
          _VisitaRow(
            visita: v,
            alerta: alertaPorVisita[v.idVisita],
            selected: v.idVisita == selectedVisitaId,
            clienteNombre: clienteNombreOf(v),
            horaProgramada: horaProgramadaOf(v),
            horaCheckIn: horaCheckInOf(v),
            onTap: () => onSelect(v),
          ),
        const SizedBox(height: 6),
      ],
    );
  }
}

class _VisitaRow extends StatelessWidget {
  final VisitaModel visita;
  final VisitaAlertaTipo? alerta;
  final bool selected;
  final String clienteNombre;
  final String horaProgramada;
  final String? horaCheckIn;
  final VoidCallback onTap;

  const _VisitaRow({
    required this.visita,
    required this.alerta,
    required this.selected,
    required this.clienteNombre,
    required this.horaProgramada,
    required this.horaCheckIn,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.steelBlue.withOpacity(0.06) : AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.steelBlue : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 560;
            if (compact) {
              return _VisitaRowCompact(
                visita: visita,
                alerta: alerta,
                clienteNombre: clienteNombre,
                horaProgramada: horaProgramada,
                horaCheckIn: horaCheckIn,
              );
            }
            return _VisitaRowWide(
              visita: visita,
              alerta: alerta,
              clienteNombre: clienteNombre,
              horaProgramada: horaProgramada,
              horaCheckIn: horaCheckIn,
            );
          },
        ),
      ),
    );
  }
}

class _VisitaRowWide extends StatelessWidget {
  final VisitaModel visita;
  final VisitaAlertaTipo? alerta;
  final String clienteNombre;
  final String horaProgramada;
  final String? horaCheckIn;

  const _VisitaRowWide({
    required this.visita,
    required this.alerta,
    required this.clienteNombre,
    required this.horaProgramada,
    required this.horaCheckIn,
  });

  @override
  Widget build(BuildContext context) {
    final ficha = ClienteFicha.fromVisita(visita, nombreResuelto: clienteNombre);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                clienteNombre,
                style: AppTextStyles.input.copyWith(fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'Cliente ID ${ficha.clienteId}',
                style: AppTextStyles.desktopSubtitle.copyWith(fontSize: 11),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              UltimaBajadaIndicator(fecha: ficha.ultimaBajada, compacto: true),
              if (ficha.tieneComodatoActivo) ...[
                const SizedBox(height: 6),
                ComodatoBadge(comodatos: ficha.comodatosActivos, compacto: true),
              ],
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Prog. $horaProgramada', style: AppTextStyles.input.copyWith(fontSize: 12)),
              Text(
                horaCheckIn != null ? 'Check-in $horaCheckIn' : 'Sin check-in',
                style: AppTextStyles.desktopSubtitle.copyWith(fontSize: 11),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Align(
            alignment: Alignment.centerLeft,
            child: EstadoVisitaBadge(estado: visita.estadoVisita),
          ),
        ),
        Expanded(
          flex: 2,
          child: Align(
            alignment: Alignment.centerLeft,
            child: AlertaVisitaBadge(tipo: alerta),
          ),
        ),
      ],
    );
  }
}

class _VisitaRowCompact extends StatelessWidget {
  final VisitaModel visita;
  final VisitaAlertaTipo? alerta;
  final String clienteNombre;
  final String horaProgramada;
  final String? horaCheckIn;

  const _VisitaRowCompact({
    required this.visita,
    required this.alerta,
    required this.clienteNombre,
    required this.horaProgramada,
    required this.horaCheckIn,
  });

  @override
  Widget build(BuildContext context) {
    final ficha = ClienteFicha.fromVisita(visita, nombreResuelto: clienteNombre);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                clienteNombre,
                style: AppTextStyles.input.copyWith(fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            EstadoVisitaBadge(estado: visita.estadoVisita),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Cliente ID ${ficha.clienteId} · Prog. $horaProgramada',
          style: AppTextStyles.desktopSubtitle.copyWith(fontSize: 11),
        ),
        const SizedBox(height: 6),
        UltimaBajadaIndicator(fecha: ficha.ultimaBajada, compacto: true),
        if (ficha.tieneComodatoActivo || alerta != null) ...[
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (ficha.tieneComodatoActivo)
                ComodatoBadge(comodatos: ficha.comodatosActivos, compacto: true),
              if (alerta != null) AlertaVisitaBadge(tipo: alerta),
            ],
          ),
        ],
      ],
    );
  }
}
