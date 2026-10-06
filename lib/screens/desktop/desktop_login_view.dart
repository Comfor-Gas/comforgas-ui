import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../router/role_router.dart';
import '../../widgets/labeled_text_field.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/desktop/desktop_side_panel.dart';
import '../../widgets/desktop/desktop_footer.dart';
import '../../widgets/selector_tipo_acceso.dart';

class DesktopLoginView extends StatefulWidget {
  const DesktopLoginView({super.key});

  @override
  State<DesktopLoginView> createState() => _DesktopLoginViewState();
}

class _DesktopLoginViewState extends State<DesktopLoginView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _localError;
  TipoAcceso _tipo = TipoAcceso.administracion;

  bool get _esChofer => _tipo == TipoAcceso.chofer;

  void _cambiarTipo(TipoAcceso tipo) {
    if (tipo == _tipo) return;
    _emailController.clear();
    _passwordController.clear();
    context.read<AuthProvider>().clearError();
    setState(() {
      _tipo = tipo;
      _localError = null;
    });
  }

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
      setState(() => _localError =
          _esChofer ? 'Completá usuario y contraseña.' : 'Completá correo y contraseña.');
      return;
    }

    setState(() => _localError = null);

    final auth = context.read<AuthProvider>();
    final ok = _esChofer
        ? await auth.loginChofer(usuario: email, password: password)
        : await auth.login(email: email, password: password);

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
                              Center(
                                child: Text(
                                  _esChofer
                                      ? 'Ingrese su usuario y contraseña de GLP Gas'
                                      : 'Ingrese sus credenciales de administrador '
                                          'para continuar',
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.desktopSubtitle,
                                ),
                              ),
                              const SizedBox(height: 24),
                              SelectorTipoAcceso(
                                seleccion: _tipo,
                                habilitado: !isLoading,
                                onCambio: _cambiarTipo,
                              ),
                              const SizedBox(height: 24),
                              LabeledTextField(
                                key: ValueKey('desktop_email_field_${_tipo.name}'),
                                label: _esChofer ? 'Usuario' : 'Correo Electrónico',
                                hint: _esChofer ? 'ej: juan.garcia' : 'administrador@gmail.com',
                                icon: _esChofer ? Icons.person_outline : Icons.mail_outline,
                                controller: _emailController,
                                keyboardType: _esChofer ? TextInputType.text : TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                onChanged: (_) => _clearError(),
                              ),
                              const SizedBox(height: 18),
                              LabeledTextField(
                                key: const ValueKey('desktop_password_field'),
                                label: 'Contraseña',
                                hint: '••••••••••',
                                icon: Icons.lock_outline,
                                obscure: true,
                                controller: _passwordController,
                                textInputAction: TextInputAction.done,
                                onSubmitted: _submit,
                                onChanged: (_) => _clearError(),
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
                                text: _esChofer ? 'Ingresar' : 'Ingresar al panel',
                                isLoading: isLoading,
                                onPressed: _submit,
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
