import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

class BarraProgresoMetrica extends StatelessWidget {
  final double progreso;
  final double? meta;
  final Color color;
  final double alto;

  const BarraProgresoMetrica({
    super.key,
    required this.progreso,
    required this.color,
    this.meta,
    this.alto = 12,
  });

  @override
  Widget build(BuildContext context) {
    final destino = progreso.isNaN ? 0.0 : progreso.clamp(0.0, 1.0).toDouble();
    final marca = meta?.clamp(0.0, 1.0).toDouble();
    return LayoutBuilder(
      builder: (context, constraints) {
        final ancho = constraints.maxWidth;
        return SizedBox(
          height: alto + 8,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.centerLeft,
            children: [
              Container(
                height: alto,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(alto),
                ),
              ),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: destino),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (context, valor, _) => Container(
                  width: ancho * valor,
                  height: alto,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(alto),
                  ),
                ),
              ),
              if (marca != null)
                Positioned(
                  left: ancho > 2 ? (ancho * marca - 1).clamp(0.0, ancho - 2).toDouble() : 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 2,
                    decoration: BoxDecoration(
                      color: AppColors.steelBlue,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
