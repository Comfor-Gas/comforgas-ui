import 'dart:async' show StreamSubscription, unawaited;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../local/cobro_offline_service.dart';
import '../../../local/cobro_pendiente.dart';
import '../../../models/credito_cliente.dart';
import '../../../models/metodo_pago.dart';
import '../../../providers/auth_provider.dart';
import '../../../repositories/cobro_repository.dart';
import '../../../repositories/network_exception.dart';
import '../../../services/connectivity_service.dart';
import '../../../services/cobro_sync_manager.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../utils/formato.dart';
import '../../../widgets/chofer/cobro/cobro_pendiente_indicator.dart';
import '../../../widgets/chofer/cobro/metodo_pago_selector.dart';
import '../../../widgets/chofer/cobro/morosidad_banner.dart';
import '../../../widgets/primary_button.dart';

const _uuid = Uuid();

class RegistroCobroScreen extends StatefulWidget {
  final int? idVenta;
  final String? uuidVentaOffline;
  final String nombreCliente;
  final int montoSugerido;
  final CreditoCliente credito;

  const RegistroCobroScreen({
    super.key,
    this.idVenta,
    this.uuidVentaOffline,
    required this.nombreCliente,
    required this.montoSugerido,
    this.credito = const CreditoCliente(),
  }) : assert(
          (idVenta == null) != (uuidVentaOffline == null),
          'Informá exactamente uno entre idVenta y uuidVentaOffline',
        );

  bool get ventaPendienteDeSync => idVenta == null;

  @override
  State<RegistroCobroScreen> createState() => _RegistroCobroScreenState();
}

class _LineaPago {
  MetodoPago metodo;
  final TextEditingController montoCtrl;

  _LineaPago({required this.metodo, int monto = 0})
      : montoCtrl = TextEditingController(text: monto > 0 ? '$monto' : '');

  int get monto => int.tryParse(montoCtrl.text.trim()) ?? 0;
}

class _ResultadoLinea {
  final MetodoPago metodo;
  final int monto;
  final bool pendiente;
  final String? error;

  const _ResultadoLinea({
    required this.metodo,
    required this.monto,
    this.pendiente = false,
    this.error,
  });

  bool get ok => error == null;
}

class _RegistroCobroScreenState extends State<RegistroCobroScreen> {
  late final CobroRepository _repo;
  StreamSubscription<bool>? _conexionSub;

  final List<_LineaPago> _lineas = [];
  List<_ResultadoLinea>? _resultados;
  bool _online = true;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _repo = CobroRepository(context.read<AuthProvider>().apiClient);
    _lineas.add(_LineaPago(metodo: MetodoPago.efectivo, monto: widget.montoSugerido));
    ConnectivityService.instance.tieneConexion().then((v) {
      if (mounted) setState(() => _online = v);
    });
    _conexionSub = ConnectivityService.instance.observarConexion().listen((v) {
      if (mounted) setState(() => _online = v);
    });
  }

  @override
  void dispose() {
    for (final l in _lineas) {
      l.montoCtrl.dispose();
    }
    _conexionSub?.cancel();
    super.dispose();
  }

  int get _total => widget.montoSugerido;
  int get _asignado => _lineas.fold(0, (a, l) => a + l.monto);
  int get _restante => _total - _asignado;
  bool get _puedeGuardar => _total > 0 ? _asignado == _total : _asignado > 0;

  void _agregarLinea(MetodoPago metodo, int monto) {
    setState(() => _lineas.add(_LineaPago(metodo: metodo, monto: monto)));
  }

  void _quitarLinea(int index) {
    setState(() => _lineas.removeAt(index).montoCtrl.dispose());
  }

  Future<bool> _registrarUno(
      MetodoPago metodo, int monto, String uuid, DateTime ahora) async {
    if (widget.ventaPendienteDeSync) {
      await CobroOfflineService.instance.encolar(
        CobroPendiente(
          uuidOffline: uuid,
          uuidVentaOffline: widget.uuidVentaOffline,
          metodoPago: metodo.codigoBackend,
          monto: monto,
          timestampCobro: ahora,
          creadoEn: ahora,
        ),
      );
      unawaited(CobroSyncManager.instance.sincronizar());
      return true;
    }
    try {
      await _repo.registrar(
        idVenta: widget.idVenta!,
        metodoPago: metodo.codigoBackend,
        monto: monto,
        timestampCobro: ahora,
        uuidOffline: uuid,
      );
      return false;
    } on NetworkException {
      await CobroOfflineService.instance.encolar(
        CobroPendiente(
          uuidOffline: uuid,
          idVenta: widget.idVenta,
          metodoPago: metodo.codigoBackend,
          monto: monto,
          timestampCobro: ahora,
          creadoEn: ahora,
        ),
      );
      unawaited(CobroSyncManager.instance.sincronizar());
      return true;
    }
  }

  Future<void> _registrar() async {
    final lineas = _lineas.where((l) => l.monto > 0).toList();
    if (lineas.isEmpty) {
      _mostrarError('Ingresá al menos un pago.');
      return;
    }
    if (_total > 0 && _asignado != _total) {
      _mostrarError(_asignado > _total
          ? 'La suma de los pagos supera el total de la venta.'
          : 'Falta asignar ${formatMoneda(_total - _asignado)}. Sumá un pago o poné el resto en Cuenta Corriente.');
      return;
    }

    setState(() => _guardando = true);
    final ahora = DateTime.now();
    final resultados = <_ResultadoLinea>[];

    for (final l in lineas) {
      final uuid = _uuid.v4();
      try {
        final pendiente = await _registrarUno(l.metodo, l.monto, uuid, ahora);
        resultados.add(_ResultadoLinea(metodo: l.metodo, monto: l.monto, pendiente: pendiente));
      } on CobroRepositoryException catch (e) {
        resultados.add(_ResultadoLinea(metodo: l.metodo, monto: l.monto, error: e.message));
      } catch (_) {
        resultados.add(_ResultadoLinea(
            metodo: l.metodo, monto: l.monto, error: 'No se pudo registrar este pago.'));
      }
    }

    if (!mounted) return;
    setState(() {
      _resultados = resultados;
      _guardando = false;
    });
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final enConfirmacion = _resultados != null;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.steelBlue,
        foregroundColor: AppColors.white,
        elevation: 0,
        automaticallyImplyLeading: !enConfirmacion,
        title: const Text('Cobro de Venta'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: enConfirmacion ? _buildConfirmacion() : _buildFormulario(),
        ),
      ),
    );
  }

  Widget _buildFormulario() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ClienteHeader(nombre: widget.nombreCliente),
        const SizedBox(height: 14),
        if (widget.credito.tieneAlerta) ...[
          MorosidadBanner(credito: widget.credito),
          const SizedBox(height: 14),
        ],
        if (widget.ventaPendienteDeSync) ...[
          const _VentaPendienteAviso(),
          const SizedBox(height: 14),
        ] else if (!_online) ...[
          const _SinConexionAviso(),
          const SizedBox(height: 14),
        ],
        _ResumenAsignacion(total: _total, asignado: _asignado, restante: _restante),
        const SizedBox(height: 16),
        for (int i = 0; i < _lineas.length; i++) _lineaCard(i),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _agregarLinea(
                  MetodoPago.efectivo,
                  _restante > 0 ? _restante : 0,
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Agregar pago'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.steelBlue,
                  side: const BorderSide(color: AppColors.steelBlue),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
        if (_restante > 0) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _agregarLinea(MetodoPago.cuentaCorriente, _restante),
              icon: const Icon(Icons.account_balance_outlined, size: 18),
              label: Text('Poner el resto en Cuenta Corriente (${formatMoneda(_restante)})'),
              style: TextButton.styleFrom(foregroundColor: AppColors.orange),
            ),
          ),
        ],
        if (_total > 0 && _restante != 0) ...[
          const SizedBox(height: 16),
          Text(
            _restante > 0
                ? 'Falta asignar ${formatMoneda(_restante)} para llegar al total. Sumá un pago o poné el resto en Cuenta Corriente.'
                : 'La suma supera el total en ${formatMoneda(-_restante)}.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: _restante > 0 ? AppColors.badgeAmber : AppColors.error,
            ),
          ),
        ],
        const SizedBox(height: 20),
        PrimaryButton(
          text: (_online && !widget.ventaPendienteDeSync)
              ? 'Registrar cobro'
              : 'Registro Local Seguro',
          isLoading: _guardando,
          onPressed: (_guardando || !_puedeGuardar) ? null : _registrar,
        ),
      ],
    );
  }

  Widget _lineaCard(int index) {
    final linea = _lineas[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Pago ${index + 1}',
                  style: AppTextStyles.label.copyWith(fontSize: 14),
                ),
              ),
              if (_lineas.length > 1)
                InkWell(
                  onTap: () => _quitarLinea(index),
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.delete_outline, size: 20, color: AppColors.graphiteGray),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          MetodoPagoSelector(
            seleccionado: linea.metodo,
            onChanged: (m) => setState(() => linea.metodo = m),
          ),
          const SizedBox(height: 14),
          _MontoLineaField(
            controller: linea.montoCtrl,
            onChanged: () => setState(() {}),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmacion() {
    final resultados = _resultados!;
    final huboError = resultados.any((r) => r.error != null);
    final huboExito = resultados.any((r) => r.error == null);
    final huboPendiente = resultados.any((r) => r.pendiente);
    final totalRegistrado =
        resultados.where((r) => r.error == null).fold<int>(0, (a, r) => a + r.monto);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Center(
          child: Icon(
            huboError ? Icons.error_outline : Icons.check_circle,
            color: huboError ? AppColors.badgeAmber : AppColors.badgeGreen,
            size: 56,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          huboError ? 'Registro parcial' : 'Cobro registrado',
          textAlign: TextAlign.center,
          style: AppTextStyles.title.copyWith(fontSize: 22),
        ),
        const SizedBox(height: 4),
        Text(widget.nombreCliente, textAlign: TextAlign.center, style: AppTextStyles.link),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.inputBorder),
          ),
          child: Column(
            children: [
              for (final r in resultados) _ResultadoFila(resultado: r),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.steelBlue.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text('Total registrado', style: AppTextStyles.label.copyWith(fontSize: 15)),
              ),
              Text(
                formatMoneda(totalRegistrado),
                style: AppTextStyles.title.copyWith(fontSize: 20, color: AppColors.orange),
              ),
            ],
          ),
        ),
        if (huboPendiente) ...[
          const SizedBox(height: 14),
          CobroPendienteIndicator(cantidadEnCola: CobroOfflineService.instance.cantidadPendiente),
        ],
        const SizedBox(height: 20),
        PrimaryButton(
          text: 'Continuar',
          onPressed: () => Navigator.of(context).pop(huboExito ? true : null),
        ),
      ],
    );
  }
}

class _ResumenAsignacion extends StatelessWidget {
  final int total;
  final int asignado;
  final int restante;

  const _ResumenAsignacion({
    required this.total,
    required this.asignado,
    required this.restante,
  });

  @override
  Widget build(BuildContext context) {
    final Color colorRestante = restante == 0
        ? AppColors.badgeGreen
        : (restante > 0 ? AppColors.badgeAmber : AppColors.error);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        children: [
          _fila('Total de la venta', formatMoneda(total), AppColors.steelBlue),
          const SizedBox(height: 8),
          _fila('Asignado', formatMoneda(asignado), AppColors.graphiteGray),
          const Divider(height: 20, color: AppColors.inputBorder),
          _fila(
            restante >= 0 ? 'Restante' : 'Excedido',
            formatMoneda(restante),
            colorRestante,
            fuerte: true,
          ),
        ],
      ),
    );
  }

  Widget _fila(String etiqueta, String valor, Color color, {bool fuerte = false}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            etiqueta,
            style: AppTextStyles.link.copyWith(
              fontSize: fuerte ? 14.5 : 13.5,
              color: AppColors.graphiteGray,
            ),
          ),
        ),
        Text(
          valor,
          style: TextStyle(
            fontSize: fuerte ? 16 : 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _MontoLineaField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onChanged;

  const _MontoLineaField({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: (_) => onChanged(),
      cursorColor: AppColors.orange,
      style: AppTextStyles.title.copyWith(fontSize: 20),
      decoration: InputDecoration(
        prefixText: '\$ ',
        prefixStyle: AppTextStyles.title.copyWith(fontSize: 20, color: AppColors.graphiteGray),
        filled: true,
        fillColor: AppColors.white,
        hintText: '0',
        hintStyle: AppTextStyles.hint.copyWith(fontSize: 20),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.orange),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _ResultadoFila extends StatelessWidget {
  final _ResultadoLinea resultado;

  const _ResultadoFila({required this.resultado});

  @override
  Widget build(BuildContext context) {
    final Color colorEstado = resultado.error != null
        ? AppColors.error
        : (resultado.pendiente ? AppColors.badgeAmber : AppColors.badgeGreen);
    final String estado = resultado.error != null
        ? 'Error'
        : (resultado.pendiente ? 'Pendiente' : 'Sincronizado');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(resultado.metodo.icono, size: 18, color: AppColors.steelBlue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  resultado.metodo.etiqueta,
                  style: AppTextStyles.label.copyWith(fontSize: 14.5),
                ),
              ),
              Text(
                formatMoneda(resultado.monto),
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.steelBlue),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colorEstado.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colorEstado.withOpacity(0.4)),
                ),
                child: Text(
                  estado,
                  style: TextStyle(
                      fontSize: 10.5, fontWeight: FontWeight.w800, color: colorEstado),
                ),
              ),
            ],
          ),
          if (resultado.error != null) ...[
            const SizedBox(height: 4),
            Text(
              resultado.error!,
              style: AppTextStyles.link.copyWith(fontSize: 11.5, color: AppColors.error),
            ),
          ],
        ],
      ),
    );
  }
}

class _ClienteHeader extends StatelessWidget {
  final String nombre;

  const _ClienteHeader({required this.nombre});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.steelBlue.withOpacity(0.1),
            child: const Icon(Icons.person_outline, color: AppColors.steelBlue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cliente', style: AppTextStyles.link.copyWith(fontSize: 12)),
                const SizedBox(height: 2),
                Text(
                  nombre,
                  style: AppTextStyles.label.copyWith(fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SinConexionAviso extends StatelessWidget {
  const _SinConexionAviso();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.badgeAmber.withOpacity(0.14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.badgeAmber.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off, size: 18, color: AppColors.badgeAmber),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Sin conexión: los pagos se guardan localmente y se envían al recuperar señal.',
              style: AppTextStyles.link.copyWith(fontSize: 12.5, color: AppColors.graphiteGray),
            ),
          ),
        ],
      ),
    );
  }
}

class _VentaPendienteAviso extends StatelessWidget {
  const _VentaPendienteAviso();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.badgeAmber.withOpacity(0.14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.badgeAmber.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.sync_problem_outlined, size: 18, color: AppColors.badgeAmber),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'La venta todavía no se sincronizó. Los pagos se guardan localmente '
              'y se envían cuando la venta se registre en el servidor.',
              style: AppTextStyles.link.copyWith(fontSize: 12.5, color: AppColors.graphiteGray),
            ),
          ),
        ],
      ),
    );
  }
}
