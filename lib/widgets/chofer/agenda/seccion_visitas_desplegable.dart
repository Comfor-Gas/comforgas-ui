import 'package:flutter/material.dart';

import '../../../models/visita_model.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

class SeccionVisitasDesplegable extends StatefulWidget {
  final String titulo;
  final IconData icono;
  final Color acento;
  final List<VisitaModel> visitas;
  final bool expandido;
  final ValueChanged<bool> onToggle;
  final Widget Function(VisitaModel) itemBuilder;
  final int tamanioPagina;
  final String? mensajeVacio;

  const SeccionVisitasDesplegable({
    super.key,
    required this.titulo,
    required this.icono,
    required this.visitas,
    required this.expandido,
    required this.onToggle,
    required this.itemBuilder,
    this.acento = AppColors.steelBlue,
    this.tamanioPagina = 15,
    this.mensajeVacio,
  });

  @override
  State<SeccionVisitasDesplegable> createState() => _SeccionVisitasDesplegableState();
}

class _SeccionVisitasDesplegableState extends State<SeccionVisitasDesplegable> {
  late int _visibles = widget.tamanioPagina;

  @override
  void didUpdateWidget(covariant SeccionVisitasDesplegable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.expandido && oldWidget.expandido) _visibles = widget.tamanioPagina;
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.visitas.length;
    final mostrar = total < _visibles ? total : _visibles;
    final restantes = total - mostrar;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.acento.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => widget.onToggle(!widget.expandido),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(widget.icono, size: 18, color: widget.acento),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.titulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.label.copyWith(color: widget.acento),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
                    decoration: BoxDecoration(
                      color: widget.acento.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$total',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: widget.acento),
                    ),
                  ),
                  const SizedBox(width: 6),
                  AnimatedRotation(
                    turns: widget.expandido ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: Icon(Icons.keyboard_arrow_down, color: widget.acento),
                  ),
                ],
              ),
            ),
          ),
          if (widget.expandido)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (total == 0 && widget.mensajeVacio != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Text(
                        widget.mensajeVacio!,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.link.copyWith(fontSize: 13),
                      ),
                    ),
                  for (var i = 0; i < mostrar; i++) widget.itemBuilder(widget.visitas[i]),
                  if (restantes > 0)
                    TextButton.icon(
                      onPressed: () => setState(() => _visibles += widget.tamanioPagina),
                      icon: const Icon(Icons.expand_more_rounded, size: 18),
                      label: Text(
                        'Mostrar ${restantes < widget.tamanioPagina ? restantes : widget.tamanioPagina} más '
                        '($restantes restantes)',
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.orange,
                        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
