import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../router/role_router.dart';
import '../../widgets/labeled_text_field.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/forgot_password_link.dart';
import '../../widgets/desktop/desktop_side_panel.dart';
import '../../widgets/desktop/desktop_footer.dart';

class DesktopLoginView extends StatefulWidget {
  const DesktopLoginView({super.key});

  @override
  State<DesktopLoginView> createState() => _DesktopLoginViewState();
}

class _DesktopLoginViewState extends State<DesktopLoginView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _localError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _localError = 'Completá correo y contraseña.');
      return;
    }

    setState(() => _localError = null);

    final auth = context.read<AuthProvider>();
    final ok = await auth.login(email: email, password: password);

    if (!mounted) return;
    if (ok) {
      RoleRouter.goToRoleHome(context, auth.role);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final errorMessage = _localError ?? auth.errorMessage;

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
                              LabeledTextField(
                                label: 'Correo Electrónico',
                                hint: 'administrador@gmail.com',
                                icon: Icons.mail_outline,
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                              ),
                              const SizedBox(height: 18),
                              LabeledTextField(
                                label: 'Contraseña',
                                hint: '••••••••••',
                                icon: Icons.lock_outline,
                                obscure: true,
                                controller: _passwordController,
                                textInputAction: TextInputAction.done,
                                onSubmitted: _submit,
                              ),
                              if (errorMessage != null) ...[
                                const SizedBox(height: 14),
                                Text(
                                  errorMessage,
                                  style: AppTextStyles.errorText,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                              const SizedBox(height: 28),
                              PrimaryButton(
                                text: 'Ingresar al panel',
                                isLoading: auth.isLoading,
                                onPressed: _submit,
                              ),
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
