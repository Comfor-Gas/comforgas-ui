import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';


Future<void> showAppAlert({
  required BuildContext context,
  required String title,
  required String message,
  String actionLabel = 'Entendido',
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(title, style: AppTextStyles.title),
      content: Text(message, style: AppTextStyles.input),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(
            actionLabel,
            style: AppTextStyles.button.copyWith(color: AppColors.orange),
          ),
        ),
      ],
    ),
  );
}
