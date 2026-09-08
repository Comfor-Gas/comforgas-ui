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
  List<DetalleControlDraft> detalles,
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
  late final Map<String, int> _contratadaPorTipo;
  late final Map<String, int> _fisicaPorTipo;
  late final List<String> _tipos;
  late final TextEditingController _obsController;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _tipos = widget.contrato.detalles.map((d) => d.tipoEnvase).toList();
    _contratadaPorTipo = {
      for (final d in widget.contrato.detalles) d.tipoEnvase: d.cantidadContratada,
    };
    final previo = <String, int>{
      for (final d in widget.controlPrevio?.detalles ?? const [])
        if (d.cantidadFisicaActual != null) d.tipoEnvase: d.cantidadFisicaActual!,
    };
    _fisicaPorTipo = {
      for (final d in widget.contrato.detalles)
        d.tipoEnvase: previo[d.tipoEnvase] ?? d.cantidadContratada,
    };
    _obsController = TextEditingController(
      text: widget.controlPrevio?.observaciones ?? '',
    );
  }

  @override
  void dispose() {
    _obsController.dispose();
    super.dispose();
  }

  int get _faltanteTotal {
    var total = 0;
    for (final tipo in _tipos) {
      final dif = (_contratadaPorTipo[tipo] ?? 0) - (_fisicaPorTipo[tipo] ?? 0);
      if (dif > 0) total += dif;
    }
    return total;
  }

  int get _sobranteTotal {
    var total = 0;
    for (final tipo in _tipos) {
      final dif = (_fisicaPorTipo[tipo] ?? 0) - (_contratadaPorTipo[tipo] ?? 0);
      if (dif > 0) total += dif;
    }
    return total;
  }

  Future<void> _guardar() async {
    if (_guardando) return;
    setState(() => _guardando = true);
    final obs = _obsController.text.trim();
    final detalles = _tipos
        .map((tipo) => DetalleControlDraft(
              tipoEnvase: tipo,
              cantidadContratada: _contratadaPorTipo[tipo] ?? 0,
              cantidadFisicaActual: _fisicaPorTipo[tipo] ?? 0,
            ))
        .toList();
    try {
      await widget.onGuardar(detalles, obs.isEmpty ? null : obs);
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
                      titulo: 'Conteo físico por tipo de envase',
                      child: Column(
                        children: [
                          for (final tipo in _tipos) ...[
                            _FilaTipo(
                              tipoEnvase: tipo,
                              cantidadContratada: _contratadaPorTipo[tipo] ?? 0,
                              cantidadFisica: _fisicaPorTipo[tipo] ?? 0,
                              enabled: !_guardando,
                              onChanged: (v) => setState(() => _fisicaPorTipo[tipo] = v),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ],
                      ),
                    ),
                    DiscrepanciaIndicator(
                      faltanteTotal: _faltanteTotal,
                      sobranteTotal: _sobranteTotal,
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

class _FilaTipo extends StatelessWidget {
  final String tipoEnvase;
  final int cantidadContratada;
  final int cantidadFisica;
  final bool enabled;
  final ValueChanged<int> onChanged;

  const _FilaTipo({
    required this.tipoEnvase,
    required this.cantidadContratada,
    required this.cantidadFisica,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final faltante = cantidadContratada - cantidadFisica;
    final Color colorDif;
    if (faltante > 0) {
      colorDif = AppColors.badgeRed;
    } else if (faltante < 0) {
      colorDif = AppColors.badgeAmber;
    } else {
      colorDif = AppColors.badgeGreen;
    }

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
                  tipoEnvase,
                  style: AppTextStyles.label.copyWith(fontSize: 14),
                ),
              ),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: colorDif, shape: BoxShape.circle),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Contratadas en sistema: $cantidadContratada',
            style: AppTextStyles.footer.copyWith(color: AppColors.graphiteGray),
          ),
          const SizedBox(height: 12),
          ContadorEnvases(
            value: cantidadFisica,
            enabled: enabled,
            onChanged: onChanged,
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
