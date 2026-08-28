import 'dart:async' show StreamSubscription, unawaited;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../local/cobro_offline_service.dart';
import '../../../local/cobro_pendiente.dart';
import '../../../models/cobro_draft.dart';
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
import '../../../widgets/chofer/cobro/comprobante_cobro.dart';
import '../../../widgets/chofer/cobro/metodo_pago_selector.dart';
import '../../../widgets/chofer/cobro/morosidad_banner.dart';
import '../../../widgets/primary_button.dart';

const _uuid = Uuid();

class RegistroCobroScreen extends StatefulWidget {
  /// PK de la venta cuando ya está confirmada por el servidor.
  final int? idVenta;

  /// UUID offline de la venta cuando todavía no sincronizó. Debe informarse
  /// exactamente uno entre [idVenta] y [uuidVentaOffline].
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

  /// La venta asociada todavía no fue confirmada por el servidor: el cobro se
  /// guarda local y se liga por UUID al sincronizar.
  bool get ventaPendienteDeSync => idVenta == null;

  @override
  State<RegistroCobroScreen> createState() => _RegistroCobroScreenState();
}

class _RegistroCobroScreenState extends State<RegistroCobroScreen> {
  late final CobroRepository _repo;
  late final TextEditingController _montoCtrl;
  StreamSubscription<bool>? _conexionSub;

  MetodoPago _metodo = MetodoPago.efectivo;
  bool _online = true;
  bool _guardando = false;

  CobroResultado? _resultado;
  String _uuidGuardado = '';

  @override
  void initState() {
    super.initState();
    _repo = CobroRepository(context.read<AuthProvider>().apiClient);
    _montoCtrl = TextEditingController(
      text: widget.montoSugerido > 0 ? '${widget.montoSugerido}' : '',
    );
    ConnectivityService.instance.tieneConexion().then((v) {
      if (mounted) setState(() => _online = v);
    });
    _conexionSub = ConnectivityService.instance.observarConexion().listen((v) {
      if (mounted) setState(() => _online = v);
    });
  }

  @override
  void dispose() {
    _montoCtrl.dispose();
    _conexionSub?.cancel();
    super.dispose();
  }

  Future<void> _guardar() async {
    final monto = int.tryParse(_montoCtrl.text.trim()) ?? 0;
    if (monto <= 0) {
      _mostrarError('Ingresá un monto válido.');
      return;
    }
    setState(() => _guardando = true);

    final uuid = _uuid.v4();
    final ahora = DateTime.now();
    final cobro = CobroDraft(
      idVenta: widget.idVenta,
      uuidVentaOffline: widget.uuidVentaOffline,
      metodo: _metodo,
      monto: monto,
      timestampCobro: ahora,
    );

    bool pendienteSync;

    if (widget.ventaPendienteDeSync) {
      // La venta todavía no tiene id del servidor: el endpoint individual solo
      // acepta idVenta, así que el cobro se encola y se liga a la venta por su
      // uuid_offline en la sincronización por lote.
      await CobroOfflineService.instance.encolar(
        CobroPendiente(
          uuidOffline: uuid,
          uuidVentaOffline: widget.uuidVentaOffline,
          metodoPago: _metodo.codigoBackend,
          monto: monto,
          timestampCobro: ahora,
          creadoEn: ahora,
        ),
      );
      unawaited(CobroSyncManager.instance.sincronizar());
      pendienteSync = true;
    } else {
      try {
        await _repo.registrar(
          idVenta: widget.idVenta!,
          metodoPago: _metodo.codigoBackend,
          monto: monto,
          timestampCobro: ahora,
          uuidOffline: uuid,
        );
        pendienteSync = false;
      } on NetworkException {
        await CobroOfflineService.instance.encolar(
          CobroPendiente(
            uuidOffline: uuid,
            idVenta: widget.idVenta,
            metodoPago: _metodo.codigoBackend,
            monto: monto,
            timestampCobro: ahora,
            creadoEn: ahora,
          ),
        );
        unawaited(CobroSyncManager.instance.sincronizar());
        pendienteSync = true;
      } on CobroRepositoryException catch (e) {
        if (!mounted) return;
        setState(() => _guardando = false);
        _mostrarError(e.message);
        return;
      } catch (_) {
        if (!mounted) return;
        setState(() => _guardando = false);
        _mostrarError('No se pudo guardar el cobro. Intentá de nuevo.');
        return;
      }
    }

    if (!mounted) return;
    setState(() {
      _uuidGuardado = uuid;
      _resultado = CobroResultado(cobro: cobro, pendienteSync: pendienteSync);
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.steelBlue,
        foregroundColor: AppColors.white,
        elevation: 0,
        title: const Text('Cobro de Venta'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: _resultado == null ? _buildFormulario() : _buildConfirmacion(),
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
        Text('Método de Pago', style: AppTextStyles.label.copyWith(fontSize: 14)),
        const SizedBox(height: 10),
        MetodoPagoSelector(
          seleccionado: _metodo,
          onChanged: (m) => setState(() => _metodo = m),
        ),
        const SizedBox(height: 20),
        Text('Monto Cobrado', style: AppTextStyles.label.copyWith(fontSize: 14)),
        const SizedBox(height: 8),
        _MontoField(controller: _montoCtrl),
        const SizedBox(height: 24),
        PrimaryButton(
          text: (_online && !widget.ventaPendienteDeSync)
              ? 'Guardar Cobro'
              : 'Registro Local Seguro',
          isLoading: _guardando,
          onPressed: _guardando ? null : _guardar,
        ),
      ],
    );
  }

  Widget _buildConfirmacion() {
    final resultado = _resultado!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        const Center(
          child: Icon(Icons.check_circle, color: AppColors.badgeGreen, size: 56),
        ),
        const SizedBox(height: 12),
        Text(
          'Cobro Guardado',
          textAlign: TextAlign.center,
          style: AppTextStyles.title.copyWith(fontSize: 22),
        ),
        const SizedBox(height: 4),
        Text(
          widget.nombreCliente,
          textAlign: TextAlign.center,
          style: AppTextStyles.link,
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.inputBorder),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${resultado.cobro.metodo.etiqueta}',
                  style: AppTextStyles.label.copyWith(fontSize: 15),
                ),
              ),
              Text(
                formatMoneda(resultado.cobro.monto),
                style: AppTextStyles.title.copyWith(fontSize: 20, color: AppColors.orange),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (resultado.pendienteSync)
          CobroPendienteIndicator(cantidadEnCola: CobroOfflineService.instance.cantidadPendiente)
        else
          const _SincronizadoAviso(),
        const SizedBox(height: 20),
        PrimaryButton(
          text: 'Generar Comprobante',
          onPressed: () => ComprobanteCobro.mostrar(
            context,
            cobro: resultado.cobro,
            nombreCliente: widget.nombreCliente,
            uuidOffline: _uuidGuardado,
            pendienteSync: resultado.pendienteSync,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(resultado),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.steelBlue,
              side: const BorderSide(color: AppColors.steelBlue),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Continuar'),
          ),
        ),
      ],
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

class _MontoField extends StatelessWidget {
  final TextEditingController controller;

  const _MontoField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: AppTextStyles.title.copyWith(fontSize: 24),
      decoration: InputDecoration(
        prefixText: '\$ ',
        prefixStyle: AppTextStyles.title.copyWith(fontSize: 24, color: AppColors.graphiteGray),
        filled: true,
        fillColor: AppColors.white,
        hintText: '0',
        hintStyle: AppTextStyles.hint.copyWith(fontSize: 24),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
              'Sin conexión: el cobro se guardará localmente y se enviará al recuperar señal.',
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
              'La venta todavía no se sincronizó. El cobro se guarda localmente '
              'y se envía cuando la venta se registre en el servidor.',
              style: AppTextStyles.link.copyWith(fontSize: 12.5, color: AppColors.graphiteGray),
            ),
          ),
        ],
      ),
    );
  }
}

class _SincronizadoAviso extends StatelessWidget {
  const _SincronizadoAviso();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.badgeGreen.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.badgeGreen.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_done_outlined, size: 18, color: AppColors.badgeGreen),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Cobro sincronizado con el servidor.',
              style: AppTextStyles.link.copyWith(fontSize: 12.5, color: AppColors.graphiteGray),
            ),
          ),
        ],
      ),
    );
  }
}
