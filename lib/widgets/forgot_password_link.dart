import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class ForgotPasswordLink extends StatefulWidget {
  final VoidCallback? onTap;

  const ForgotPasswordLink({super.key, this.onTap});

  @override
  State<ForgotPasswordLink> createState() => _ForgotPasswordLinkState();
}

class _ForgotPasswordLinkState extends State<ForgotPasswordLink> {
  bool _active = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _active = true),
      onTapUp: (_) => setState(() => _active = false),
      onTapCancel: () => setState(() => _active = false),
      onTap: widget.onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _active = true),
        onExit: (_) => setState(() => _active = false),
        child: Text(
          '¿Olvidé mi contraseña?',
          style: AppTextStyles.link.copyWith(
            color: AppColors.graphiteGray,
            decoration:
                _active ? TextDecoration.underline : TextDecoration.none,
            decorationColor: AppColors.graphiteGray,
          ),
        ),
      ),
    );
  }
}
