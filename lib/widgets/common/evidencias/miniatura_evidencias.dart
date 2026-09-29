import 'package:flutter/material.dart';

import '../../../models/evidencia_fotografica_model.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import 'galeria_evidencias_dialog.dart';

class MiniaturaEvidencias extends StatelessWidget {
  final List<EvidenciaFotograficaModel> fotos;
  final bool cargando;
  final double tamanio;
  final String tituloGaleria;
  final bool mostrarVacio;
  final bool contadorSiempre;

  const MiniaturaEvidencias({
    super.key,
    required this.fotos,
    this.cargando = false,
    this.tamanio = 56,
    this.tituloGaleria = 'Fotos de la visita',
    this.mostrarVacio = false,
    this.contadorSiempre = true,
  });

  BoxDecoration _caja({Color? borde, double ancho = 1}) => BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borde ?? AppColors.inputBorder, width: ancho),
      );

  @override
  Widget build(BuildContext context) {
    if (cargando) {
      return Container(
        width: tamanio,
        height: tamanio,
        decoration: _caja(),
        child: const Center(
          child: SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.orange),
          ),
        ),
      );
    }

    if (fotos.isEmpty) {
      if (!mostrarVacio) return const SizedBox.shrink();
      return Tooltip(
        message: 'Sin foto',
        child: Container(
          width: tamanio,
          height: tamanio,
          decoration: _caja(),
          child: Icon(Icons.no_photography_outlined, size: tamanio * 0.4, color: AppColors.inputHint),
        ),
      );
    }

    return Tooltip(
      message: 'Ver foto',
      child: InkWell(
        onTap: () => GaleriaEvidenciasDialog.mostrar(context, fotos, titulo: tituloGaleria),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: tamanio,
          height: tamanio,
          decoration: _caja(borde: AppColors.orange.withOpacity(0.6), ancho: 1.4),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10.5),
                child: Image.network(
                  urlEvidencia(fotos.first.urlAlmacenamiento),
                  fit: BoxFit.cover,
                  webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const Center(
                      child: SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.orange),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stack) => Center(
                    child: Icon(Icons.photo_camera_outlined, size: tamanio * 0.4, color: AppColors.inputHint),
                  ),
                ),
              ),
              if (contadorSiempre || fotos.length > 1)
                Positioned(
                  right: 3,
                  bottom: 3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.steelBlue,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.photo_library_outlined, size: 11, color: AppColors.white),
                        const SizedBox(width: 3),
                        Text(
                          '${fotos.length}',
                          style: AppTextStyles.footer.copyWith(
                            color: AppColors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
