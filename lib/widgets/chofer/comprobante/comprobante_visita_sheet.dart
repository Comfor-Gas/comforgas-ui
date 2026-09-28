import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/comprobante_visita.dart';
import '../../../models/motivo_sin_operar.dart';
import '../../../models/visita_estado.dart';
import '../../../models/visita_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../repositories/comprobante_repository.dart';
import '../../../repositories/network_exception.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../utils/date_format_utils.dart';
import '../../../utils/formato.dart';
import '../../../utils/json_parsing.dart';
import '../visita_estado_chip.dart';
import '../../common/carga/zona_carga.dart';
import 'comprobante_secciones.dart';

class ComprobanteVisitaSheet extends StatefulWidget {
  final VisitaModel visita;
  final String nombreCliente;
  final String direccionCliente;

  const ComprobanteVisitaSheet({
    super.key,
    required this.visita,
    required this.nombreCliente,
    required this.direccionCliente,
  });

  static Future<void> mostrar(
    BuildContext context, {
    required VisitaModel visita,
    required String nombreCliente,
    required String direccionCliente,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ComprobanteVisitaSheet(
        visita: visita,
        nombreCliente: nombreCliente,
        direccionCliente: direccionCliente,
      ),
    );
  }

  @override
  State<ComprobanteVisitaSheet> createState() => _ComprobanteVisitaSheetState();
}

class _ComprobanteVisitaSheetState extends State<ComprobanteVisitaSheet> {
  ComprobanteVisita? _comprobante;
  String? _error;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    if (widget.visita.idVisita == null) {
      _cargando = false;
      _error =
          'La visita todavía no se sincronizó con el servidor. El comprobante va a estar disponible cuando haya señal.';
    } else {
      _cargar();
    }
  }

  Future<void> _cargar() async {
    final idVisita = widget.visita.idVisita;
    if (idVisita == null) return;
    if (_error != null) {
      setState(() {
        _cargando = true;
        _error = null;
      });
    }
    try {
      final apiClient = context.read<AuthProvider>().apiClient;
      final comprobante = await ComprobanteRepository(apiClient).obtener(idVisita);
      if (!mounted) return;
      setState(() {
        _comprobante = comprobante;
        _cargando = false;
      });
    } on NetworkException {
      if (!mounted) return;
      setState(() {
        _error = 'Sin conexión: conectate para ver el comprobante de esta visita.';
        _cargando = false;
      });
    } on ComprobanteRepositoryException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _cargando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo cargar el comprobante.';
        _cargando = false;
      });
    }
  }

  Map<String, int> get _cobrosPorMetodo {
    final raw = widget.visita.sucursalSnapshot['cobrosPorMetodo'];
    final resultado = <String, int>{};
    if (raw is Map) {
      raw.forEach((k, v) {
        final monto = parseInt(v) ?? 0;
        if (monto > 0) resultado[k.toString()] = monto;
      });
    }
    return resultado;
  }

  int get _montoCobrado => parseInt(widget.visita.sucursalSnapshot['montoCobrado']) ?? 0;

  String _etiquetaMotivo(String codigo) {
    for (final m in MotivoSinOperar.opciones) {
      if (m.codigo == codigo.toUpperCase()) return m.etiqueta;
    }
    return codigo;
  }

  String _etiquetaMetodo(String metodo) {
    final m = metodo.toUpperCase();
    if (m.isEmpty) return metodo;
    return m[0] + m.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final alto = MediaQuery.of(context).size.height * 0.88;
    return Container(
      constraints: BoxConstraints(maxHeight: alto),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: _Encabezado(
                visita: widget.visita,
                nombreCliente: widget.nombreCliente,
                direccionCliente: widget.direccionCliente,
              ),
            ),
            const Divider(height: 1, color: AppColors.inputBorder),
            BarraCarga(visible: _cargando),
            Flexible(child: _cuerpo()),
          ],
        ),
      ),
    );
  }

  Widget _cuerpo() {
    if (_cargando) {
      return const SizedBox(height: 132);
    }
    final error = _error;
    if (error != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.receipt_long_outlined, size: 44, color: AppColors.inputHint),
            const SizedBox(height: 12),
            Text(error, textAlign: TextAlign.center, style: AppTextStyles.link),
            if (widget.visita.idVisita != null) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: _cargar,
                child: const Text(
                  'REINTENTAR',
                  style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.orange),
                ),
              ),
            ],
          ],
        ),
      );
    }
    final c = _comprobante!;
    final usaCobrosBackend = c.cobrosPorMetodo.isNotEmpty;
    final cobros = usaCobrosBackend ? c.cobrosPorMetodo : _cobrosPorMetodo;
    final totalCobrado = usaCobrosBackend
        ? c.totalCobrado
        : (_montoCobrado > 0 ? _montoCobrado : cobros.values.fold<int>(0, (a, v) => a + v));
    final motivo = c.motivoNoAsistencia;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (motivo != null)
            ComprobanteSeccion(
              titulo: 'Visita sin operar',
              icono: Icons.do_not_disturb_on_outlined,
              child: ComprobanteDato(
                etiqueta: 'Motivo',
                valor: _etiquetaMotivo(motivo),
              ),
            ),
          ComprobanteSeccion(
            titulo: 'Ventas',
            icono: Icons.shopping_bag_outlined,
            child: c.ventas.isEmpty
                ? Text(
                    'No se registraron ventas en esta visita.',
                    style: AppTextStyles.footer.copyWith(color: AppColors.graphiteGray),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < c.ventas.length; i++)
                        ComprobanteVentaBloque(
                          venta: c.ventas[i],
                          numero: i + 1,
                          mostrarEncabezado: c.ventas.length > 1,
                        ),
                      const Divider(height: 16, color: AppColors.inputBorder),
                      ComprobanteDato(etiqueta: 'Garrafas llenas entregadas', valor: '${c.llenasEntregadas}'),
                      ComprobanteDato(etiqueta: 'Envases vacíos recibidos', valor: '${c.vaciasRecibidas}'),
                      if (c.envasesEnPrestamo > 0)
                        ComprobanteDato(etiqueta: 'Envases en préstamo', valor: '${c.envasesEnPrestamo}'),
                      ComprobanteDato(
                        etiqueta: 'Total vendido',
                        valor: formatMoneda(c.montoTotal),
                        destacado: true,
                      ),
                    ],
                  ),
          ),
          if (totalCobrado > 0 || cobros.isNotEmpty)
            ComprobanteSeccion(
              titulo: 'Cobrado',
              icono: Icons.payments_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final e in cobros.entries)
                    ComprobanteDato(etiqueta: _etiquetaMetodo(e.key), valor: formatMoneda(e.value)),
                  ComprobanteDato(
                    etiqueta: 'Total cobrado',
                    valor: formatMoneda(totalCobrado),
                    destacado: true,
                  ),
                ],
              ),
            ),
          if (c.canjes.isNotEmpty)
            ComprobanteSeccion(
              titulo: 'Canjes por daño',
              icono: Icons.swap_horiz,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final canje in c.canjes)
                    ComprobanteDato(
                      etiqueta: canje.danio != null ? '${canje.descripcion} · ${canje.danio}' : canje.descripcion,
                      valor: '1',
                    ),
                ],
              ),
            ),
          if (c.comodato != null)
            ComprobanteSeccion(
              titulo: 'Control de comodato',
              icono: Icons.inventory_2_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ComprobanteDato(etiqueta: 'Contratadas', valor: '${c.comodato!.cantidadContratada}'),
                  ComprobanteDato(etiqueta: 'Contadas en el punto', valor: '${c.comodato!.cantidadFisica}'),
                  if (c.comodato!.faltante > 0)
                    ComprobanteDato(etiqueta: 'Faltante', valor: '${c.comodato!.faltante}'),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Encabezado extends StatelessWidget {
  final VisitaModel visita;
  final String nombreCliente;
  final String direccionCliente;

  const _Encabezado({
    required this.visita,
    required this.nombreCliente,
    required this.direccionCliente,
  });

  @override
  Widget build(BuildContext context) {
    final fin = visita.timestampFin ?? visita.timestampInicio;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.receipt_long, color: AppColors.orange, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Text('Comprobante de visita', style: AppTextStyles.title.copyWith(fontSize: 18)),
            ),
            VisitaEstadoChip(estado: visita.estadoVisita),
          ],
        ),
        const SizedBox(height: 10),
        Text(nombreCliente, style: AppTextStyles.label.copyWith(fontSize: 15)),
        const SizedBox(height: 2),
        Text(
          direccionCliente,
          style: AppTextStyles.footer.copyWith(color: AppColors.graphiteGray),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (fin != null) ...[
          const SizedBox(height: 4),
          Text(
            '${formatFechaCorta(fin.toLocal())} · ${formatHora12(fin.toLocal())}'
            '${visita.estadoVisita == VisitaEstado.cancelada ? ' · Visita cancelada' : ''}',
            style: AppTextStyles.footer.copyWith(color: AppColors.steelBlue, fontWeight: FontWeight.w600),
          ),
        ],
      ],
    );
  }
}
