import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

class SelectorSegmentado<T> extends StatelessWidget {
  final List<T> opciones;
  final T seleccion;
  final String Function(T) etiqueta;
  final ValueChanged<T> onCambio;

  const SelectorSegmentado({
    super.key,
    required this.opciones,
    required this.seleccion,
    required this.etiqueta,
    required this.onCambio,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Wrap(
        spacing: 2,
        runSpacing: 2,
        children: [
          for (final o in opciones)
            _Segmento(
              texto: etiqueta(o),
              activo: o == seleccion,
              onTap: () => onCambio(o),
            ),
        ],
      ),
    );
  }
}

class _Segmento extends StatelessWidget {
  final String texto;
  final bool activo;
  final VoidCallback onTap;

  const _Segmento({required this.texto, required this.activo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: activo ? AppColors.white : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      elevation: activo ? 1 : 0,
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Text(
            texto,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: activo ? FontWeight.w700 : FontWeight.w500,
              color: activo ? AppColors.orange : AppColors.graphiteGray,
            ),
          ),
        ),
      ),
    );
  }
}
