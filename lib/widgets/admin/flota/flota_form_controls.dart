import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

class FlotaBotonPrimario extends StatelessWidget {
  final String texto;
  final bool cargando;
  final VoidCallback? onTap;
  final IconData? icono;

  const FlotaBotonPrimario({
    super.key,
    required this.texto,
    this.cargando = false,
    this.onTap,
    this.icono,
  });

  @override
  Widget build(BuildContext context) {
    final habilitado = onTap != null && !cargando;
    return GestureDetector(
      onTap: habilitado ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: habilitado ? AppColors.orange : AppColors.badgeGray.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: cargando
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.white),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icono != null) ...[
                    Icon(icono, size: 18, color: AppColors.white),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      texto,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class FlotaBotonSecundario extends StatelessWidget {
  final String texto;
  final VoidCallback? onTap;

  const FlotaBotonSecundario({super.key, required this.texto, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.inputBorder),
        ),
        child: Text(
          texto,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.graphiteGray,
          ),
        ),
      ),
    );
  }
}

class FlotaCampoLabel extends StatelessWidget {
  final String texto;

  const FlotaCampoLabel(this.texto, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(texto, style: AppTextStyles.label.copyWith(fontSize: 13)),
    );
  }
}

class FlotaDropdown<T> extends StatelessWidget {
  final T? value;
  final String hint;
  final IconData? prefijo;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const FlotaDropdown({
    super.key,
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
    this.prefijo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(left: prefijo != null ? 12 : 14, right: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Row(
        children: [
          if (prefijo != null) ...[
            Icon(prefijo, size: 18, color: AppColors.inputHint),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: value,
                isExpanded: true,
                icon: const Icon(Icons.expand_more, color: AppColors.inputHint),
                style: AppTextStyles.input,
                hint: Text(hint, style: AppTextStyles.hint),
                items: items,
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
