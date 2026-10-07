import 'package:flutter/material.dart';

import '../../../models/vista_cuentas_corrientes.dart';
import '../../../theme/app_colors.dart';

class VistaCuentasSelector extends StatelessWidget {
  final VistaCuentasCorrientes seleccion;
  final ValueChanged<VistaCuentasCorrientes> onCambio;
  final Map<VistaCuentasCorrientes, int?> contadores;
  final bool habilitado;

  const VistaCuentasSelector({
    super.key,
    required this.seleccion,
    required this.onCambio,
    this.contadores = const {},
    this.habilitado = true,
  });

  IconData _icono(VistaCuentasCorrientes v) {
    switch (v) {
      case VistaCuentasCorrientes.cobranzas:
        return Icons.payments_outlined;
      case VistaCuentasCorrientes.morosos:
        return Icons.warning_amber_rounded;
      case VistaCuentasCorrientes.todas:
        return Icons.people_outline;
    }
  }

  Color _acento(VistaCuentasCorrientes v) =>
      v == VistaCuentasCorrientes.morosos ? AppColors.error : AppColors.orange;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final v in VistaCuentasCorrientes.values)
              _Pestania(
                texto: v.etiqueta,
                icono: _icono(v),
                acento: _acento(v),
                activa: v == seleccion,
                contador: contadores[v],
                onTap: habilitado && v != seleccion ? () => onCambio(v) : null,
              ),
          ],
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}

class _Pestania extends StatelessWidget {
  final String texto;
  final IconData icono;
  final Color acento;
  final bool activa;
  final int? contador;
  final VoidCallback? onTap;

  const _Pestania({
    required this.texto,
    required this.icono,
    required this.acento,
    required this.activa,
    required this.onTap,
    this.contador,
  });

  @override
  Widget build(BuildContext context) {
    final colorTexto = activa ? AppColors.white : AppColors.steelBlue;
    return Material(
      color: activa ? acento : AppColors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: activa ? acento : AppColors.inputBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icono, size: 17, color: activa ? AppColors.white : acento),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  texto,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colorTexto),
                ),
              ),
              if (contador != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                  decoration: BoxDecoration(
                    color: activa ? AppColors.white.withValues(alpha: 0.25) : acento.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$contador',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: activa ? AppColors.white : acento,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
