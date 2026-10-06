import 'package:flutter/material.dart';

import '../../../models/administrador_cuenta.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

class ConfirmarBajaAdministradorDialog extends StatelessWidget {
  final AdministradorCuenta cuenta;

  const ConfirmarBajaAdministradorDialog({super.key, required this.cuenta});

  static Future<bool> mostrar(BuildContext context, AdministradorCuenta cuenta) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => ConfirmarBajaAdministradorDialog(cuenta: cuenta),
    );
    return ok ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.person_remove_outlined, size: 20, color: AppColors.error),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text('Dar de baja', style: AppTextStyles.title.copyWith(fontSize: 18))),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Text.rich(
          TextSpan(
            style: AppTextStyles.input.copyWith(color: AppColors.graphiteGray, height: 1.4),
            children: [
              const TextSpan(text: '¿Querés dar de baja a '),
              TextSpan(
                text: cuenta.nombreMostrado,
                style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.steelBlue),
              ),
              TextSpan(text: ' (${cuenta.email})? Ya no va a poder ingresar al panel y se cierran sus sesiones abiertas.'),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text('Cancelar', style: AppTextStyles.button.copyWith(color: AppColors.graphiteGray)),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text('Dar de baja', style: AppTextStyles.button.copyWith(color: AppColors.error)),
        ),
      ],
    );
  }
}
