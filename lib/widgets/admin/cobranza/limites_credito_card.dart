import 'package:flutter/material.dart';

import '../../../core/responsive.dart';
import '../../../models/cuenta_corriente_resumen.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../utils/formato.dart';

class LimitesCreditoCard extends StatelessWidget {
  final List<CuentaCorrienteResumen> clientes;
  final VoidCallback? onAsignar;
  final ValueChanged<CuentaCorrienteResumen>? onEditar;
  final bool cargando;
  final bool mostrarIndicadores;

  const LimitesCreditoCard({
    super.key,
    required this.clientes,
    this.onAsignar,
    this.onEditar,
    this.cargando = false,
    this.mostrarIndicadores = true,
  });

  List<CuentaCorrienteResumen> get _sinDisponible =>
      clientes.where((c) => c.limiteCredito - c.saldoUsado <= 0).toList();

  @override
  Widget build(BuildContext context) {
    final totalLimites = clientes.fold<int>(0, (a, c) => a + c.limiteCredito);
    final agotados = _sinDisponible;

    return Container(
      padding: EdgeInsets.all(Responsive.isMobileContext(context) ? 14 : 18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final angosto = constraints.maxWidth < 620;
              final encabezado = Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.orange.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.tune_rounded, color: AppColors.orange, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Límites de crédito', style: AppTextStyles.label.copyWith(fontSize: 15.5)),
                        const SizedBox(height: 3),
                        Text(
                          'Definí cuánto puede cargar cada cliente en Cuenta Corriente. '
                          'El chofer no puede cobrar por encima del disponible.',
                          style: AppTextStyles.link.copyWith(fontSize: 12.5),
                        ),
                      ],
                    ),
                  ),
                ],
              );
              final boton = ElevatedButton.icon(
                onPressed: cargando ? null : onAsignar,
                icon: const Icon(Icons.add_card_outlined, size: 18),
                label: const Text('Asignar límite'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  foregroundColor: AppColors.white,
                  disabledBackgroundColor: AppColors.orange.withOpacity(0.4),
                  disabledForegroundColor: AppColors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
              if (angosto) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [encabezado, const SizedBox(height: 12), boton],
                );
              }
              return Row(
                children: [
                  Expanded(child: encabezado),
                  const SizedBox(width: 16),
                  boton,
                ],
              );
            },
          ),
          if (mostrarIndicadores) ...[
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _Indicador(
                icono: Icons.people_outline,
                texto: '${clientes.length} con cuenta',
                color: AppColors.steelBlue,
              ),
              _Indicador(
                icono: Icons.account_balance_outlined,
                texto: 'Crédito otorgado ${formatMoneda(totalLimites)}',
                color: AppColors.steelBlue,
              ),
              _Indicador(
                icono: Icons.block_outlined,
                texto: '${agotados.length} sin disponible',
                color: agotados.isEmpty ? AppColors.badgeGreen : AppColors.error,
              ),
            ],
          ),
          ],
          if (mostrarIndicadores && agotados.isNotEmpty && onEditar != null) ...[
            const SizedBox(height: 14),
            Text(
              'Sin crédito disponible',
              style: AppTextStyles.footer.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
                color: AppColors.graphiteGray,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in agotados.take(8))
                  ActionChip(
                    avatar: const Icon(Icons.edit_outlined, size: 15, color: AppColors.orange),
                    label: Text(c.nombreMostrado, overflow: TextOverflow.ellipsis),
                    onPressed: () => onEditar!(c),
                    backgroundColor: AppColors.background,
                    side: BorderSide(color: AppColors.orange.withOpacity(0.35)),
                    labelStyle: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.steelBlue,
                    ),
                  ),
                if (agotados.length > 8)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '+${agotados.length - 8} más',
                      style: AppTextStyles.footer.copyWith(color: AppColors.graphiteGray),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Indicador extends StatelessWidget {
  final IconData icono;
  final String texto;
  final Color color;

  const _Indicador({required this.icono, required this.texto, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 15, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(texto, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: color)),
          ),
        ],
      ),
    );
  }
}
