import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

class ContadorEnvases extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int? max;
  final bool enabled;

  const ContadorEnvases({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max,
    this.enabled = true,
  });

  bool get _puedeRestar => enabled && value > min;
  bool get _puedeSumar => enabled && (max == null || value < max!);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _BotonRedondo(
          icon: Icons.remove,
          onTap: _puedeRestar ? () => onChanged(value - 1) : null,
        ),
        Container(
          width: 96,
          margin: const EdgeInsets.symmetric(horizontal: 18),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.inputBorder, width: 1.2),
          ),
          child: Text(
            value.toString().padLeft(2, '0'),
            textAlign: TextAlign.center,
            style: AppTextStyles.title.copyWith(fontSize: 30),
          ),
        ),
        _BotonRedondo(
          icon: Icons.add,
          onTap: _puedeSumar ? () => onChanged(value + 1) : null,
        ),
      ],
    );
  }
}

class _BotonRedondo extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _BotonRedondo({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool activo = onTap != null;
    return Material(
      color: activo ? AppColors.orange : AppColors.badgeGray.withOpacity(0.4),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          height: 52,
          width: 52,
          child: Icon(
            icon,
            color: AppColors.white,
            size: 26,
          ),
        ),
      ),
    );
  }
}
