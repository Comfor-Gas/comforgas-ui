import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/responsive.dart';
import '../../../models/administrador_cuenta.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

class DatosAdministrador {
  final String nombre;
  final String email;
  final String password;

  const DatosAdministrador({required this.nombre, required this.email, required this.password});
}

class AdministradorDialog extends StatefulWidget {
  final AdministradorCuenta? cuenta;

  const AdministradorDialog({super.key, this.cuenta});

  static Future<DatosAdministrador?> crear(BuildContext context) {
    return showDialog<DatosAdministrador>(
      context: context,
      builder: (_) => const AdministradorDialog(),
    );
  }

  static Future<DatosAdministrador?> editar(BuildContext context, AdministradorCuenta cuenta) {
    return showDialog<DatosAdministrador>(
      context: context,
      builder: (_) => AdministradorDialog(cuenta: cuenta),
    );
  }

  @override
  State<AdministradorDialog> createState() => _AdministradorDialogState();
}

class _AdministradorDialogState extends State<AdministradorDialog> {
  static final RegExp _regexEmail = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static const int _minimoPassword = 8;

  final _nombre = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmacion = TextEditingController();
  bool _verPassword = false;

  bool get _esEdicion => widget.cuenta != null;

  @override
  void initState() {
    super.initState();
    final cuenta = widget.cuenta;
    if (cuenta != null) {
      _nombre.text = cuenta.nombre;
      _email.text = cuenta.email;
    }
    for (final c in [_nombre, _email, _password, _confirmacion]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _nombre.dispose();
    _email.dispose();
    _password.dispose();
    _confirmacion.dispose();
    super.dispose();
  }

  String? get _errorEmail {
    final v = _email.text.trim();
    if (v.isEmpty) return null;
    return _regexEmail.hasMatch(v) ? null : 'Ingresá un correo válido.';
  }

  String? get _errorPassword {
    final v = _password.text;
    if (v.isEmpty) return null;
    return v.length >= _minimoPassword ? null : 'Mínimo $_minimoPassword caracteres.';
  }

  String? get _errorConfirmacion {
    final v = _confirmacion.text;
    if (v.isEmpty) return null;
    return v == _password.text ? null : 'Las contraseñas no coinciden.';
  }

  bool get _passwordValida {
    if (_esEdicion && _password.text.isEmpty && _confirmacion.text.isEmpty) return true;
    return _password.text.length >= _minimoPassword && _confirmacion.text == _password.text;
  }

  bool get _hayCambios {
    final cuenta = widget.cuenta;
    if (cuenta == null) return true;
    return _nombre.text.trim() != cuenta.nombre.trim() ||
        _email.text.trim().toLowerCase() != cuenta.email.trim().toLowerCase() ||
        _password.text.isNotEmpty;
  }

  bool get _valido =>
      _nombre.text.trim().isNotEmpty &&
      _email.text.trim().isNotEmpty &&
      _errorEmail == null &&
      _passwordValida &&
      _hayCambios;

  void _confirmar() {
    if (!_valido) return;
    Navigator.of(context).pop(DatosAdministrador(
      nombre: _nombre.text.trim(),
      email: _email.text.trim(),
      password: _password.text,
    ));
  }

  InputDecoration _decoracion(String etiqueta, IconData icono, {String? error, String? ayuda, Widget? sufijo}) {
    return InputDecoration(
      labelText: etiqueta,
      prefixIcon: Icon(icono, size: 19, color: AppColors.steelBlue),
      suffixIcon: sufijo,
      errorText: error,
      helperText: ayuda,
      helperMaxLines: 2,
      isDense: true,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.inputBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.orange),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      floatingLabelStyle: const TextStyle(color: AppColors.orange),
    );
  }

  Widget _ojo() {
    return IconButton(
      tooltip: _verPassword ? 'Ocultar' : 'Mostrar',
      onPressed: () => setState(() => _verPassword = !_verPassword),
      icon: Icon(
        _verPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        size: 19,
        color: AppColors.graphiteGray,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final movil = Responsive.isMobileContext(context);
    final ancho = math.min(440.0, MediaQuery.sizeOf(context).width - 64);
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: movil
          ? const EdgeInsets.symmetric(horizontal: 16, vertical: 24)
          : const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      titlePadding: EdgeInsets.fromLTRB(movil ? 16 : 24, 22, movil ? 16 : 24, 0),
      contentPadding: EdgeInsets.fromLTRB(movil ? 16 : 24, 16, movil ? 16 : 24, 8),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.orange.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _esEdicion ? Icons.manage_accounts_outlined : Icons.person_add_alt_1_outlined,
              size: 20,
              color: AppColors.orange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _esEdicion ? 'Editar administrador' : 'Nuevo administrador',
              style: AppTextStyles.title.copyWith(fontSize: 18),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: ancho,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 4),
              TextField(
                controller: _nombre,
                textCapitalization: TextCapitalization.words,
                cursorColor: AppColors.orange,
                decoration: _decoracion('Nombre completo', Icons.badge_outlined),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                cursorColor: AppColors.orange,
                decoration: _decoracion('Correo', Icons.alternate_email_rounded, error: _errorEmail),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _password,
                obscureText: !_verPassword,
                autocorrect: false,
                enableSuggestions: false,
                cursorColor: AppColors.orange,
                decoration: _decoracion(
                  _esEdicion ? 'Nueva contraseña' : 'Contraseña',
                  Icons.lock_outline,
                  error: _errorPassword,
                  ayuda: _errorPassword == null
                      ? (_esEdicion
                          ? 'Dejala vacía para no cambiarla. Mínimo $_minimoPassword caracteres.'
                          : 'Mínimo $_minimoPassword caracteres.')
                      : null,
                  sufijo: _ojo(),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _confirmacion,
                obscureText: !_verPassword,
                autocorrect: false,
                enableSuggestions: false,
                cursorColor: AppColors.orange,
                onSubmitted: (_) => _confirmar(),
                decoration: _decoracion(
                  _esEdicion ? 'Repetir nueva contraseña' : 'Repetir contraseña',
                  Icons.lock_outline,
                  error: _errorConfirmacion,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.steelBlue.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, size: 17, color: AppColors.steelBlue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _esEdicion
                            ? 'Si cambiás el correo o la contraseña, se cierran las sesiones abiertas '
                                'de este administrador y tiene que volver a ingresar con los datos nuevos.'
                            : 'El nuevo administrador ingresa al panel web con este correo y contraseña, '
                                'en la pestaña "Administración".',
                        style: AppTextStyles.footer.copyWith(color: AppColors.steelBlue),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancelar', style: AppTextStyles.button.copyWith(color: AppColors.graphiteGray)),
        ),
        TextButton(
          onPressed: _valido ? _confirmar : null,
          child: Text(
            _esEdicion ? 'Guardar cambios' : 'Crear administrador',
            style: AppTextStyles.button.copyWith(color: _valido ? AppColors.orange : AppColors.badgeGray),
          ),
        ),
      ],
    );
  }
}
