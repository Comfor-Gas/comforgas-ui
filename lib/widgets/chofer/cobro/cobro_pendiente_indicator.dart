import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

class CobroPendienteIndicator extends StatelessWidget {
  final int cantidadEnCola;

  const CobroPendienteIndicator({super.key, this.cantidadEnCola = 0});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.orange,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.sync, color: AppColors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'COBRO GUARDADO LOCALMENTE',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Pendiente de envío. Se sincroniza solo al recuperar señal.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.white.withOpacity(0.95),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (cantidadEnCola > 0) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Cola: $cantidadEnCola pendiente${cantidadEnCola == 1 ? '' : 's'}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
