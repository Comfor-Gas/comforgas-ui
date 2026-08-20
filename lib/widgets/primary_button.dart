import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class PrimaryButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;

  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bool inactive = widget.onPressed == null && !widget.isLoading;
    final bool disabled = widget.isLoading || widget.onPressed == null;

    final Color backgroundColor;
    if (inactive) {
      backgroundColor = AppColors.badgeGray.withOpacity(0.55);
    } else if (_pressed) {
      backgroundColor = const Color(0xFFD8611A);
    } else {
      backgroundColor =
          AppColors.orange.withOpacity(widget.isLoading ? 0.7 : 1);
    }

    final Color contentColor =
        inactive ? Colors.white.withOpacity(0.9) : AppColors.white;

    return MouseRegion(
      cursor: disabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: disabled ? null : (_) => setState(() => _pressed = true),
        onTapUp: disabled ? null : (_) => setState(() => _pressed = false),
        onTapCancel: disabled ? null : () => setState(() => _pressed = false),
        onTap: disabled ? null : widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: (_pressed || inactive)
                ? []
                : [
                    BoxShadow(
                      color: AppColors.orange.withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
          ),
          child: widget.isLoading
              ? const Center(
                  child: SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      valueColor: AlwaysStoppedAnimation(AppColors.white),
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.text.toUpperCase(),
                      style: AppTextStyles.button.copyWith(color: contentColor),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.chevron_right, color: contentColor, size: 20),
                  ],
                ),
        ),
      ),
    );
  }
}
