import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../router/role_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/fingerprint_button.dart';
import '../widgets/footer_decoration.dart';
import '../widgets/forgot_password_link.dart';
import '../widgets/labeled_text_field.dart';
import '../widgets/logo_header.dart';
import '../widgets/primary_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _submitting = false;
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _validateInputs() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    String? emailError;
    String? passwordError;

    if (email.isEmpty) {
      emailError = 'Ingresa tu usuario.';
    } else if (!email.contains('@') || !email.contains('.')) {
      emailError = 'Ingresa un correo válido.';
    }

    if (password.isEmpty) {
      passwordError = 'Ingresa tu contraseña.';
    } else if (password.length < 6) {
      passwordError = 'La contraseña debe tener al menos 6 caracteres.';
    }

    setState(() {
      _emailError = emailError;
      _passwordError = passwordError;
    });

    return emailError == null && passwordError == null;
  }

  Future<void> _handleLogin() async {
    if (_submitting) return;

    FocusScope.of(context).unfocus();

    if (!_validateInputs()) {
      await _showAlert(
        title: 'Revisa los datos',
        message: 'Corrige los campos marcados antes de continuar.',
      );
      return;
    }

    setState(() => _submitting = true);

    final auth = context.read<AuthProvider>();
    final success = await auth.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (success) {
      RoleRouter.goToRoleHome(context, auth.role);
    } else {
      await _showAlert(
        title: 'No se pudo iniciar sesión',
        message: auth.errorMessage ??
            'Ocurrió un error inesperado. Intenta de nuevo.',
      );
    }
  }

  Future<void> _showAlert({
    required String title,
    required String message,
  }) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: AppTextStyles.title),
        content: Text(message, style: AppTextStyles.input),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Entendido',
              style: AppTextStyles.button.copyWith(color: AppColors.orange),
            ),
          ),
        ],
      ),
    );
  }

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
                          LabeledTextField(
                            label: 'Usuario',
                            hint: 'correo@comforgas.com',
                            icon: Icons.person_outline,
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            enabled: !_submitting,
                            errorText: _emailError,
                            onChanged: (_) {
                              if (_emailError != null) {
                                setState(() => _emailError = null);
                              }
                            },
                          ),
                          const SizedBox(height: 18),
                          LabeledTextField(
                            label: 'Contraseña',
                            hint: '••••••••',
                            icon: Icons.lock_outline,
                            obscure: true,
                            controller: _passwordController,
                            textInputAction: TextInputAction.done,
                            enabled: !_submitting,
                            errorText: _passwordError,
                            onSubmitted: (_) => _handleLogin(),
                            onChanged: (_) {
                              if (_passwordError != null) {
                                setState(() => _passwordError = null);
                              }
                            },
                          ),
                          const SizedBox(height: 24),
                          const Center(child: FingerprintButton()),
                          const SizedBox(height: 5),
                          PrimaryButton(
                            text: 'Ingresar al sistema',
                            isLoading: _submitting,
                            onPressed: _submitting ? null : _handleLogin,
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
      ),
    );
  }
}