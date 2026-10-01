import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/responsive.dart';
import '../../../models/chofer_cuenta.dart';
import '../../../models/chofer_externo.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../common/filtros/filtros.dart';

class DatosCuentaChofer {
  final String email;
  final String password;
  final ChoferExterno? chofer;

  const DatosCuentaChofer({required this.email, required this.password, this.chofer});
}

class ChoferCuentaDialog extends StatefulWidget {
  final ChoferCuenta? cuenta;
  final List<ChoferExterno> disponibles;
  final String? avisoDisponibles;

  const ChoferCuentaDialog({
    super.key,
    this.cuenta,
    this.disponibles = const [],
    this.avisoDisponibles,
  });

  static Future<DatosCuentaChofer?> crear(
    BuildContext context, {
    required List<ChoferExterno> disponibles,
    String? aviso,
  }) {
    return showDialog<DatosCuentaChofer>(
      context: context,
      builder: (_) => ChoferCuentaDialog(disponibles: disponibles, avisoDisponibles: aviso),
    );
  }

  static Future<DatosCuentaChofer?> editar(BuildContext context, ChoferCuenta cuenta) {
    return showDialog<DatosCuentaChofer>(
      context: context,
      builder: (_) => ChoferCuentaDialog(cuenta: cuenta),
    );
  }

  @override
  State<ChoferCuentaDialog> createState() => _ChoferCuentaDialogState();
}

class _ChoferCuentaDialogState extends State<ChoferCuentaDialog> {
  static final RegExp _regexEmail = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static const int _minimoPassword = 8;

  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmacion = TextEditingController();
  String? _idSeleccionado;
  bool _verPassword = false;

  bool get _esEdicion => widget.cuenta != null;

  ChoferExterno? get _seleccionado {
    for (final c in widget.disponibles) {
      if (c.idChoferExterno == _idSeleccionado) return c;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    final cuenta = widget.cuenta;
    if (cuenta != null) _email.text = cuenta.email;
    for (final c in [_email, _password, _confirmacion]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
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
    return v.length < _minimoPassword ? 'Mínimo $_minimoPassword caracteres.' : null;
  }

  String? get _errorConfirmacion {
    if (_confirmacion.text.isEmpty) return null;
    return _confirmacion.text == _password.text ? null : 'Las contraseñas no coinciden.';
  }

  bool get _valido {
    final email = _email.text.trim();
    final password = _password.text;
    if (email.isEmpty || _errorEmail != null) return false;
    if (_esEdicion) {
      final cambiaEmail = email.toLowerCase() != widget.cuenta!.email.trim().toLowerCase();
      final cambiaPassword = password.isNotEmpty;
      if (!cambiaEmail && !cambiaPassword) return false;
      if (cambiaPassword && (_errorPassword != null || _confirmacion.text != password)) return false;
      return true;
    }
    return _seleccionado != null &&
        password.length >= _minimoPassword &&
        _confirmacion.text == password;
  }

  void _confirmar() {
    if (!_valido) return;
    Navigator.of(context).pop(DatosCuentaChofer(
      email: _email.text.trim(),
      password: _password.text,
      chofer: _seleccionado,
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

  @override
  Widget build(BuildContext context) {
    final movil = Responsive.isMobileContext(context);
    final ancho = math.min(440.0, MediaQuery.sizeOf(context).width - 64);
    final cuenta = widget.cuenta;
    final ojo = IconButton(
      tooltip: _verPassword ? 'Ocultar' : 'Mostrar',
      onPressed: () => setState(() => _verPassword = !_verPassword),
      icon: Icon(
        _verPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        size: 19,
        color: AppColors.graphiteGray,
      ),
    );

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
              _esEdicion ? 'Editar cuenta' : 'Nuevo chofer',
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
              if (cuenta != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.inputBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.badge_outlined, size: 18, color: AppColors.steelBlue),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          cuenta.nombreMostrado,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.label.copyWith(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                Text('Chofer', style: AppTextStyles.label.copyWith(fontSize: 13)),
                const SizedBox(height: 8),
                FiltroBuscable(
                  etiqueta: 'Chofer de la API',
                  icono: Icons.badge_outlined,
                  opciones: [
                    for (final c in widget.disponibles)
                      OpcionFiltro(
                        c.idChoferExterno,
                        c.documento == null ? c.nombre : '${c.nombre} · ${c.documento}',
                      ),
                  ],
                  seleccion: _idSeleccionado,
                  hint: widget.disponibles.isEmpty ? 'No hay choferes disponibles' : 'Elegí un chofer',
                  obligatorio: true,
                  habilitado: widget.disponibles.isNotEmpty,
                  ancho: ancho,
                  onCambio: (id) => setState(() => _idSeleccionado = id),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.avisoDisponibles ??
                      (widget.disponibles.isEmpty
                          ? 'Todos los choferes de la API ya tienen una cuenta asignada.'
                          : 'Solo aparecen los choferes que todavía no tienen cuenta.'),
                  style: AppTextStyles.footer.copyWith(
                    color: widget.avisoDisponibles != null ? AppColors.badgeAmber : AppColors.graphiteGray,
                  ),
                ),
              ],
              const SizedBox(height: 18),
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
                  Icons.lock_outline_rounded,
                  error: _errorPassword,
                  ayuda: _esEdicion
                      ? 'Dejala vacía si no querés cambiarla.'
                      : 'Mínimo $_minimoPassword caracteres.',
                  sufijo: ojo,
                ),
              ),
              if (!_esEdicion || _password.text.isNotEmpty) ...[
                const SizedBox(height: 14),
                TextField(
                  controller: _confirmacion,
                  obscureText: !_verPassword,
                  autocorrect: false,
                  enableSuggestions: false,
                  cursorColor: AppColors.orange,
                  onSubmitted: (_) => _confirmar(),
                  decoration: _decoracion(
                    'Repetir contraseña',
                    Icons.lock_reset_rounded,
                    error: _errorConfirmacion,
                  ),
                ),
              ],
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
            _esEdicion ? 'Guardar cambios' : 'Crear cuenta',
            style: AppTextStyles.button.copyWith(color: _valido ? AppColors.orange : AppColors.badgeGray),
          ),
        ),
      ],
    );
  }
}
