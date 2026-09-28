import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/formato_dashboard.dart';

class PaginadorCompacto extends StatelessWidget {
  final int pagina;
  final int porPagina;
  final int total;
  final ValueChanged<int> onCambio;
  final String unidad;

  const PaginadorCompacto({
    super.key,
    required this.pagina,
    required this.porPagina,
    required this.total,
    required this.onCambio,
    this.unidad = '',
  });

  int get paginas => total == 0 ? 1 : ((total - 1) ~/ porPagina) + 1;

  static int acotar(int pagina, int porPagina, int total) {
    final paginas = total == 0 ? 1 : ((total - 1) ~/ porPagina) + 1;
    if (pagina < 0) return 0;
    if (pagina >= paginas) return paginas - 1;
    return pagina;
  }

  @override
  Widget build(BuildContext context) {
    if (total <= porPagina) return const SizedBox.shrink();
    final desde = pagina * porPagina + 1;
    final hasta = (desde + porPagina - 1) > total ? total : desde + porPagina - 1;
    final sufijo = unidad.isEmpty ? '' : ' $unidad';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${formatEntero(desde)}–${formatEntero(hasta)} de ${formatEntero(total)}$sufijo',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.graphiteGray),
        ),
        const SizedBox(width: 8),
        _Flecha(
          icono: Icons.chevron_left,
          tooltip: 'Anterior',
          onTap: pagina > 0 ? () => onCambio(pagina - 1) : null,
        ),
        const SizedBox(width: 4),
        _Flecha(
          icono: Icons.chevron_right,
          tooltip: 'Siguiente',
          onTap: pagina < paginas - 1 ? () => onCambio(pagina + 1) : null,
        ),
      ],
    );
  }
}

class _Flecha extends StatelessWidget {
  final IconData icono;
  final String tooltip;
  final VoidCallback? onTap;

  const _Flecha({required this.icono, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final habilitado = onTap != null;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: habilitado ? AppColors.background : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.inputBorder),
          ),
          child: Icon(
            icono,
            size: 18,
            color: habilitado ? AppColors.steelBlue : AppColors.inputBorder,
          ),
        ),
      ),
    );
  }
}
