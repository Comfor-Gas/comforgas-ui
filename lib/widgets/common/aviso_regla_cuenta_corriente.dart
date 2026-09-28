import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class AvisoReglaCuentaCorriente extends StatelessWidget {
  final String texto;
  final bool destacado;

  const AvisoReglaCuentaCorriente({
    super.key,
    this.texto =
        'Las deudas de Cuenta Corriente se cobran en el día. Si no se pagan, desde el día siguiente el cliente figura como moroso.',
    this.destacado = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = destacado ? AppColors.orange : AppColors.steelBlue;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule_outlined, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texto,
              style: AppTextStyles.footer.copyWith(fontSize: 12.5, color: AppColors.graphiteGray),
            ),
          ),
        ],
      ),
    );
  }
}
