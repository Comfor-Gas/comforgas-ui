import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/mock_chofer_data.dart';
import '../../models/visita_estado.dart';
import '../../models/visita_model.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/visita_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/chofer/visita_cliente_card.dart';
import '../../widgets/chofer/visita_estado_chip.dart';

const List<String> _diasSemana = [
  'Lunes',
  'Martes',
  'Miércoles',
  'Jueves',
  'Viernes',
  'Sábado',
  'Domingo',
];

const List<String> _meses = [
  'Enero',
  'Febrero',
  'Marzo',
  'Abril',
  'Mayo',
  'Junio',
  'Julio',
  'Agosto',
  'Septiembre',
  'Octubre',
  'Noviembre',
  'Diciembre',
];

class AgendaChoferScreen extends StatefulWidget {
  const AgendaChoferScreen({super.key});

  @override
  State<AgendaChoferScreen> createState() => _AgendaChoferScreenState();
}

class _AgendaChoferScreenState extends State<AgendaChoferScreen> {
  late final VisitaRepository _repo;
  final _searchCtrl = TextEditingController();

  bool _loading = true;
  String? _error;
  List<VisitaModel> _visitas = [];

  @override
  void initState() {
    super.initState();
    _repo = VisitaRepository(context.read<AuthProvider>().apiClient);
    _searchCtrl.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final auth = context.read<AuthProvider>();
    final idUsuario = auth.user?.id;
    if (idUsuario == null || idUsuario.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'No se pudo identificar al chofer autenticado.';
      });
      return;
    }

    try {
      final data = await _repo.getVisitasPorUsuarioYFecha(
        idUsuario: idUsuario,
        fecha: DateTime.now(),
      );
      data.sort((a, b) => a.ordenVisita.compareTo(b.ordenVisita));
      if (!mounted) return;
      setState(() {
        _visitas = data;
        _loading = false;
      });
    } on VisitaRepositoryException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo cargar la ruta del día.';
        _loading = false;
      });
    }
  }

  String _nombreCliente(VisitaModel v) {
    for (final key in ['nombre', 'nombreSucursal', 'razonSocial', 'cliente']) {
      final value = v.sucursalSnapshot[key];
      if (value is String && value.trim().isNotEmpty) return value;
    }
    return 'Sucursal #${v.idSucursal}';
  }

  String _direccionCliente(VisitaModel v) {
    for (final key in ['direccion', 'domicilio', 'address']) {
      final value = v.sucursalSnapshot[key];
      if (value is String && value.trim().isNotEmpty) return value;
    }
    return 'Sin dirección registrada';
  }

  List<VisitaModel> get _visitasFiltradas {
    final query = _searchCtrl.text.trim().toLowerCase();
    if (query.isEmpty) return _visitas;
    return _visitas.where((v) {
      return _nombreCliente(v).toLowerCase().contains(query) ||
          _direccionCliente(v).toLowerCase().contains(query);
    }).toList();
  }

  VisitaModel? get _siguienteVisita {
    for (final v in _visitas) {
      if (v.estadoVisita == VisitaEstado.pendiente) return v;
    }
    return null;
  }

  void _handleIniciarSiguiente() {
    final siguiente = _siguienteVisita;
    if (siguiente == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No quedan visitas pendientes por hoy.')),
      );
      return;
    }
    _mostrarDetalle(siguiente);
  }

  void _mostrarDetalle(VisitaModel visita) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _DetalleVisitaSheet(
        nombreCliente: _nombreCliente(visita),
        direccionCliente: _direccionCliente(visita),
        orden: visita.ordenVisita,
        estado: visita.estadoVisita,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final nombreChofer = auth.user?.fullName?.trim().isNotEmpty == true
        ? auth.user!.fullName!
        : (auth.user?.email ?? 'Chofer');
    final patente = mockPatenteFor(auth.user?.id ?? nombreChofer);

    final now = DateTime.now();
    final fechaTexto =
        '${_diasSemana[now.weekday - 1]}, ${now.day} de ${_meses[now.month - 1]} ${now.year}';

    final visitasOrdenadas = _visitasFiltradas;
    final completadas =
        _visitas.where((v) => v.estadoVisita == VisitaEstado.completada).length;
    final recaudacion = completadas * mockMontoPromedioPorVisita;
    final siguiente = _siguienteVisita;

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
            _AgendaHeader(nombreChofer: nombreChofer, patente: patente),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _load,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ruta del Día', style: AppTextStyles.title.copyWith(fontSize: 24)),
                      const SizedBox(height: 2),
                      Text(fechaTexto, style: AppTextStyles.link),
                      const SizedBox(height: 16),
                      _StatsCard(
                        clientes: _visitas.length,
                        pedidos: completadas,
                        recaudacion: recaudacion,
                      ),
                      const SizedBox(height: 16),
                      _SearchField(controller: _searchCtrl),
                      const SizedBox(height: 16),
                      if (_loading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (_error != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 30),
                          child: Column(
                            children: [
                              Text(
                                _error!,
                                style: AppTextStyles.errorText,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton(
                                onPressed: _load,
                                child: const Text('Reintentar'),
                              ),
                            ],
                          ),
                        )
                      else if (visitasOrdenadas.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 30),
                          child: Center(
                            child: Text(
                              _visitas.isEmpty
                                  ? 'No tenés visitas asignadas para hoy.'
                                  : 'No encontramos clientes con ese criterio.',
                              style: AppTextStyles.link,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      else
                        ...visitasOrdenadas.map(
                          (v) => VisitaClienteCard(
                            visita: v,
                            nombreCliente: _nombreCliente(v),
                            direccionCliente: _direccionCliente(v),
                            esSiguiente: siguiente != null && siguiente.idVisita == v.idVisita,
                            onTap: () => _mostrarDetalle(v),
                          ),
                        ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _handleIniciarSiguiente,
                  icon: const Icon(Icons.place_outlined),
                  label: const Text('INICIAR SIGUIENTE VISITA'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: AppTextStyles.button,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
  }
}

class _AgendaHeader extends StatelessWidget {
  final String nombreChofer;
  final String patente;

  const _AgendaHeader({required this.nombreChofer, required this.patente});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
      decoration: const BoxDecoration(
        color: AppColors.steelBlue,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            padding: const EdgeInsets.all(5),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Image.asset(
              'assets/images/logomolecula.png',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 13, color: Colors.white),
                    children: [
                      const TextSpan(text: 'Chofer: '),
                      TextSpan(
                        text: nombreChofer,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 13, color: Colors.white),
                    children: [
                      const TextSpan(text: 'Transporte Patente: '),
                      TextSpan(
                        text: patente,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
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

class _StatsCard extends StatelessWidget {
  final int clientes;
  final int pedidos;
  final double recaudacion;

  const _StatsCard({
    required this.clientes,
    required this.pedidos,
    required this.recaudacion,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatItem(label: 'Clientes a\nVisitar', value: '$clientes'),
          ),
          const _StatDivider(),
          Expanded(
            child: _StatItem(label: 'Pedidos\nRealizados', value: '$pedidos'),
          ),
          const _StatDivider(),
          Expanded(
            child: _StatItem(
              label: 'Recaudación:',
              value: '\$${recaudacion.toStringAsFixed(0)}',
            ),
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 44, color: AppColors.inputBorder);
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyles.link.copyWith(fontSize: 12),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: AppTextStyles.title.copyWith(fontSize: 18),
        ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;

  const _SearchField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: TextField(
        controller: controller,
        style: AppTextStyles.input,
        decoration: InputDecoration(
          hintText: 'Buscar cliente o dirección',
          hintStyle: AppTextStyles.hint,
          prefixIcon: const Icon(Icons.search, color: AppColors.inputHint),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close, color: AppColors.inputHint, size: 18),
                  onPressed: controller.clear,
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

class _DetalleVisitaSheet extends StatelessWidget {
  final String nombreCliente;
  final String direccionCliente;
  final int orden;
  final VisitaEstado estado;

  const _DetalleVisitaSheet({
    required this.nombreCliente,
    required this.direccionCliente,
    required this.orden,
    required this.estado,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.inputBorder,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text('Parada N° $orden', style: AppTextStyles.link),
          const SizedBox(height: 4),
          Text(nombreCliente, style: AppTextStyles.title.copyWith(fontSize: 20)),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: AppColors.graphiteGray),
              const SizedBox(width: 6),
              Expanded(child: Text(direccionCliente, style: AppTextStyles.input)),
            ],
          ),
          const SizedBox(height: 12),
          VisitaEstadoChip(estado: estado),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.steelBlue,
                side: const BorderSide(color: AppColors.steelBlue),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Cerrar'),
            ),
          ),
        ],
      ),
    );
  }
}
