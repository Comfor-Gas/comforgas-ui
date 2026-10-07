import 'dart:io';

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../common/evidencias/galeria_evidencias_dialog.dart';

class EvidenciaCapturaCard extends StatelessWidget {
  final String titulo;
  final File? foto;
  final String? urlFoto;
  final bool cargando;
  final bool editable;
  final String? etiquetaCambiar;
  final VoidCallback onCapturar;

  const EvidenciaCapturaCard({
    super.key,
    required this.titulo,
    required this.onCapturar,
    this.foto,
    this.urlFoto,
    this.cargando = false,
    this.editable = true,
    this.etiquetaCambiar,
  });

  bool get _tieneImagen => foto != null || (urlFoto != null && urlFoto!.trim().isNotEmpty);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: InkWell(
          onTap: cargando || !editable || (_tieneImagen && etiquetaCambiar != null) ? null : onCapturar,
          child: Ink(
            decoration: BoxDecoration(color: AppColors.graphiteGray.withValues(alpha: 0.9)),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (foto != null)
                  Image.file(foto!, fit: BoxFit.cover)
                else if (_tieneImagen)
                  Image.network(
                    urlEvidencia(urlFoto!),
                    fit: BoxFit.cover,
                    webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.orange),
                      );
                    },
                    errorBuilder: (context, error, stack) => Container(
                      color: const Color(0xFF3A4552),
                      alignment: Alignment.center,
                      child: const Icon(Icons.image_not_supported_outlined, color: Colors.white70, size: 30),
                    ),
                  )
                else
                  Container(color: const Color(0xFF3A4552)),
                if (_tieneImagen && editable && etiquetaCambiar != null && !cargando)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Material(
                      color: AppColors.orange,
                      shape: const CircleBorder(),
                      elevation: 3,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: onCapturar,
                        child: Tooltip(
                          message: etiquetaCambiar!,
                          child: const Padding(
                            padding: EdgeInsets.all(9),
                            child: Icon(Icons.edit_rounded, size: 18, color: AppColors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (_tieneImagen && !editable)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.steelBlue.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock_outline, size: 14, color: AppColors.white),
                          SizedBox(width: 5),
                          Text(
                            'Bloqueada',
                            style: TextStyle(color: AppColors.white, fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (!_tieneImagen) ...[
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.photo_camera_outlined, color: Colors.white70, size: 34),
                        const SizedBox(height: 10),
                        Text(
                          titulo,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.label.copyWith(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const _EncuadreEsquinas(),
                ],
                if (cargando)
                  Container(
                    color: Colors.black.withValues(alpha: 0.45),
                    child: const Center(
                      child: SizedBox(
                        height: 30,
                        width: 30,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation(AppColors.white),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Dibuja las 4 esquinas de encuadre típicas de un visor de cámara.
class _EncuadreEsquinas extends StatelessWidget {
  const _EncuadreEsquinas();

  static const double _size = 26;
  static const double _thickness = 3;
  static const Color _color = Colors.white70;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Stack(
        children: const [
          Align(alignment: Alignment.topLeft, child: _Esquina(top: true, left: true)),
          Align(alignment: Alignment.topRight, child: _Esquina(top: true, left: false)),
          Align(alignment: Alignment.bottomLeft, child: _Esquina(top: false, left: true)),
          Align(alignment: Alignment.bottomRight, child: _Esquina(top: false, left: false)),
        ],
      ),
    );
  }
}

class _Esquina extends StatelessWidget {
  final bool top;
  final bool left;

  const _Esquina({required this.top, required this.left});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _EncuadreEsquinas._size,
      height: _EncuadreEsquinas._size,
      decoration: BoxDecoration(
        border: Border(
          top: top
              ? const BorderSide(color: _EncuadreEsquinas._color, width: _EncuadreEsquinas._thickness)
              : BorderSide.none,
          bottom: !top
              ? const BorderSide(color: _EncuadreEsquinas._color, width: _EncuadreEsquinas._thickness)
              : BorderSide.none,
          left: left
              ? const BorderSide(color: _EncuadreEsquinas._color, width: _EncuadreEsquinas._thickness)
              : BorderSide.none,
          right: !left
              ? const BorderSide(color: _EncuadreEsquinas._color, width: _EncuadreEsquinas._thickness)
              : BorderSide.none,
        ),
      ),
    );
  }
}
