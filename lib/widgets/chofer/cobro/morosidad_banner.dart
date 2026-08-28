import 'package:flutter/material.dart';
import '../../../models/credito_cliente.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/formato.dart';

class MorosidadBanner extends StatelessWidget {
  final CreditoCliente credito;
  final bool compacto;

  const MorosidadBanner({
    super.key,
    required this.credito,
    this.compacto = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!credito.tieneAlerta) return const SizedBox.shrink();

    final saldo = credito.saldoUsado;
    final detalle = credito.limiteExcedido ? 'Límite excedido' : 'Cliente moroso';
    final saldoTexto = saldo != null ? 'Saldo: ${formatMoneda(saldo.round())}' : 'Cuenta con deuda';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: compacto ? 10 : 12),
      decoration: BoxDecoration(
        color: AppColors.error,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.white, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '¡ALERTA MOROSIDAD!',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$saldoTexto  ·  $detalle',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white.withOpacity(0.95),
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
