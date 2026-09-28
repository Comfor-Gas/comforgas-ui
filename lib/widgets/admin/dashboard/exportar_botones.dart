import 'package:flutter/material.dart';
import '../../../repositories/reporte_export_repository.dart';
import '../../../theme/app_colors.dart';

class ExportarBotones extends StatelessWidget {
  final bool exportando;
  final ValueChanged<TipoReporteExport> onExcel;

  const ExportarBotones({super.key, required this.exportando, required this.onExcel});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        PopupMenuButton<TipoReporteExport>(
          enabled: !exportando,
          tooltip: 'Exportar a Excel',
          position: PopupMenuPosition.under,
          color: AppColors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onSelected: onExcel,
          itemBuilder: (context) => [
            for (final tipo in TipoReporteExport.values)
              PopupMenuItem<TipoReporteExport>(
                value: tipo,
                child: Row(
                  children: [
                    const Icon(Icons.table_view_outlined, size: 18, color: AppColors.steelBlue),
                    const SizedBox(width: 10),
                    Text(
                      tipo.etiqueta,
                      style: const TextStyle(fontSize: 13.5, color: AppColors.steelBlue, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
          ],
          child: _BotonExport(
            icono: Icons.grid_on_outlined,
            texto: exportando ? 'Generando Excel…' : 'Exportar Excel',
            fondo: AppColors.orange,
            cargando: exportando,
            conMenu: true,
          ),
        ),
        const Tooltip(
          message: 'La exportación a PDF estará disponible próximamente',
          child: _BotonExport(
            icono: Icons.picture_as_pdf_outlined,
            texto: 'Exportar PDF',
            fondo: AppColors.inputBorder,
            deshabilitado: true,
          ),
        ),
      ],
    );
  }
}

class _BotonExport extends StatelessWidget {
  final IconData icono;
  final String texto;
  final Color fondo;
  final bool cargando;
  final bool deshabilitado;
  final bool conMenu;

  const _BotonExport({
    required this.icono,
    required this.texto,
    required this.fondo,
    this.cargando = false,
    this.deshabilitado = false,
    this.conMenu = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorTexto = deshabilitado ? AppColors.inputHint : AppColors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        color: cargando ? fondo.withOpacity(0.75) : fondo,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (cargando)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
            )
          else
            Icon(icono, size: 18, color: colorTexto),
          const SizedBox(width: 8),
          Text(
            texto,
            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: colorTexto, letterSpacing: 0.3),
          ),
          if (conMenu && !cargando) ...[
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, size: 20, color: colorTexto),
          ],
        ],
      ),
    );
  }
}
