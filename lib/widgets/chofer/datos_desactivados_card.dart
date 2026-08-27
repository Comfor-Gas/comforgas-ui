import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/common/estado_conexion_badge.dart';
import '../../widgets/primary_button.dart';

class DatosDesactivadosCard extends StatelessWidget {
  final String nombreCliente;
  final String direccionCliente;
  final bool reintentando;
  final VoidCallback onReintentar;

  const DatosDesactivadosCard({
    super.key,
    required this.nombreCliente,
    required this.direccionCliente,
    required this.onReintentar,
    this.reintentando = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: EstadoConexionBadge()),
          const SizedBox(height: 20),
          const Center(
            child: Icon(Icons.mobiledata_off, size: 48, color: AppColors.error),
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
              color: AppColors.error.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.error.withOpacity(0.35)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.wifi_off, size: 18, color: AppColors.error),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Activá los datos móviles o el WiFi para iniciar la visita. '
                    'Con el internet apagado no se puede validar tu ubicación.',
                    style: AppTextStyles.link
                        .copyWith(fontSize: 12.5, color: AppColors.graphiteGray),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          PrimaryButton(
            text: 'Reintentar',
            isLoading: reintentando,
            onPressed: reintentando ? null : onReintentar,
          ),
          const SizedBox(height: 10),
          Center(
            child: TextButton(
              onPressed: reintentando ? null : () => Navigator.of(context).pop(),
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
