import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

class VerComprobanteBoton extends StatelessWidget {
  final VoidCallback onTap;
  final bool expandido;

  const VerComprobanteBoton({super.key, required this.onTap, this.expandido = false});

  @override
  Widget build(BuildContext context) {
    final boton = OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.receipt_long_outlined, size: 16, color: AppColors.orange),
      label: const Text(
        'VER COMPROBANTE',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
          color: AppColors.orange,
        ),
      ),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppColors.orange, width: 1.2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    return expandido ? SizedBox(width: double.infinity, child: boton) : boton;
  }
}
