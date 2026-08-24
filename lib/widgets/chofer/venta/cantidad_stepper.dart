import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

class CantidadStepper extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final IconData icono;
  final Color acento;
  final int valor;
  final ValueChanged<int> onChanged;
  final int minimo;
  final int maximo;

  const CantidadStepper({
    super.key,
    required this.titulo,
    required this.subtitulo,
    required this.icono,
    required this.acento,
    required this.valor,
    required this.onChanged,
    this.minimo = 0,
    this.maximo = 999,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        children: [
          Text(
            titulo,
            style: AppTextStyles.label.copyWith(fontSize: 13),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StepButton(
                icono: Icons.remove,
                onTap: valor > minimo ? () => onChanged(valor - 1) : null,
              ),
              Container(
                width: 52,
                alignment: Alignment.center,
                child: Text(
                  '$valor',
                  style: AppTextStyles.title.copyWith(fontSize: 26),
                ),
              ),
              _StepButton(
                icono: Icons.add,
                acento: acento,
                onTap: valor < maximo ? () => onChanged(valor + 1) : null,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Icon(icono, size: 28, color: acento),
          const SizedBox(height: 4),
          Text(
            subtitulo,
            style: AppTextStyles.footer.copyWith(color: acento, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icono;
  final VoidCallback? onTap;
  final Color? acento;

  const _StepButton({required this.icono, this.onTap, this.acento});

  @override
  Widget build(BuildContext context) {
    final habilitado = onTap != null;
    final fondo = acento ?? AppColors.steelBlue;

    return Material(
      color: habilitado ? fondo : AppColors.inputBorder,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            icono,
            color: habilitado ? AppColors.white : AppColors.inputHint,
            size: 22,
          ),
        ),
      ),
    );
  }
}
