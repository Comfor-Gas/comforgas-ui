import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'fingerprint_button.dart';


class AppLockScreen extends StatelessWidget {
  final bool isAuthenticating;
  final int remainingAttempts;
  final int maxAttempts;
  final VoidCallback onRetry;
  final VoidCallback onUseLoginInstead;

  const AppLockScreen({
    super.key,
    required this.isAuthenticating,
    required this.remainingAttempts,
    required this.maxAttempts,
    required this.onRetry,
    required this.onUseLoginInstead,
  });

  @override
  Widget build(BuildContext context) {
    final showAttemptsWarning = remainingAttempts < maxAttempts;

    return Material(
      color: AppColors.background,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock_outline,
                  size: 40,
                  color: AppColors.steelBlue,
                ),
                const SizedBox(height: 16),
                Text(
                  'App bloqueada',
                  style: AppTextStyles.title,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Usá tu huella, rostro o el código del celular para continuar',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.footerText),
                ),
                if (showAttemptsWarning) ...[
                  const SizedBox(height: 8),
                  Text(
                    remainingAttempts > 0
                        ? 'Te queda${remainingAttempts == 1 ? '' : 'n'} $remainingAttempts intento${remainingAttempts == 1 ? '' : 's'}'
                        : 'Sin intentos disponibles',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                isAuthenticating
                    ? const SizedBox(
                        height: 120,
                        width: 120,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : FingerprintButton(onTap: onRetry),
                const SizedBox(height: 32),
                TextButton(
                  onPressed: onUseLoginInstead,
                  child: const Text('Ingresar con usuario y contraseña'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
