import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

class DashboardCard extends StatelessWidget {
  final String titulo;
  final String? subtitulo;
  final Widget? accion;
  final Widget child;
  final EdgeInsetsGeometry padding;

  const DashboardCard({
    super.key,
    required this.titulo,
    this.subtitulo,
    this.accion,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(20, 18, 20, 20),
  });

  @override
  Widget build(BuildContext context) {
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
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 10,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(titulo, style: AppTextStyles.label.copyWith(fontSize: 16, fontWeight: FontWeight.w700)),
                  if (subtitulo != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitulo!, style: AppTextStyles.footer.copyWith(color: AppColors.graphiteGray)),
                  ],
                ],
              ),
              if (accion != null) accion!,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class DashboardVacio extends StatelessWidget {
  final String mensaje;
  final IconData icono;
  final double alto;

  const DashboardVacio({
    super.key,
    required this.mensaje,
    this.icono = Icons.insights_outlined,
    this.alto = 220,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: alto,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 34, color: AppColors.badgeGray),
            const SizedBox(height: 10),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: AppTextStyles.link.copyWith(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class LeyendaSerie extends StatelessWidget {
  final Color color;
  final String etiqueta;
  final bool linea;

  const LeyendaSerie({super.key, required this.color, required this.etiqueta, this.linea = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: linea ? 16 : 10,
          height: linea ? 3 : 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(linea ? 2 : 3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          etiqueta,
          style: AppTextStyles.footer.copyWith(color: AppColors.graphiteGray, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
