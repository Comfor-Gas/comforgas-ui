import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/common/estado_conexion_badge.dart';
import '../../widgets/primary_button.dart';

class InicioSinConexionCard extends StatelessWidget {
  final String nombreCliente;
  final String direccionCliente;
  final bool reintentando;
  final bool continuando;
  final VoidCallback onReintentarConexion;
  final VoidCallback onContinuarOffline;

  const InicioSinConexionCard({
    super.key,
    required this.nombreCliente,
    required this.direccionCliente,
    required this.onReintentarConexion,
    required this.onContinuarOffline,
    this.reintentando = false,
    this.continuando = false,
  });

  @override
  Widget build(BuildContext context) {
    final ocupado = reintentando || continuando;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: EstadoConexionBadge()),
          const SizedBox(height: 20),
          const Center(
            child: Icon(Icons.cloud_off_outlined, size: 44, color: AppColors.badgeGray),
          ),
          const SizedBox(height: 16),
          Text(
            nombreCliente,
            style: AppTextStyles.title.copyWith(fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            direccionCliente,
            style: AppTextStyles.link,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.badgeAmber.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.badgeAmber.withOpacity(0.4)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, size: 18, color: AppColors.badgeAmber),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Estás sin conexión. Podés iniciar la visita igual:'
                    'la ubicación y todo se sincroniza al recuperar la señal.',
                    style: AppTextStyles.link
                        .copyWith(fontSize: 12.5, color: AppColors.graphiteGray),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          PrimaryButton(
            text: 'Continuar offline',
            isLoading: continuando,
            onPressed: ocupado ? null : onContinuarOffline,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: ocupado ? null : onReintentarConexion,
              icon: reintentando
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: AppColors.steelBlue,
                      ),
                    )
                  : const Icon(Icons.refresh, size: 20),
              label: const Text('Reintentar conexión'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.steelBlue,
                side: const BorderSide(color: AppColors.steelBlue),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: TextButton(
              onPressed: ocupado ? null : () => Navigator.of(context).pop(),
              child: const Text(
                'Cancelar',
                style: TextStyle(
                  color: AppColors.graphiteGray,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
