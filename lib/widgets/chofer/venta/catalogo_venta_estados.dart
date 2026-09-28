import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../common/carga/zona_carga.dart';

class CatalogoVentaSeccion extends StatelessWidget {
  final String titulo;

  const CatalogoVentaSeccion({super.key, required this.titulo});

  @override
  Widget build(BuildContext context) {
    return Text(titulo, style: AppTextStyles.label.copyWith(fontSize: 15));
  }
}

class CatalogoVentaCargando extends StatelessWidget {
  const CatalogoVentaCargando({super.key});

  @override
  Widget build(BuildContext context) {
    return ReportarCarga(
      cargando: true,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 34),
            const SizedBox(height: 16),
            Text(
              'Consultando el stock de tu camión…',
              style: AppTextStyles.link,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class CatalogoVentaVacio extends StatelessWidget {
  final String? aviso;

  const CatalogoVentaVacio({super.key, this.aviso});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inventory_2_outlined,
                size: 56, color: AppColors.inputHint),
            const SizedBox(height: 16),
            Text(
              aviso ??
                  'No hay garrafas llenas disponibles en el stock de tu camión para este cliente.',
              textAlign: TextAlign.center,
              style: AppTextStyles.link,
            ),
          ],
        ),
      ),
    );
  }
}
