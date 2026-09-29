import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../../core/responsive.dart';
import '../../../theme/app_colors.dart';
import 'decoracion_filtro.dart';

class CampoBusquedaFiltro extends StatefulWidget {
  final TextEditingController controller;
  final String etiqueta;
  final String hint;
  final IconData icono;
  final double ancho;
  final ValueChanged<String>? onSubmitted;
  final TextInputType? keyboardType;

  const CampoBusquedaFiltro({
    super.key,
    required this.controller,
    this.etiqueta = 'Buscar',
    this.hint = 'Escribí para buscar',
    this.icono = Icons.search,
    this.ancho = 280,
    this.onSubmitted,
    this.keyboardType,
  });

  @override
  State<CampoBusquedaFiltro> createState() => _CampoBusquedaFiltroState();
}

class _CampoBusquedaFiltroState extends State<CampoBusquedaFiltro> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refrescar);
  }

  @override
  void didUpdateWidget(covariant CampoBusquedaFiltro oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_refrescar);
      widget.controller.addListener(_refrescar);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refrescar);
    super.dispose();
  }

  void _refrescar() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final activo = widget.controller.text.trim().isNotEmpty;
    final ancho = Responsive.isMobileContext(context)
        ? math.max(widget.ancho, MediaQuery.sizeOf(context).width)
        : widget.ancho;
    return SizedBox(
      width: ancho,
      child: TextField(
        controller: widget.controller,
        keyboardType: widget.keyboardType,
        style: estiloTextoFiltro,
        cursorColor: AppColors.steelBlue,
        onSubmitted: widget.onSubmitted,
        decoration: decoracionFiltro(
          etiqueta: widget.etiqueta,
          icono: widget.icono,
          activo: activo,
          hint: widget.hint,
          sufijo: activo
              ? IconButton(
                  tooltip: 'Borrar',
                  icon: const Icon(Icons.close, size: 16, color: AppColors.graphiteGray),
                  onPressed: widget.controller.clear,
                )
              : null,
        ),
      ),
    );
  }
}
