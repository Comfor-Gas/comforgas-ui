import 'package:flutter/material.dart';
import '../../../models/control_comodato.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

class ControlComodatoCard extends StatelessWidget {
  final ContratoComodato? contrato;
  final List<int> comodatosActivosFallback;
  final ControlComodatoDraft? controlRegistrado;
  final bool pendienteSync;
  final bool cargando;
  final VoidCallback? onAuditar;

  const ControlComodatoCard({
    super.key,
    required this.contrato,
    required this.comodatosActivosFallback,
    required this.controlRegistrado,
    required this.pendienteSync,
    required this.cargando,
    required this.onAuditar,
  });

  bool get _auditado => controlRegistrado != null;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _auditado
              ? AppColors.badgeGreen.withOpacity(0.5)
              : AppColors.inputBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.assignment_outlined, size: 20, color: AppColors.orange),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Control de Comodato',
                  style: AppTextStyles.label.copyWith(fontSize: 15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_auditado) _buildResumenAuditado() else _buildResumenContrato(),
          if (!_auditado) ...[
            const SizedBox(height: 14),
            _buildBoton(),
          ],
        ],
      ),
    );
  }

  Widget _buildResumenContrato() {
    if (cargando) {
      return Row(
        children: const [
          SizedBox(
            height: 16,
            width: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.orange),
          ),
          SizedBox(width: 10),
          Text(
            'Cargando contrato de comodato…',
            style: TextStyle(fontSize: 12.5, color: AppColors.graphiteGray),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RESUMEN CONTRATO DE COMODATO',
            style: AppTextStyles.footer.copyWith(letterSpacing: 0.4),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.propane_tank_rounded, size: 16, color: AppColors.orange),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _tituloContrato(),
                  style: AppTextStyles.input.copyWith(fontSize: 13.5),
                ),
              ),
            ],
          ),
          if (_detalleContrato().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              _detalleContrato(),
              style: AppTextStyles.footer.copyWith(color: AppColors.graphiteGray),
            ),
          ],
        ],
      ),
    );
  }

  String _tituloContrato() {
    final c = contrato;
    if (c != null) {
      final unidad = c.cantidadContratadaTotal == 1 ? 'garrafa' : 'garrafas';
      return 'Comodato activo: ${c.cantidadContratadaTotal} $unidad';
    }
    if (comodatosActivosFallback.isNotEmpty) {
      final tamanos = comodatosActivosFallback.map((k) => '${k}kg').join(' · ');
      return 'Comodato activo: $tamanos';
    }
    return 'Sin contrato de comodato registrado para este cliente.';
  }

  String _detalleContrato() {
    final c = contrato;
    if (c == null || c.detalles.isEmpty) return '';
    return c.detalles
        .map((d) => '${d.tipoEnvase}: ${d.cantidadContratada}')
        .join('  ·  ');
  }

  Widget _buildResumenAuditado() {
    final control = controlRegistrado!;
    final contratada = control.contratadaTotal;
    final fisica = control.fisicaTotal;
    final faltante = control.faltanteTotal;

    final Color colorEstado = faltante > 0 ? AppColors.badgeRed : AppColors.badgeGreen;
    final String textoDif = faltante > 0 ? ' (-$faltante dif.)' : ' (sin dif.)';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, size: 18, color: colorEstado),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Auditado: $fisica/$contratada físicos$textoDif',
                  style: AppTextStyles.label.copyWith(fontSize: 13.5, color: colorEstado),
                ),
              ),
            ],
          ),
          if (pendienteSync) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.orange.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.orange.withOpacity(0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.sync, size: 14, color: AppColors.orange),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Guardado local (Pendiente sincronización)',
                      style: AppTextStyles.footer.copyWith(
                        color: AppColors.orange,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 6),
            Text(
              'Sincronizado con el servidor.',
              style: AppTextStyles.footer.copyWith(color: AppColors.graphiteGray),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBoton() {
    return Material(
      color: AppColors.orange,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onAuditar,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.fact_check_outlined, size: 22, color: AppColors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CONTROL DE COMODATO [AUDITAR]',
                      style: AppTextStyles.button.copyWith(fontSize: 13, letterSpacing: 0.4),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Auditoría física de cilindros prestados',
                      style: AppTextStyles.footer.copyWith(
                        color: AppColors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              _buildPill(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        'PENDIENTE',
        style: AppTextStyles.footer.copyWith(
          color: AppColors.orange,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
