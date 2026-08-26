import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class CheckinForzadoButton extends StatelessWidget {
  final Future<void> Function() onConfirmado;

  const CheckinForzadoButton({super.key, required this.onConfirmado});

  Future<void> _confirmar(BuildContext context) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Check-in forzado'),
        content: const Text(
          'Estás sin conexión y no se pudo validar tu ubicación. '
          'Si forzás el check-in, la visita quedará marcada sin geolocalización '
          'válida y se confirmará con el servidor cuando vuelva la señal. '
          '¿Querés continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Volver'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.orange),
            child: const Text('Forzar check-in'),
          ),
        ],
      ),
    );
    if (confirmado == true) {
      await onConfirmado();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _confirmar(context),
            icon: const Icon(Icons.bolt, size: 20),
            label: const Text('Check-in forzado'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.orange,
              side: const BorderSide(color: AppColors.orange, width: 1.4),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.wifi_off, size: 14, color: AppColors.graphiteGray),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Disponible sin conexión para no frenar la visita. Se sincroniza al recuperar señal.',
                style: AppTextStyles.footer,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
