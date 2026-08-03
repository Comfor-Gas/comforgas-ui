import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/labeled_text_field.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/forgot_password_link.dart';
import '../../widgets/desktop/desktop_side_panel.dart';
import '../../widgets/desktop/desktop_footer.dart';

class DesktopLoginView extends StatelessWidget {
  const DesktopLoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [

        const Expanded(flex: 5, child: DesktopSidePanel()),

   
        Expanded(
          flex: 6,
          child: ColoredBox(
            color: AppColors.white,
            child: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 48,
                          vertical: 32,
                        ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const _DesktopLogo(),
                              const SizedBox(height: 24),
                              const Center(
                                child: Text(
                                  'Iniciar Sesión',
                                  style: AppTextStyles.desktopTitle,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Center(
                                child: Text(
                                  'Ingrese sus credenciales de administrador '
                                  'para continuar',
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.desktopSubtitle,
                                ),
                              ),
                              const SizedBox(height: 32),
                              const LabeledTextField(
                                label: 'Correo Electrónico',
                                hint: 'administrador@gmail.com',
                                icon: Icons.mail_outline,
                              ),
                              const SizedBox(height: 18),
                              const LabeledTextField(
                                label: 'Contraseña',
                                hint: '••••••••••',
                                icon: Icons.lock_outline,
                                obscure: true,
                              ),
                              const SizedBox(height: 28),
                              const PrimaryButton(text: 'Ingresar al panel'),
                              const SizedBox(height: 18),
                              const Center(
                                child: ForgotPasswordLink(
                                  text: '¿Olvidó su contraseña?',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const DesktopFooter(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DesktopLogo extends StatelessWidget {
  const _DesktopLogo();

  @override
  Widget build(BuildContext context) {
    return const Image(
      image: AssetImage('assets/images/logo_comfor_gas.png'),
      height: 110,
      fit: BoxFit.contain,
    );
  }
}
