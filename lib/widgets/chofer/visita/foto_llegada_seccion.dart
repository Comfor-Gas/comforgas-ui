import 'dart:io';

import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../evidencia_captura_card.dart';
import 'aviso_requisito_visita.dart';

class FotoLlegadaSeccion extends StatelessWidget {
  final File? foto;
  final bool registrada;
  final bool cargando;
  final VoidCallback onCapturar;

  const FotoLlegadaSeccion({
    super.key,
    required this.foto,
    required this.registrada,
    required this.cargando,
    required this.onCapturar,
  });

  @override
  Widget build(BuildContext context) {
    if (registrada && foto == null) {
      return const _FotoRegistrada();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'FOTO DE LLEGADA',
          style: AppTextStyles.footer.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            color: AppColors.steelBlue,
          ),
        ),
        const SizedBox(height: 8),
        EvidenciaCapturaCard(
          titulo: registrada ? 'Foto de llegada\nregistrada' : 'Sacá la foto de la fachada\n(obligatoria)',
          foto: foto,
          cargando: cargando,
          onCapturar: onCapturar,
        ),
        const SizedBox(height: 10),
        if (registrada)
          const _FotoRegistrada()
        else
          const AvisoRequisitoVisita(
            icono: Icons.photo_camera_outlined,
            texto: 'La foto de llegada confirma que estás en el domicilio. Sacala para habilitar la venta, el comodato, los canjes y el cierre de la visita.',
          ),
      ],
    );
  }
}

class _FotoRegistrada extends StatelessWidget {
  const _FotoRegistrada();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.check_circle, size: 18, color: AppColors.badgeGreen),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Foto de llegada registrada.',
            style: AppTextStyles.footer.copyWith(color: AppColors.graphiteGray, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
