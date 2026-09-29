import 'package:flutter/material.dart';
import '../../../core/responsive.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../utils/formato.dart';

class VentasCabecera extends StatelessWidget {
  final int cantidad;
  final int montoTotal;

  const VentasCabecera({
    super.key,
    required this.cantidad,
    required this.montoTotal,
  });

  @override
  Widget build(BuildContext context) {
    final movil = Responsive.isMobileContext(context);
    final titulos = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Consola de Ventas',
          style: movil
              ? AppTextStyles.desktopTitle.copyWith(fontSize: 22)
              : AppTextStyles.desktopTitle,
        ),
        const SizedBox(height: 4),
        Text(
          'Monitoreo diario de ventas con el desglose de cilindros entregados y retribuidos.',
          style: AppTextStyles.desktopSubtitle,
        ),
      ],
    );
    final resumen = VentasResumenChip(
      etiqueta: 'Total del día',
      valor: formatMoneda(montoTotal),
      expandido: movil,
    );

    if (movil) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          titulos,
          const SizedBox(height: 14),
          resumen,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: titulos),
        const SizedBox(width: 16),
        resumen,
      ],
    );
  }
}

class VentasResumenChip extends StatelessWidget {
  final String etiqueta;
  final String valor;
  final bool expandido;

  const VentasResumenChip({
    super.key,
    required this.etiqueta,
    required this.valor,
    this.expandido = false,
  });

  static const TextStyle _estiloEtiqueta = TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.w600,
    color: AppColors.graphiteGray,
  );

  static const TextStyle _estiloValor = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w800,
    color: AppColors.orange,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: expandido
          ? Row(
              children: [
                Expanded(child: Text(etiqueta, style: _estiloEtiqueta.copyWith(fontSize: 12.5))),
                const SizedBox(width: 12),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(valor, style: _estiloValor),
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(etiqueta, style: _estiloEtiqueta),
                const SizedBox(height: 2),
                Text(valor, style: _estiloValor),
              ],
            ),
    );
  }
}
