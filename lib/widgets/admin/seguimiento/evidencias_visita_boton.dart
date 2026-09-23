import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/evidencia_fotografica_model.dart';
import '../../../models/visita_estado.dart';
import '../../../providers/auth_provider.dart';
import '../../../repositories/evidencia_repository.dart';
import '../../../repositories/network_exception.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

String _urlEvidencia(String url) {
  final partes = url.split('?');
  final base = partes.first.replaceAll('%2F', '/').replaceAll('%2f', '/');
  return partes.length > 1 ? '$base?${partes.sublist(1).join('?')}' : base;
}

class EvidenciasVisitaBoton extends StatefulWidget {
  final int? idVisita;
  final VisitaEstado estado;

  const EvidenciasVisitaBoton({
    super.key,
    required this.idVisita,
    required this.estado,
  });

  @override
  State<EvidenciasVisitaBoton> createState() => _EvidenciasVisitaBotonState();
}

class _EvidenciasVisitaBotonState extends State<EvidenciasVisitaBoton> {
  bool _cargando = false;
  List<EvidenciaFotograficaModel> _fotos = const [];

  static const Set<VisitaEstado> _estadosConEvidencia = {
    VisitaEstado.visitado,
    VisitaEstado.completada,
    VisitaEstado.cancelada,
    VisitaEstado.noAsistio,
  };

  bool get _corresponde =>
      widget.idVisita != null && _estadosConEvidencia.contains(widget.estado);

  @override
  void initState() {
    super.initState();
    if (_corresponde) _cargar();
  }

  @override
  void didUpdateWidget(covariant EvidenciasVisitaBoton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.idVisita != widget.idVisita || oldWidget.estado != widget.estado) {
      _fotos = const [];
      if (_corresponde) {
        _cargar();
      } else {
        setState(() {});
      }
    }
  }

  Future<void> _cargar() async {
    final idVisita = widget.idVisita;
    if (idVisita == null) return;
    setState(() => _cargando = true);
    final apiClient = context.read<AuthProvider>().apiClient;
    try {
      final fotos = await EvidenciaRepository(apiClient).listarPorVisita(idVisita);
      if (!mounted) return;
      setState(() {
        _fotos = fotos.where((f) => f.urlAlmacenamiento.trim().isNotEmpty).toList();
        _cargando = false;
      });
    } on NetworkException {
      if (!mounted) return;
      setState(() => _cargando = false);
    } catch (_) {
      if (!mounted) return;
      setState(() => _cargando = false);
    }
  }

  void _abrirGaleria() {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (_) => _GaleriaEvidenciasDialog(fotos: _fotos),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_corresponde) return const SizedBox.shrink();

    if (_cargando) {
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.inputBorder),
        ),
        child: const Center(
          child: SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.orange),
          ),
        ),
      );
    }

    if (_fotos.isEmpty) return const SizedBox.shrink();

    return InkWell(
      onTap: _abrirGaleria,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.orange.withOpacity(0.6), width: 1.4),
          color: AppColors.background,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10.5),
              child: Image.network(
                _urlEvidencia(_fotos.first.urlAlmacenamiento),
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
                errorBuilder: (context, error, stack) => const Center(
                  child: Icon(Icons.photo_camera_outlined, size: 22, color: AppColors.inputHint),
                ),
              ),
            ),
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
                      '${_fotos.length}',
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
    );
  }
}

class _GaleriaEvidenciasDialog extends StatefulWidget {
  final List<EvidenciaFotograficaModel> fotos;

  const _GaleriaEvidenciasDialog({required this.fotos});

  @override
  State<_GaleriaEvidenciasDialog> createState() => _GaleriaEvidenciasDialogState();
}

class _GaleriaEvidenciasDialogState extends State<_GaleriaEvidenciasDialog> {
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

    return Dialog(
      backgroundColor: AppColors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 720),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 10, 12),
              child: Row(
                children: [
                  const Icon(Icons.photo_library_outlined, size: 20, color: AppColors.orange),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Fotos de la visita',
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
                              _urlEvidencia(fotos[i].urlAlmacenamiento),
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
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.orange.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _etiquetaTipo(actual.tipoEvidencia),
                          style: AppTextStyles.label.copyWith(fontSize: 12, color: AppColors.orange),
                        ),
                      ),
                      const Spacer(),
                      if (actual.timestampCaptura != null)
                        Text(
                          _formatoFecha(actual.timestampCaptura!),
                          style: AppTextStyles.footer.copyWith(color: AppColors.graphiteGray),
                        ),
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
      color: onTap == null ? AppColors.white.withOpacity(0.4) : AppColors.white,
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
