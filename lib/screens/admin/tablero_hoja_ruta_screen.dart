import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/mock_chofer_data.dart';
import '../../models/ruta_model.dart';
import '../../models/visita_estado.dart';
import '../../models/visita_model.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/catalogo_repository.dart';
import '../../repositories/visita_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/admin/estado_visita_badge.dart';
import '../../widgets/labeled_text_field.dart';

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
    try {
      final resultados = await Future.wait([
        _visitaRepo.listarTodas(),
        _catalogoRepo.listarRutas(),
      ]);
      if (!mounted) return;
      final todas = resultados[0] as List<VisitaModel>;
      final rutas = resultados[1] as List<RutaModel>;
      final hoy = DateTime.now();
      setState(() {
        _rutaNombre = {for (final r in rutas) r.idRuta: r.nombre};
        _visitas = todas.where((v) {
          final f = v.fecha;
          return f != null &&
              f.year == hoy.year &&
              f.month == hoy.month &&
              f.day == hoy.day;
        }).toList();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo cargar el tablero de hojas de ruta.';
        _loading = false;
      });
    }
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
      visitasGrupo.sort((a, b) => a.ordenVisita.compareTo(b.ordenVisita));
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

  static const List<(String, String)> _estados = [
    ('PENDIENTE', 'Pendiente'),
    ('EN_CURSO', 'En curso'),
    ('VISITADO', 'Visitado'),
    ('COMPLETADA', 'Completada'),
    ('CANCELADA', 'Cancelada'),
    ('NO_ASISTIO', 'No asistió'),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomSafePadding = MediaQuery.of(context).padding.bottom;

    if (_loading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.orange));
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

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomSafePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Visitas por Hoja de Ruta', style: AppTextStyles.desktopTitle),
          const SizedBox(height: 4),
          Text(
            'Encabezado de cada hoja de ruta y sus visitas ordenadas por orden de recorrido.',
            style: AppTextStyles.desktopSubtitle,
          ),
          const SizedBox(height: 20),
          _FiltroBar(
            controller: _filtroCtrl,
            estadoFilter: _estadoFilter,
            estados: _estados,
            onEstadoChanged: (v) => setState(() => _estadoFilter = v),
            onRefrescar: _cargar,
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
                  style: AppTextStyles.desktopSubtitle,
                ),
              ),
            )
          else
            for (final hoja in hojas) ...[
              _HojaRutaCard(
                hoja: hoja,
                clienteNombre: _clienteNombre,
                domicilio: _domicilio,
                barrio: _barrio,
              ),
              const SizedBox(height: 20),
            ],
        ],
      ),
    );
  }
}

class _FiltroBar extends StatelessWidget {
  final TextEditingController controller;
  final String? estadoFilter;
  final List<(String, String)> estados;
  final ValueChanged<String?> onEstadoChanged;
  final VoidCallback onRefrescar;

  const _FiltroBar({
    required this.controller,
    required this.estadoFilter,
    required this.estados,
    required this.onEstadoChanged,
    required this.onRefrescar,
  });

  Widget _buscador() {
    return LabeledTextField(
      label: 'Buscar hoja de ruta',
      hint: 'Chofer, vendedor, zona o cliente',
      icon: Icons.search,
      controller: controller,
    );
  }

  Widget _estadoDropdown() {
    return Column(
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
                for (final (value, label) in estados)
                  DropdownMenuItem<String?>(value: value, child: Text(label)),
              ],
              onChanged: onEstadoChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _botonActualizar({bool expandido = false}) {
    final boton = OutlinedButton.icon(
      onPressed: onRefrescar,
      icon: const Icon(Icons.refresh, size: 18),
      label: const Text('Actualizar'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.steelBlue,
        side: const BorderSide(color: AppColors.steelBlue),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    return expandido ? SizedBox(width: double.infinity, child: boton) : boton;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 640;

          if (narrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buscador(),
                const SizedBox(height: 12),
                _estadoDropdown(),
                const SizedBox(height: 12),
                _botonActualizar(expandido: true),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: _buscador()),
              const SizedBox(width: 12),
              SizedBox(width: 180, child: _estadoDropdown()),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: _botonActualizar(),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HojaRutaCard extends StatelessWidget {
  final _HojaRuta hoja;
  final String Function(VisitaModel) clienteNombre;
  final String Function(VisitaModel) domicilio;
  final String Function(VisitaModel) barrio;

  const _HojaRutaCard({
    required this.hoja,
    required this.clienteNombre,
    required this.domicilio,
    required this.barrio,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Encabezado(hoja: hoja),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: _Tabla(
              visitas: hoja.visitas,
              clienteNombre: clienteNombre,
              domicilio: domicilio,
              barrio: barrio,
            ),
          ),
        ],
      ),
    );
  }
}

class _Encabezado extends StatelessWidget {
  final _HojaRuta hoja;

  const _Encabezado({required this.hoja});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: const BoxDecoration(
        color: AppColors.steelBlue,
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
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
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${hoja.visitas.length} visita(s)',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 28,
            runSpacing: 12,
            children: [
              _DatoCabecera(label: 'Vendedor', valor: hoja.vendedor),
              _DatoCabecera(label: 'Acompañante', valor: hoja.acompanante),
              _DatoCabecera(label: 'Móvil', valor: hoja.movil),
              _DatoCabecera(label: 'Chofer', valor: hoja.choferNombre),
            ],
          ),
        ],
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
            color: Colors.white.withOpacity(0.65),
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
        color: AppColors.orange.withOpacity(0.1),
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
