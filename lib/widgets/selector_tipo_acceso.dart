import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum TipoAcceso { chofer, administracion }

class SelectorTipoAcceso extends StatelessWidget {
  final TipoAcceso seleccion;
  final ValueChanged<TipoAcceso> onCambio;
  final bool habilitado;

  const SelectorTipoAcceso({
    super.key,
    required this.seleccion,
    required this.onCambio,
    this.habilitado = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Opcion(
              texto: 'Chofer',
              icono: Icons.local_shipping_outlined,
              activa: seleccion == TipoAcceso.chofer,
              onTap: habilitado ? () => onCambio(TipoAcceso.chofer) : null,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _Opcion(
              texto: 'Administración',
              icono: Icons.admin_panel_settings_outlined,
              activa: seleccion == TipoAcceso.administracion,
              onTap: habilitado ? () => onCambio(TipoAcceso.administracion) : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _Opcion extends StatelessWidget {
  final String texto;
  final IconData icono;
  final bool activa;
  final VoidCallback? onTap;

  const _Opcion({required this.texto, required this.icono, required this.activa, this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = activa ? AppColors.white : AppColors.steelBlue;
    return Material(
      color: activa ? AppColors.orange : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: activa ? null : onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icono, size: 17, color: color),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  texto,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
