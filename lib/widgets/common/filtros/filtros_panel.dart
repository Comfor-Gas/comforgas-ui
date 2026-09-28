import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

class FiltrosPanel extends StatelessWidget {
  final List<Widget> filas;
  final String? aviso;
  final EdgeInsetsGeometry padding;

  const FiltrosPanel({
    super.key,
    required this.filas,
    this.aviso,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    final hijos = <Widget>[];
    for (var i = 0; i < filas.length; i++) {
      if (i > 0) hijos.add(const SizedBox(height: 14));
      hijos.add(filas[i]);
    }
    if (aviso != null) {
      hijos.add(const SizedBox(height: 10));
      hijos.add(
        Row(
          children: [
            const Icon(Icons.info_outline, size: 16, color: AppColors.badgeAmber),
            const SizedBox(width: 6),
            Expanded(
              child: Text(aviso!, style: AppTextStyles.footer.copyWith(color: AppColors.graphiteGray)),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: hijos,
      ),
    );
  }
}

class FilaFiltros extends StatelessWidget {
  final List<Widget> children;

  const FilaFiltros({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: children,
    );
  }
}

class EtiquetaFiltro extends StatelessWidget {
  final String texto;

  const EtiquetaFiltro(this.texto, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Text(
        texto.toUpperCase(),
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
          color: AppColors.graphiteGray,
        ),
      ),
    );
  }
}
