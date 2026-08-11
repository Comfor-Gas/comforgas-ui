import 'dart:io';

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// Tarjeta tipo "visor de cámara" para capturar la evidencia fotográfica
/// (fachada, comodato) de una visita. Muestra el encuadre con esquinas
/// mientras no hay foto, y la vista previa una vez capturada.
class EvidenciaCapturaCard extends StatelessWidget {
  final String titulo;
  final File? foto;
  final bool cargando;
  final VoidCallback onCapturar;

  const EvidenciaCapturaCard({
    super.key,
    required this.titulo,
    required this.onCapturar,
    this.foto,
    this.cargando = false,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: InkWell(
          onTap: cargando ? null : onCapturar,
          child: Ink(
            decoration: BoxDecoration(color: AppColors.graphiteGray.withOpacity(0.9)),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (foto != null)
                  Image.file(foto!, fit: BoxFit.cover)
                else
                  Container(color: const Color(0xFF3A4552)),
                if (foto == null) ...[
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
                    color: Colors.black.withOpacity(0.45),
                    child: const Center(
                      child: SizedBox(
                        height: 30,
                        width: 30,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
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
