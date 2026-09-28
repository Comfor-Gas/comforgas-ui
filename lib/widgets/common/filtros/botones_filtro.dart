import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

class BotonActualizar extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool cargando;
  final String texto;

  const BotonActualizar({
    super.key,
    required this.onPressed,
    this.cargando = false,
    this.texto = 'Actualizar',
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: cargando ? null : onPressed,
      icon: cargando
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.steelBlue),
            )
          : const Icon(Icons.refresh, size: 18),
      label: Text(texto),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.steelBlue,
        side: const BorderSide(color: AppColors.inputBorder),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

class BotonLimpiarFiltros extends StatelessWidget {
  final VoidCallback onPressed;
  final String texto;

  const BotonLimpiarFiltros({super.key, required this.onPressed, this.texto = 'Limpiar filtros'});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.filter_alt_off_outlined, size: 17, color: AppColors.graphiteGray),
      label: Text(
        texto,
        style: const TextStyle(fontSize: 12.5, color: AppColors.graphiteGray, fontWeight: FontWeight.w600),
      ),
    );
  }
}
