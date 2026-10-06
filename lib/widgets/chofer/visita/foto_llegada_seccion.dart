import 'dart:io';

import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../evidencia_captura_card.dart';
import 'aviso_requisito_visita.dart';

class FotoLlegadaSeccion extends StatelessWidget {
  final File? foto;
  final String? urlRegistrada;
  final bool registrada;
  final bool verificando;
  final bool cargando;
  final bool editable;
  final VoidCallback onCapturar;

  const FotoLlegadaSeccion({
    super.key,
    required this.foto,
    required this.registrada,
    this.urlRegistrada,
    this.verificando = false,
    required this.cargando,
    this.editable = true,
    required this.onCapturar,
  });

  @override
  Widget build(BuildContext context) {
    if (verificando && !registrada) {
      return Row(
        children: [
          const Icon(Icons.hourglass_top_rounded, size: 18, color: AppColors.steelBlue),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Verificando la foto de llegada…',
              style: AppTextStyles.footer.copyWith(color: AppColors.graphiteGray, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      );
    }
    final tieneImagen = foto != null || (urlRegistrada != null && urlRegistrada!.trim().isNotEmpty);
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
        if (registrada && !tieneImagen && !editable)
          const SizedBox.shrink()
        else
          EvidenciaCapturaCard(
            titulo: registrada
                ? 'Foto de llegada registrada\nTocá para sacar otra'
                : 'Sacá la foto de la fachada\n(obligatoria)',
            foto: foto,
            urlFoto: urlRegistrada,
            cargando: cargando,
            editable: editable,
            etiquetaCambiar: 'Editar foto',
            onCapturar: onCapturar,
          ),
        const SizedBox(height: 10),
        if (registrada)
          _FotoRegistrada(editable: editable)
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
  final bool editable;

  const _FotoRegistrada({required this.editable});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          editable ? Icons.check_circle : Icons.lock_outline,
          size: 18,
          color: editable ? AppColors.badgeGreen : AppColors.steelBlue,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            editable
                ? 'Foto de llegada registrada. Tocá el lápiz para cambiarla mientras la visita esté en curso.'
                : 'Foto de llegada registrada. Ya no se puede modificar.',
            style: AppTextStyles.footer.copyWith(color: AppColors.graphiteGray, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
