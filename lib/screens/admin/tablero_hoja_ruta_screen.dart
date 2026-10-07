import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/responsive.dart';
import '../../data/mock_chofer_data.dart';
import '../../models/visita_estado.dart';
import '../../models/usuario_model.dart';
import '../../models/visita_model.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/catalogo_repository.dart';
import '../../repositories/visita_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/admin/estado_visita_badge.dart';
import '../../widgets/common/carga/zona_carga.dart';
import '../../widgets/common/filtros/filtros.dart';
import '../../utils/orden_visitas.dart';

class _HojaRuta {
  final String choferNombre;
  final int idRuta;
  final String zona;
  final String vendedor;
  final String acompanante;
  final String movil;
  final List<VisitaModel> visitas;

  const _HojaRuta({
    required this.choferNombre,
    required this.idRuta,
    required this.zona,
    required this.vendedor,
    required this.acompanante,
    required this.movil,
    required this.visitas,
  });
}

class TableroHojaRutaScreen extends StatefulWidget {
  const TableroHojaRutaScreen({super.key});

  @override
  State<TableroHojaRutaScreen> createState() => _TableroHojaRutaScreenState();
}

class _TableroHojaRutaScreenState extends State<TableroHojaRutaScreen> {
  late final VisitaRepository _visitaRepo;
  late final CatalogoRepository _catalogoRepo;
  final TextEditingController _filtroCtrl = TextEditingController();

  bool _loading = true;
  String? _error;
  List<VisitaModel> _visitas = [];
  List<UsuarioModel>? _choferes;
  Map<int, String> _rutaNombre = {};
  String? _estadoFilter;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _visitaRepo = VisitaRepository(auth.apiClient);
    _catalogoRepo = CatalogoRepository(auth.apiClient);
    _filtroCtrl.addListener(() => setState(() {}));
    _cargar();
  }

  @override
  void dispose() {
    _filtroCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final rutasFuture = _catalogoRepo
        .listarRutas()
        .then((rutas) => {for (final r in rutas) r.idRuta: r.nombre})
        .catchError((_) => <int, String>{});

    List<VisitaModel> visitasDelDia;
    try {
      final choferes = _choferes ??= await _catalogoRepo.listarUsuarios(rol: 'CHOFER');
      final hoy = DateTime.now();
      final listas = await Future.wait(
        choferes.map(
          (ch) => _visitaRepo
              .getVisitasPorUsuarioYFecha(idUsuario: ch.id, fecha: hoy)
              .then((items) => items.map((i) {
                    final base = i.toVisitaModel(ch.id);
                    return base.copyWith(
                      nombreUsuario: ch.fullName,
                      rutaSnapshot: {
                        ...base.rutaSnapshot,
                        if (i.movil != null) 'movil': i.movil,
                        if (i.patente != null && i.patente!.trim().isNotEmpty) 'patente': i.patente,
                      },
                    );
                  }).toList())
              .catchError((_) => <VisitaModel>[]),
        ),
      );
      visitasDelDia = [for (final l in listas) ...l];
    } on CatalogoRepositoryException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
      return;
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo cargar la agenda de las hojas de ruta.';
        _loading = false;
      });
      return;
    }

    final rutaNombre = await rutasFuture;

    if (!mounted) return;
    setState(() {
      _rutaNombre = rutaNombre;
      _visitas = visitasDelDia;
      _loading = false;
    });
  }

  String _textoSnapshot(Map<String, dynamic> snapshot, List<String> claves) {
    for (final clave in claves) {
      final valor = snapshot[clave];
      if (valor is String && valor.trim().isNotEmpty) return valor.trim();
      if (valor is num) return valor.toString();
    }
    return '';
  }

  String _clienteNombre(VisitaModel v) {
    final texto = _textoSnapshot(
        v.sucursalSnapshot, ['nombre', 'nombreSucursal', 'razonSocial', 'cliente']);
    return texto.isNotEmpty ? texto : 'Sucursal #${v.idSucursal}';
  }

  String _domicilio(VisitaModel v) {
    final texto = _textoSnapshot(v.sucursalSnapshot, ['direccion', 'domicilio', 'address']);
    return texto.isNotEmpty ? texto : 'Sin dirección';
  }

  String _barrio(VisitaModel v) {
    final texto = _textoSnapshot(v.sucursalSnapshot, ['barrio', 'zona']);
    return texto.isNotEmpty ? texto : '—';
  }

  String _zona(int idRuta) {
    final nombre = _rutaNombre[idRuta];
    if (nombre == null || nombre.trim().isEmpty) return 'Ruta $idRuta';
    return '$idRuta ${nombre.toUpperCase()}';
  }

  String _movil(List<VisitaModel> visitas, int idRuta) {
    for (final v in visitas) {
      final valor = v.rutaSnapshot['movil'];
      if (valor is num) return 'N° ${valor.toInt()}';
      if (valor is String && valor.trim().isNotEmpty) return valor.trim();
    }
    return 'N° ${mockMovilFor(idRuta)}';
  }

  String _cabecera(List<VisitaModel> visitas, String clave) {
    for (final v in visitas) {
      final valor = v.rutaSnapshot[clave];
      if (valor is String && valor.trim().isNotEmpty) return valor.trim();
    }
    return '—';
  }

  List<_HojaRuta> get _hojasFiltradas {
    final query = _filtroCtrl.text.trim().toLowerCase();

    final grupos = <String, List<VisitaModel>>{};
    for (final v in _visitas) {
      final chofer = v.nombreUsuario ?? 'Sin asignar';
      grupos.putIfAbsent('$chofer#${v.idRuta}', () => []).add(v);
    }

    final hojas = <_HojaRuta>[];
    grupos.forEach((_, visitasGrupo) {
      ordenarVisitas(visitasGrupo);
      final chofer = visitasGrupo.first.nombreUsuario ?? 'Sin asignar';
      final idRuta = visitasGrupo.first.idRuta;
      final zona = _zona(idRuta);
      final vendedor = _cabecera(visitasGrupo, 'vendedor');
      final acompanante = _cabecera(visitasGrupo, 'acompanante');

      var visitasVisibles = _estadoFilter == null
          ? visitasGrupo
          : visitasGrupo
              .where((v) => VisitaEstadoMapper.toValue(v.estadoVisita) == _estadoFilter)
              .toList();
      if (visitasVisibles.isEmpty) return;

      if (query.isNotEmpty) {
        final coincideCabecera = chofer.toLowerCase().contains(query) ||
            vendedor.toLowerCase().contains(query) ||
            zona.toLowerCase().contains(query);

        if (coincideCabecera) {
        } else {
          visitasVisibles = visitasVisibles
              .where((v) => _clienteNombre(v).toLowerCase().contains(query))
              .toList();
          if (visitasVisibles.isEmpty) return;
        }
      }

      hojas.add(_HojaRuta(
        choferNombre: chofer,
        idRuta: idRuta,
        zona: zona,
        vendedor: vendedor,
        acompanante: acompanante,
        movil: _movil(visitasGrupo, idRuta),
        visitas: visitasVisibles,
      ));
    });

    hojas.sort((a, b) => a.zona.compareTo(b.zona));
    return hojas;
  }

  static const List<OpcionFiltro> _estados = [
    OpcionFiltro('PENDIENTE', 'Pendiente'),
    OpcionFiltro('EN_CURSO', 'En curso'),
    OpcionFiltro('VISITADO', 'Visitado'),
    OpcionFiltro('COMPLETADA', 'Completada'),
    OpcionFiltro('CANCELADA', 'Cancelada'),
    OpcionFiltro('NO_ASISTIO', 'No asistió'),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomSafePadding = MediaQuery.of(context).padding.bottom;

    if (_loading) {
      return ReportarCarga(cargando: _loading);
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: AppTextStyles.errorText),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _cargar,
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

    final hojas = _hojasFiltradas;
    final mobile = Responsive.isMobileContext(context);
    final pad = mobile ? 16.0 : 24.0;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(pad, pad, pad, pad + bottomSafePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ReportarCarga(cargando: _loading),
          Text(
            'Visitas por Hoja de Ruta',
            style: mobile
                ? AppTextStyles.desktopTitle.copyWith(fontSize: 22)
                : AppTextStyles.desktopTitle,
          ),
          const SizedBox(height: 4),
          Text(
            'Agenda del día de cada hoja de ruta, con todos los clientes a visitar en orden de recorrido.',
            style: AppTextStyles.desktopSubtitle,
          ),
          const SizedBox(height: 20),
          _FiltroBar(
            controller: _filtroCtrl,
            estadoFilter: _estadoFilter,
            estados: _estados,
            onEstadoChanged: (v) => setState(() => _estadoFilter = v),
            onLimpiar: () {
              _filtroCtrl.clear();
              setState(() => _estadoFilter = null);
            },
            onRefrescar: _cargar,
            cargando: _loading,
          ),
          const SizedBox(height: 20),
          if (hojas.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 60),
              child: Center(
                child: Text(
                  _visitas.isEmpty
                      ? 'No hay visitas cargadas para hoy.'
                      : 'No hay hojas de ruta para los filtros seleccionados.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.desktopSubtitle,
                ),
              ),
            )
          else
            for (final hoja in hojas) ...[
              _HojaRutaCard(
                key: ValueKey('${hoja.choferNombre}#${hoja.idRuta}'),
                hoja: hoja,
                clienteNombre: _clienteNombre,
                domicilio: _domicilio,
                barrio: _barrio,
              ),
              SizedBox(height: mobile ? 16 : 20),
            ],
        ],
      ),
    );
  }
}

class _FiltroBar extends StatelessWidget {
  final TextEditingController controller;
  final String? estadoFilter;
  final List<OpcionFiltro> estados;
  final ValueChanged<String?> onEstadoChanged;
  final VoidCallback onLimpiar;
  final VoidCallback onRefrescar;
  final bool cargando;

  const _FiltroBar({
    required this.controller,
    required this.estadoFilter,
    required this.estados,
    required this.onEstadoChanged,
    required this.onLimpiar,
    required this.onRefrescar,
    required this.cargando,
  });

  @override
  Widget build(BuildContext context) {
    final hayFiltros = controller.text.trim().isNotEmpty || estadoFilter != null;
    final mobile = Responsive.isMobileContext(context);
    return FiltrosPanel(
      filas: [
        FilaFiltros(
          children: [
            CampoBusquedaFiltro(
              controller: controller,
              etiqueta: 'Buscar hoja de ruta',
              hint: 'Chofer, vendedor, zona o cliente',
              icono: Icons.search,
              ancho: mobile ? double.infinity : 320,
            ),
            FiltroBuscable(
              etiqueta: 'Estado',
              icono: Icons.flag_outlined,
              opciones: estados,
              seleccion: estadoFilter,
              onCambio: onEstadoChanged,
              ancho: mobile ? double.infinity : 200,
            ),
            if (hayFiltros) BotonLimpiarFiltros(onPressed: onLimpiar),
            BotonActualizar(onPressed: onRefrescar, cargando: cargando),
          ],
        ),
      ],
    );
  }
}

class _HojaRutaCard extends StatefulWidget {
  final _HojaRuta hoja;
  final String Function(VisitaModel) clienteNombre;
  final String Function(VisitaModel) domicilio;
  final String Function(VisitaModel) barrio;

  const _HojaRutaCard({
    super.key,
    required this.hoja,
    required this.clienteNombre,
    required this.domicilio,
    required this.barrio,
  });

  @override
  State<_HojaRutaCard> createState() => _HojaRutaCardState();
}

class _HojaRutaCardState extends State<_HojaRutaCard> {
  bool _expandida = true;

  @override
  Widget build(BuildContext context) {
    final hoja = widget.hoja;
    return Container(
      clipBehavior: Clip.antiAlias,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Encabezado(
            hoja: hoja,
            expandida: _expandida,
            onToggle: () => setState(() => _expandida = !_expandida),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _expandida
                ? Padding(
                    padding: Responsive.isMobileContext(context)
                        ? const EdgeInsets.fromLTRB(12, 4, 12, 12)
                        : const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    child: _Tabla(
                      visitas: hoja.visitas,
                      clienteNombre: widget.clienteNombre,
                      domicilio: widget.domicilio,
                      barrio: widget.barrio,
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _Encabezado extends StatelessWidget {
  final _HojaRuta hoja;
  final bool expandida;
  final VoidCallback onToggle;

  const _Encabezado({required this.hoja, required this.expandida, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final mobile = Responsive.isMobileContext(context);
    final datos = [
      _DatoCabecera(label: 'Vendedor', valor: hoja.vendedor),
      _DatoCabecera(label: 'Acompañante', valor: hoja.acompanante),
      _DatoCabecera(label: 'Móvil', valor: hoja.movil),
      _DatoCabecera(label: 'Chofer', valor: hoja.choferNombre),
    ];
    return Material(
      color: AppColors.steelBlue,
      child: InkWell(
        onTap: onToggle,
        hoverColor: Colors.white.withValues(alpha: 0.05),
        child: Container(
          padding: EdgeInsets.all(mobile ? 14 : 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.alt_route_outlined, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      hoja.zona,
                      style: TextStyle(
                        fontSize: mobile ? 15 : 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  if (mobile) const SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: mobile ? 8 : 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${hoja.visitas.where((v) => VisitaEstadoMapper.esTerminadaEnCampo(v.estadoVisita)).length} de ${hoja.visitas.length} visitados',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Tooltip(
                    message: expandida ? 'Plegar lista' : 'Desplegar lista',
                    child: AnimatedRotation(
                      turns: expandida ? 0.5 : 0,
                      duration: const Duration(milliseconds: 220),
                      child: const Icon(Icons.expand_more_rounded, color: Colors.white, size: 24),
                    ),
                  ),
                ],
              ),
              SizedBox(height: mobile ? 12 : 14),
              if (mobile)
                LayoutBuilder(
                  builder: (context, constraints) {
                    const espacio = 16.0;
                    final ancho = (constraints.maxWidth - espacio) / 2;
                    return Wrap(
                      spacing: espacio,
                      runSpacing: 12,
                      children: [
                        for (final dato in datos) SizedBox(width: ancho, child: dato),
                      ],
                    );
                  },
                )
              else
                Wrap(
                  spacing: 28,
                  runSpacing: 12,
                  children: datos,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DatoCabecera extends StatelessWidget {
  final String label;
  final String valor;

  const _DatoCabecera({required this.label, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: Colors.white.withValues(alpha: 0.65),
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          valor,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

const TextStyle _headerCeldaStyle = TextStyle(
  fontSize: 11,
  fontWeight: FontWeight.w800,
  color: AppColors.graphiteGray,
  letterSpacing: 0.5,
);

class _Tabla extends StatelessWidget {
  final List<VisitaModel> visitas;
  final String Function(VisitaModel) clienteNombre;
  final String Function(VisitaModel) domicilio;
  final String Function(VisitaModel) barrio;

  const _Tabla({
    required this.visitas,
    required this.clienteNombre,
    required this.domicilio,
    required this.barrio,
  });

  static const double _wOrden = 72;
  static const double _wEstado = 140;
  static const double _compactBreakpoint = 560;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return constraints.maxWidth < _compactBreakpoint
            ? _buildCompact(context)
            : _buildTabla(context);
      },
    );
  }

  Widget _buildTabla(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.inputBorder)),
          ),
          child: Row(
            children: const [
              SizedBox(
                width: _wOrden,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('ORDEN', style: _headerCeldaStyle),
                ),
              ),
              _Celda(flex: 3, texto: 'CLIENTE', header: true),
              _Celda(flex: 4, texto: 'DOMICILIO', header: true),
              _Celda(flex: 2, texto: 'BARRIO', header: true),
              SizedBox(
                width: _wEstado,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('ESTADO', style: _headerCeldaStyle),
                ),
              ),
            ],
          ),
        ),
        for (int i = 0; i < visitas.length; i++)
          Container(
            color: i.isEven ? AppColors.background : Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                SizedBox(
                  width: _wOrden,
                  child: Center(child: _OrdenChip(orden: visitas[i].ordenVisita)),
                ),
                _Celda(flex: 3, texto: clienteNombre(visitas[i]), bold: true),
                _Celda(flex: 4, texto: domicilio(visitas[i])),
                _Celda(flex: 2, texto: barrio(visitas[i])),
                SizedBox(
                  width: _wEstado,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: EstadoVisitaBadge(estado: visitas[i].estadoVisita),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCompact(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < visitas.length; i++)
          Container(
            margin: EdgeInsets.only(
              top: i == 0 ? 8 : 0,
              bottom: i == visitas.length - 1 ? 0 : 10,
            ),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.inputBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _OrdenChip(orden: visitas[i].ordenVisita),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        clienteNombre(visitas[i]),
                        style: AppTextStyles.input.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _LineaCompacta(label: 'Domicilio', valor: domicilio(visitas[i])),
                const SizedBox(height: 4),
                _LineaCompacta(label: 'Barrio', valor: barrio(visitas[i])),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: EstadoVisitaBadge(estado: visitas[i].estadoVisita),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _LineaCompacta extends StatelessWidget {
  final String label;
  final String valor;

  const _LineaCompacta({required this.label, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 78,
          child: Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: AppColors.graphiteGray,
              letterSpacing: 0.4,
            ),
          ),
        ),
        Expanded(
          child: Text(
            valor,
            style: AppTextStyles.input.copyWith(fontSize: 13),
          ),
        ),
      ],
    );
  }
}

class _Celda extends StatelessWidget {
  final int flex;
  final String texto;
  final bool header;
  final bool bold;

  const _Celda({
    required this.flex,
    required this.texto,
    this.header = false,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          texto,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: header
              ? _headerCeldaStyle
              : AppTextStyles.input.copyWith(
                  fontSize: 13,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
                ),
        ),
      ),
    );
  }
}

class _OrdenChip extends StatelessWidget {
  final int orden;

  const _OrdenChip({required this.orden});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.orange.withValues(alpha: 0.1),
        border: Border.all(color: AppColors.orange, width: 1.4),
      ),
      child: Text(
        '$orden',
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: AppColors.orange,
        ),
      ),
    );
  }
}
