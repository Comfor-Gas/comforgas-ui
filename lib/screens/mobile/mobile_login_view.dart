import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../router/role_router.dart';
import '../../widgets/logo_header.dart';
import '../../widgets/labeled_text_field.dart';
import '../../widgets/fingerprint_button.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/forgot_password_link.dart';
import '../../widgets/footer_decoration.dart';

/// Login optimizado para Choferes en ruta (iOS / Android).
class MobileLoginView extends StatefulWidget {
  const MobileLoginView({super.key});

  @override
  State<MobileLoginView> createState() => _MobileLoginViewState();
}

class _MobileLoginViewState extends State<MobileLoginView> {
  // NOTA: el backend autentica por email (ver AuthApi.login). Este campo
  // se muestra como "Usuario" en la UI del chofer, pero internamente se
  // envía como email.
  final _userController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _localError;

  @override
  void dispose() {
    _userController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final user = _userController.text.trim();
    final password = _passwordController.text;

    if (user.isEmpty || password.isEmpty) {
      setState(() => _localError = 'Completá usuario y contraseña.');
      return;
    }

    setState(() => _localError = null);

    final auth = context.read<AuthProvider>();
    final ok = await auth.login(email: user, password: password);

    if (!mounted) return;
    if (ok) {
      RoleRouter.goToRoleHome(context, auth.role);
    }
  }

  void _clearError() {
    if (_localError != null) setState(() => _localError = null);
    context.read<AuthProvider>().clearError();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select<AuthProvider, bool>((a) => a.isLoading);
    final providerError =
        context.select<AuthProvider, String?>((a) => a.errorMessage);
    final errorMessage = _localError ?? providerError;

    return SafeArea(
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
                        LabeledTextField(
                          key: const ValueKey('mobile_user_field'),
                          label: 'Usuario',
                          hint: 'Nombre de usuario',
                          icon: Icons.person_outline,
                          controller: _userController,
                          textInputAction: TextInputAction.next,
                          onChanged: (_) => _clearError(),
                        ),
                        const SizedBox(height: 18),
                        LabeledTextField(
                          key: const ValueKey('mobile_password_field'),
                          label: 'Contraseña',
                          hint: '••••••••',
                          icon: Icons.lock_outline,
                          obscure: true,
                          controller: _passwordController,
                          textInputAction: TextInputAction.done,
                          onSubmitted: _submit,
                          onChanged: (_) => _clearError(),
                        ),
                        if (errorMessage != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            errorMessage,
                            style: AppTextStyles.errorText,
                            textAlign: TextAlign.center,
                          ),
                        ],
                        const SizedBox(height: 24),
                        const Center(child: FingerprintButton()),
                        const SizedBox(height: 5),
                        PrimaryButton(
                          text: 'Ingresar al sistema',
                          isLoading: isLoading,
                          onPressed: _submit,
                        ),
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
    );
  }
}
