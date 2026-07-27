import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/logo_header.dart';
import '../widgets/labeled_text_field.dart';
import '../widgets/fingerprint_button.dart';
import '../widgets/primary_button.dart';
import '../widgets/forgot_password_link.dart';
import '../widgets/footer_decoration.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 32,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const LogoHeader(),
                          const SizedBox(height: 1),
                          Center(
                            child: Text(
                              'Iniciar Sesión',
                              style: AppTextStyles.title,
                            ),
                          ),
                          const SizedBox(height: 28),
                          const LabeledTextField(
                            label: 'Usuario',
                            hint: 'Nombre de usuario',
                            icon: Icons.person_outline,
                          ),
                          const SizedBox(height: 18),
                          const LabeledTextField(
                            label: 'Contraseña',
                            hint: '••••••••',
                            icon: Icons.lock_outline,
                            obscure: true,
                          ),
                          const SizedBox(height: 24),
                          const Center(child: FingerprintButton()),
                          const SizedBox(height: 5),
                          const PrimaryButton(text: 'Ingresar al sistema'),
                          const SizedBox(height: 18),
                          const Center(child: ForgotPasswordLink()),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const FooterDecoration(),
          ],
        ),
      ),
    );
  }
}
