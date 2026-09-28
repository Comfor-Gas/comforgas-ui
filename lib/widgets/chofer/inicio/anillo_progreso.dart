import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

class AnilloProgreso extends StatelessWidget {
  final double progreso;
  final double diametro;
  final double grosor;
  final Color color;
  final Widget centro;

  const AnilloProgreso({
    super.key,
    required this.progreso,
    required this.color,
    required this.centro,
    this.diametro = 120,
    this.grosor = 11,
  });

  @override
  Widget build(BuildContext context) {
    final destino = progreso.isNaN ? 0.0 : progreso.clamp(0.0, 1.0).toDouble();
    return SizedBox(
      width: diametro,
      height: diametro,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: destino),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, valor, _) => CircularProgressIndicator(
                value: valor,
                strokeWidth: grosor,
                strokeCap: StrokeCap.round,
                color: color,
                backgroundColor: AppColors.background,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(grosor + 4),
            child: FittedBox(fit: BoxFit.scaleDown, child: centro),
          ),
        ],
      ),
    );
  }
}
