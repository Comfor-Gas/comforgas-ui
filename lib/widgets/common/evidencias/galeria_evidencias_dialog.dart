import 'package:flutter/material.dart';

import '../../../config/api_config.dart';
import '../../../core/responsive.dart';
import '../../../models/evidencia_fotografica_model.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

const Set<String> _hostsLocales = {'localhost', '127.0.0.1', '0.0.0.0'};

String urlEvidencia(String url) {
  final partes = url.trim().split('?');
  var base = partes.first.replaceAll('%2F', '/').replaceAll('%2f', '/');
  base = _ajustarHost(base);
  return partes.length > 1 ? '$base?${partes.sublist(1).join('?')}' : base;
}

String _ajustarHost(String base) {
  final api = Uri.tryParse(ApiConfig.baseUrl);
  if (api == null || api.host.isEmpty) return base;
  if (base.startsWith('/')) return '${api.scheme}://${api.authority}$base';
  final uri = Uri.tryParse(base);
  if (uri == null || !_hostsLocales.contains(uri.host) || uri.host == api.host) return base;
  return '${api.scheme}://${api.authority}${uri.path}';
}

class GaleriaEvidenciasDialog extends StatefulWidget {
  final List<EvidenciaFotograficaModel> fotos;
  final String titulo;

  const GaleriaEvidenciasDialog({super.key, required this.fotos, this.titulo = 'Fotos de la visita'});

  static Future<void> mostrar(BuildContext context, List<EvidenciaFotograficaModel> fotos, {String titulo = 'Fotos de la visita'}) {
    if (fotos.isEmpty) return Future.value();
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (_) => GaleriaEvidenciasDialog(fotos: fotos, titulo: titulo),
    );
  }

  @override
  State<GaleriaEvidenciasDialog> createState() => GaleriaEvidenciasDialogState();
}

class GaleriaEvidenciasDialogState extends State<GaleriaEvidenciasDialog> {
  final PageController _controller = PageController();
  int _indice = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _etiquetaTipo(String tipo) {
    final limpio = tipo.trim().replaceAll('_', ' ').toLowerCase();
    if (limpio.isEmpty) return 'Evidencia';
    return limpio[0].toUpperCase() + limpio.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final fotos = widget.fotos;
    final actual = fotos[_indice];
    final movil = Responsive.isMobileContext(context);

    return Dialog(
      backgroundColor: AppColors.white,
      insetPadding: movil
          ? const EdgeInsets.symmetric(horizontal: 12, vertical: 24)
          : const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 720),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(movil ? 14 : 18, 16, movil ? 4 : 10, 12),
              child: Row(
                children: [
                  const Icon(Icons.photo_library_outlined, size: 20, color: AppColors.orange),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.titulo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.title.copyWith(fontSize: 17),
                    ),
                  ),
                  Text(
                    '${_indice + 1} / ${fotos.length}',
                    style: AppTextStyles.desktopSubtitle.copyWith(fontSize: 13),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.close, size: 20, color: AppColors.inputHint),
                  ),
                ],
              ),
            ),
            Flexible(
              child: Container(
                color: AppColors.background,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PageView.builder(
                      controller: _controller,
                      itemCount: fotos.length,
                      onPageChanged: (i) => setState(() => _indice = i),
                      itemBuilder: (context, i) {
                        return InteractiveViewer(
                          minScale: 1,
                          maxScale: 4,
                          child: Center(
                            child: Image.network(
                              urlEvidencia(fotos[i].urlAlmacenamiento),
                              fit: BoxFit.contain,
                              webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return const Center(
                                  child: CircularProgressIndicator(color: AppColors.orange),
                                );
                              },
                              errorBuilder: (context, error, stack) {
                                debugPrint('Evidencia no cargó: $error · ${fotos[i].urlAlmacenamiento}');
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(28),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.broken_image_outlined, size: 40, color: AppColors.inputHint),
                                        SizedBox(height: 8),
                                        Text('No se pudo cargar la foto', style: AppTextStyles.hint),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                    if (fotos.length > 1) ...[
                      Positioned(
                        left: 6,
                        child: _FlechaGaleria(
                          icon: Icons.chevron_left,
                          onTap: _indice > 0
                              ? () => _controller.previousPage(
                                    duration: const Duration(milliseconds: 220),
                                    curve: Curves.easeOut,
                                  )
                              : null,
                        ),
                      ),
                      Positioned(
                        right: 6,
                        child: _FlechaGaleria(
                          icon: Icons.chevron_right,
                          onTap: _indice < fotos.length - 1
                              ? () => _controller.nextPage(
                                    duration: const Duration(milliseconds: 220),
                                    curve: Curves.easeOut,
                                  )
                              : null,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(movil ? 14 : 18, 12, movil ? 14 : 18, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.orange.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _etiquetaTipo(actual.tipoEvidencia),
                              style: AppTextStyles.label.copyWith(fontSize: 12, color: AppColors.orange),
                            ),
                          ),
                        ),
                      ),
                      if (actual.timestampCaptura != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          _formatoFecha(actual.timestampCaptura!),
                          style: AppTextStyles.footer.copyWith(color: AppColors.graphiteGray),
                        ),
                      ],
                    ],
                  ),
                  if ((actual.observaciones ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      actual.observaciones!.trim(),
                      style: AppTextStyles.input.copyWith(fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatoFecha(DateTime f) {
    final dd = f.day.toString().padLeft(2, '0');
    final mm = f.month.toString().padLeft(2, '0');
    final hh = f.hour.toString().padLeft(2, '0');
    final min = f.minute.toString().padLeft(2, '0');
    return '$dd/$mm/${f.year} · $hh:$min';
  }
}

class _FlechaGaleria extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _FlechaGaleria({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: onTap == null ? AppColors.white.withValues(alpha: 0.4) : AppColors.white,
      shape: const CircleBorder(),
      elevation: onTap == null ? 0 : 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            icon,
            size: 26,
            color: onTap == null ? AppColors.inputHint : AppColors.steelBlue,
          ),
        ),
      ),
    );
  }
}
