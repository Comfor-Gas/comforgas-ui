import 'package:flutter/material.dart';
import '../../../models/control_comodato.dart';
import '../../../repositories/comodato_repository.dart';
import '../../../repositories/network_exception.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../widgets/chofer/comodato/contador_envases.dart';
import '../../../widgets/chofer/comodato/discrepancia_indicator.dart';
import '../../../widgets/primary_button.dart';

typedef GuardarControlComodato = Future<void> Function(
  int cantidadFisicaActual,
  String? observaciones,
);

class AuditoriaComodatoScreen extends StatefulWidget {
  final String nombreCliente;
  final ContratoComodato contrato;
  final ControlComodatoDraft? controlPrevio;
  final GuardarControlComodato onGuardar;

  const AuditoriaComodatoScreen({
    super.key,
    required this.nombreCliente,
    required this.contrato,
    required this.controlPrevio,
    required this.onGuardar,
  });

  @override
  State<AuditoriaComodatoScreen> createState() => _AuditoriaComodatoScreenState();
}

class _AuditoriaComodatoScreenState extends State<AuditoriaComodatoScreen> {
  late int _contratada;
  late int _fisica;
  late final TextEditingController _obsController;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _contratada = widget.contrato.cantidadContratada;
    _fisica = widget.controlPrevio?.cantidadFisicaActual ?? _contratada;
    _obsController = TextEditingController(
      text: widget.controlPrevio?.observaciones ?? '',
    );
  }

  @override
  void dispose() {
    _obsController.dispose();
    super.dispose();
  }

  int get _faltante {
    final dif = _contratada - _fisica;
    return dif > 0 ? dif : 0;
  }

  int get _sobrante {
    final dif = _fisica - _contratada;
    return dif > 0 ? dif : 0;
  }

  Future<void> _guardar() async {
    if (_guardando) return;
    setState(() => _guardando = true);
    final obs = _obsController.text.trim();
    try {
      await widget.onGuardar(_fisica, obs.isEmpty ? null : obs);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ComodatoRepositoryException catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      _mostrarError(e.message);
    } on NetworkException catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      _mostrarError(e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _guardando = false);
      _mostrarError('No se pudo guardar el control de comodato. Intentá de nuevo.');
    }
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
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TopBar(nombreCliente: widget.nombreCliente),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Seccion(
                      titulo: 'Conteo físico de garrafas en comodato',
                      child: _buildContador(),
                    ),
                    const SizedBox(height: 12),
                    DiscrepanciaIndicator(
                      faltanteTotal: _faltante,
                      sobranteTotal: _sobrante,
                    ),
                    const SizedBox(height: 20),
                    _Seccion(
                      titulo: 'Observaciones de campo',
                      child: _buildObservaciones(),
                    ),
                    const SizedBox(height: 16),
                    _buildNotaOffline(),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: PrimaryButton(
                text: 'Guardar control de comodato',
                isLoading: _guardando,
                onPressed: _guardando ? null : _guardar,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContador() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.propane_tank_rounded, size: 18, color: AppColors.orange),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Garrafas de 10 kg',
                  style: AppTextStyles.label.copyWith(fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Contratadas en sistema: $_contratada',
            style: AppTextStyles.footer.copyWith(color: AppColors.graphiteGray),
          ),
          const SizedBox(height: 12),
          ContadorEnvases(
            value: _fisica,
            enabled: !_guardando,
            onChanged: (v) => setState(() => _fisica = v),
          ),
        ],
      ),
    );
  }

  Widget _buildObservaciones() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.inputBorder, width: 1.2),
      ),
      child: TextField(
        controller: _obsController,
        enabled: !_guardando,
        maxLines: 3,
        style: AppTextStyles.input,
        cursorColor: AppColors.steelBlue,
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.all(14),
          hintText: 'Ej: envase dañado, faltante reconocido por el cliente…',
          hintStyle: AppTextStyles.hint,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildNotaOffline() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.steelBlue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.save_outlined, size: 18, color: AppColors.steelBlue),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Si no hay señal, el control se guarda en el dispositivo y se sincroniza automáticamente al recuperar conexión.',
              style: AppTextStyles.footer.copyWith(color: AppColors.graphiteGray),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final String nombreCliente;

  const _TopBar({required this.nombreCliente});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 16, 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.steelBlue),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Auditoría de Comodato',
                  style: AppTextStyles.title.copyWith(fontSize: 18),
                ),
                Text(
                  nombreCliente,
                  style: AppTextStyles.link.copyWith(fontSize: 13),
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

class _Seccion extends StatelessWidget {
  final String titulo;
  final Widget child;

  const _Seccion({required this.titulo, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo.toUpperCase(),
          style: AppTextStyles.footer.copyWith(
            letterSpacing: 0.5,
            fontWeight: FontWeight.w700,
            color: AppColors.graphiteGray,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
