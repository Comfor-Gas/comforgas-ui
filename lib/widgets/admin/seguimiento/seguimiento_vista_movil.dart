import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

class SeguimientoVistaMovil extends StatelessWidget {
  final int indice;
  final ValueChanged<int> onCambio;
  final Widget mapa;
  final Widget listado;
  final int cantidadVisitas;

  const SeguimientoVistaMovil({
    super.key,
    required this.indice,
    required this.onCambio,
    required this.mapa,
    required this.listado,
    required this.cantidadVisitas,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SelectorVista(
          indice: indice,
          onCambio: onCambio,
          cantidadVisitas: cantidadVisitas,
        ),
        const SizedBox(height: 12),
        Expanded(
          child: IndexedStack(
            index: indice,
            sizing: StackFit.expand,
            children: [mapa, listado],
          ),
        ),
      ],
    );
  }
}

class _SelectorVista extends StatelessWidget {
  final int indice;
  final ValueChanged<int> onCambio;
  final int cantidadVisitas;

  const _SelectorVista({
    required this.indice,
    required this.onCambio,
    required this.cantidadVisitas,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: _OpcionVista(
              icono: Icons.map_outlined,
              texto: 'Mapa',
              activa: indice == 0,
              onTap: () => onCambio(0),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _OpcionVista(
              icono: Icons.list_alt_outlined,
              texto: 'Listado ($cantidadVisitas)',
              activa: indice == 1,
              onTap: () => onCambio(1),
            ),
          ),
        ],
      ),
    );
  }
}

class _OpcionVista extends StatelessWidget {
  final IconData icono;
  final String texto;
  final bool activa;
  final VoidCallback onTap;

  const _OpcionVista({
    required this.icono,
    required this.texto,
    required this.activa,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = activa ? AppColors.white : AppColors.steelBlue;
    return Material(
      color: activa ? AppColors.orange : Colors.transparent,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icono, size: 18, color: color),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  texto,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
