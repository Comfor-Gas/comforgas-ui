import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../data/mock_seguimiento_data.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/admin/alerta_visita_badge.dart';
import '../../widgets/labeled_text_field.dart';
import '../../widgets/primary_button.dart';

class SeguimientoTiempoRealScreen extends StatefulWidget {
  const SeguimientoTiempoRealScreen({super.key});

  @override
  State<SeguimientoTiempoRealScreen> createState() =>
      _SeguimientoTiempoRealScreenState();
}

class _SeguimientoTiempoRealScreenState
    extends State<SeguimientoTiempoRealScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _choferFilterCtrl = TextEditingController();

  String? _selectedVisitaId;
  String? _estadoFilter;

  @override
  void initState() {
    super.initState();
    _choferFilterCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _choferFilterCtrl.dispose();
    super.dispose();
  }

  List<VisitaSeguimientoMock> get _filteredVisitas {
    final query = _choferFilterCtrl.text.trim().toLowerCase();
    return mockVisitasSeguimiento.where((v) {
      if (query.isNotEmpty && !v.choferNombre.toLowerCase().contains(query)) {
        return false;
      }
      if (_estadoFilter != null && v.estado.label != _estadoFilter) {
        return false;
      }
      return true;
    }).toList();
  }

  Map<String, List<VisitaSeguimientoMock>> get _agrupadasPorChofer {
    final map = <String, List<VisitaSeguimientoMock>>{};
    for (final v in _filteredVisitas) {
      map.putIfAbsent(v.choferNombre, () => []).add(v);
    }
    return map;
  }

  VisitaSeguimientoMock? get _selectedVisita {
    if (_selectedVisitaId == null) return null;
    for (final v in mockVisitasSeguimiento) {
      if (v.id == _selectedVisitaId) return v;
    }
    return null;
  }

  void _selectVisita(VisitaSeguimientoMock v) {
    setState(() => _selectedVisitaId = v.id);
    _mapController.move(v.posicion, 15.5);
  }

  void _cerrarInfo() => setState(() => _selectedVisitaId = null);

  @override
  Widget build(BuildContext context) {
    final bottomSafePadding = MediaQuery.of(context).padding.bottom;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomSafePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Header(),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 1000;

              final mapa = _MapaCard(
                mapController: _mapController,
                selectedVisita: _selectedVisita,
                onMarkerTap: _selectVisita,
                onCerrarInfo: _cerrarInfo,
              );

              final lista = _ListadoCard(
                choferCtrl: _choferFilterCtrl,
                estadoFilter: _estadoFilter,
                onEstadoChanged: (v) => setState(() => _estadoFilter = v),
                grupos: _agrupadasPorChofer,
                selectedVisitaId: _selectedVisitaId,
                onSelect: _selectVisita,
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
          const SizedBox(height: 20),
          PrimaryButton(
            text: 'Publicar Nuevas Rutas',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'La publicación de rutas se conecta con Planificación '
                    'de Visitas. Esta pantalla es de solo lectura por ahora.',
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}


class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Listado de Visitas en Tiempo Real',
                style: AppTextStyles.desktopTitle,
              ),
              const SizedBox(height: 4),
              Text(
                'Seguimiento en vivo de choferes, visitas y alertas del día.',
                style: AppTextStyles.desktopSubtitle,
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        const _WebSocketStatusChip(),
      ],
    );
  }
}

class _WebSocketStatusChip extends StatelessWidget {
  const _WebSocketStatusChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.badgeGray.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off, size: 14, color: AppColors.badgeGray),
          const SizedBox(width: 6),
          Text(
            'Tiempo real: esperando backend',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.badgeGray.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }
}


class _CardContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const _CardContainer({
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

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
  final VisitaSeguimientoMock? selectedVisita;
  final ValueChanged<VisitaSeguimientoMock> onMarkerTap;
  final VoidCallback onCerrarInfo;

  const _MapaCard({
    required this.mapController,
    required this.selectedVisita,
    required this.onMarkerTap,
    required this.onCerrarInfo,
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
                  interactionOptions: InteractionOptions(
                    flags: InteractiveFlag.all,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.comforgas.web',
                  ),
                  PolylineLayer(
                    polylines: [
                      for (final ruta in mockRutasChofer)
                        if (recorridoDeChofer(ruta.choferId).length > 1)
                          Polyline(
                            points: recorridoDeChofer(ruta.choferId),
                            color: ruta.color,
                            strokeWidth: 4,
                          ),
                    ],
                  ),
                  MarkerLayer(
                    markers: [
                      for (final ruta in mockRutasChofer)
                        Marker(
                          point: ruta.posicionActual,
                          width: 44,
                          height: 44,
                          child: _ChoferMarker(color: ruta.color),
                        ),
                      for (final v in mockVisitasSeguimiento)
                        Marker(
                          point: v.posicion,
                          width: 38,
                          height: 38,
                          child: _VisitaMarker(
                            visita: v,
                            selected: v.id == selectedVisita?.id,
                            onTap: () => onMarkerTap(v),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              top: 12,
              left: 12,
              child: _Leyenda(rutas: mockRutasChofer),
            ),
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
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
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
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.45),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: const Icon(
        Icons.local_shipping,
        color: Colors.white,
        size: 20,
      ),
    );
  }
}

class _VisitaMarker extends StatelessWidget {
  final VisitaSeguimientoMock visita;
  final bool selected;
  final VoidCallback onTap;

  const _VisitaMarker({
    required this.visita,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = visita.estado.color;
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
                border: Border.all(
                  color: Colors.white,
                  width: selected ? 3 : 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.5),
                    blurRadius: selected ? 10 : 4,
                  ),
                ],
              ),
              child: Icon(
                visita.estado.icon,
                color: Colors.white,
                size: selected ? 18 : 14,
              ),
            ),
            if (visita.tieneAlerta)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: visita.alerta.name == 'gpsDesvio'
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
  final List<ChoferRutaMock> rutas;

  const _Leyenda({required this.rutas});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final r in rutas)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: r.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    r.choferNombre,
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
      ),
    );
  }
}

class _VisitaInfoPanel extends StatelessWidget {
  final VisitaSeguimientoMock visita;
  final VoidCallback onClose;

  const _VisitaInfoPanel({required this.visita, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: visita.estado.color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(visita.estado.icon, color: visita.estado.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  visita.cliente,
                  style: AppTextStyles.title.copyWith(fontSize: 15),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${visita.choferNombre} · ${visita.sucursal} Nº ${visita.numeroSucursal}',
                  style: AppTextStyles.desktopSubtitle.copyWith(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
                if (visita.tieneAlerta) ...[
                  const SizedBox(height: 6),
                  AlertaVisitaBadge(tipo: visita.alerta),
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
  final Map<String, List<VisitaSeguimientoMock>> grupos;
  final String? selectedVisitaId;
  final ValueChanged<VisitaSeguimientoMock> onSelect;

  const _ListadoCard({
    required this.choferCtrl,
    required this.estadoFilter,
    required this.onEstadoChanged,
    required this.grupos,
    required this.selectedVisitaId,
    required this.onSelect,
  });

  static const List<String> _estados = [
    'PENDIENTE',
    'EN CURSO',
    'VISITADO',
    'ASIGNADO',
    'CANCELADA',
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
                          icon: const Icon(Icons.keyboard_arrow_down,
                              color: AppColors.inputHint),
                          style: AppTextStyles.input,
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('Todos'),
                            ),
                            ..._estados.map(
                              (e) => DropdownMenuItem<String?>(
                                value: e,
                                child: Text(e),
                              ),
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
            '$totalVisitas visita(s) · agrupadas por chofer',
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
  final List<VisitaSeguimientoMock> visitas;
  final String? selectedVisitaId;
  final ValueChanged<VisitaSeguimientoMock> onSelect;

  const _GrupoChofer({
    required this.choferNombre,
    required this.visitas,
    required this.selectedVisitaId,
    required this.onSelect,
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
              Text(
                choferNombre,
                style: AppTextStyles.label.copyWith(fontSize: 13),
              ),
            ],
          ),
        ),
        for (final v in visitas)
          _VisitaRow(
            visita: v,
            selected: v.id == selectedVisitaId,
            onTap: () => onSelect(v),
          ),
        const SizedBox(height: 6),
      ],
    );
  }
}

class _VisitaRow extends StatelessWidget {
  final VisitaSeguimientoMock visita;
  final bool selected;
  final VoidCallback onTap;

  const _VisitaRow({
    required this.visita,
    required this.selected,
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
          color: selected
              ? AppColors.steelBlue.withOpacity(0.06)
              : AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.steelBlue : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 560;
            if (compact) return _VisitaRowCompact(visita: visita);
            return _VisitaRowWide(visita: visita);
          },
        ),
      ),
    );
  }
}

class _VisitaRowWide extends StatelessWidget {
  final VisitaSeguimientoMock visita;

  const _VisitaRowWide({required this.visita});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                visita.cliente,
                style: AppTextStyles.input.copyWith(fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '${visita.sucursal} · Nº ${visita.numeroSucursal}',
                style: AppTextStyles.desktopSubtitle.copyWith(fontSize: 11),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Prog. ${visita.horaProgramada}',
                  style: AppTextStyles.input.copyWith(fontSize: 12)),
              Text(
                visita.horaCheckIn != null
                    ? 'Check-in ${visita.horaCheckIn}'
                    : 'Sin check-in',
                style: AppTextStyles.desktopSubtitle.copyWith(fontSize: 11),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: _EstadoBadge(visita: visita),
        ),
        Expanded(
          flex: 2,
          child: AlertaVisitaBadge(tipo: visita.alerta),
        ),
        _VisitaAcciones(visita: visita),
      ],
    );
  }
}

class _VisitaRowCompact extends StatelessWidget {
  final VisitaSeguimientoMock visita;

  const _VisitaRowCompact({required this.visita});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                visita.cliente,
                style: AppTextStyles.input.copyWith(fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            _EstadoBadge(visita: visita),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${visita.sucursal} · Nº ${visita.numeroSucursal} · Prog. ${visita.horaProgramada}',
          style: AppTextStyles.desktopSubtitle.copyWith(fontSize: 11),
        ),
        if (visita.tieneAlerta) ...[
          const SizedBox(height: 6),
          AlertaVisitaBadge(tipo: visita.alerta),
        ],
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerRight,
          child: _VisitaAcciones(visita: visita),
        ),
      ],
    );
  }
}

class _EstadoBadge extends StatelessWidget {
  final VisitaSeguimientoMock visita;

  const _EstadoBadge({required this.visita});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: visita.estado.color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        visita.estado.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: visita.estado.color,
        ),
      ),
    );
  }
}

class _VisitaAcciones extends StatelessWidget {
  final VisitaSeguimientoMock visita;

  const _VisitaAcciones({required this.visita});

  void _proximamente(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Esta acción se habilitará junto con el canal de tiempo real.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Editar',
          onPressed: () => _proximamente(context),
          icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.inputHint),
        ),
        IconButton(
          tooltip: 'Eliminar',
          onPressed: () => _proximamente(context),
          icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.inputHint),
        ),
      ],
    );
  }
}
