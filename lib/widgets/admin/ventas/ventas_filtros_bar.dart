import 'package:flutter/material.dart';
import '../../../core/responsive.dart';
import '../../../models/venta_monitoreo.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../utils/date_format_utils.dart';

class VentasFiltrosBar extends StatelessWidget {
  final TextEditingController choferController;
  final TextEditingController clienteController;
  final EstadoVentaMonitoreo? estadoSeleccionado;
  final ValueChanged<EstadoVentaMonitoreo?> onEstadoChanged;
  final DateTime fecha;
  final VoidCallback onTapFecha;

  const VentasFiltrosBar({
    super.key,
    required this.choferController,
    required this.clienteController,
    required this.estadoSeleccionado,
    required this.onEstadoChanged,
    required this.fecha,
    required this.onTapFecha,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Filtros de Búsqueda', style: AppTextStyles.label),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final campos = <Widget>[
                _CampoBusqueda(
                  label: 'Buscador por Chofer',
                  hint: 'Nombre del chofer',
                  icon: Icons.person_outline,
                  controller: choferController,
                ),
                _CampoBusqueda(
                  label: 'Buscador por Cliente',
                  hint: 'Nombre del cliente',
                  icon: Icons.storefront_outlined,
                  controller: clienteController,
                ),
                _CampoEstado(
                  seleccionado: estadoSeleccionado,
                  onChanged: onEstadoChanged,
                ),
                _CampoFecha(fecha: fecha, onTap: onTapFecha),
              ];

              if (Responsive.isDesktop(constraints)) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: campos[0]),
                    const SizedBox(width: 14),
                    Expanded(flex: 3, child: campos[1]),
                    const SizedBox(width: 14),
                    Expanded(flex: 3, child: campos[2]),
                    const SizedBox(width: 14),
                    Expanded(flex: 2, child: campos[3]),
                  ],
                );
              }

              return Column(
                children: [
                  for (final campo in campos)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: campo,
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CampoContenedor extends StatelessWidget {
  final String label;
  final Widget child;

  const _CampoContenedor({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: AppColors.graphiteGray,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _CampoBusqueda extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController controller;

  const _CampoBusqueda({
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return _CampoContenedor(
      label: label,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.inputBorder),
        ),
        child: TextField(
          controller: controller,
          style: AppTextStyles.input,
          cursorColor: AppColors.steelBlue,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 13),
            hintText: hint,
            hintStyle: AppTextStyles.hint.copyWith(fontSize: 14),
            prefixIcon: Icon(icon, color: AppColors.inputHint, size: 19),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            suffixIcon: ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, _) {
                if (value.text.isEmpty) return const SizedBox.shrink();
                return IconButton(
                  icon: const Icon(Icons.close, size: 17, color: AppColors.inputHint),
                  onPressed: controller.clear,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _CampoEstado extends StatelessWidget {
  final EstadoVentaMonitoreo? seleccionado;
  final ValueChanged<EstadoVentaMonitoreo?> onChanged;

  const _CampoEstado({required this.seleccionado, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return _CampoContenedor(
      label: 'Buscador por Estado',
      child: Container(
        height: 47,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.inputBorder),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<EstadoVentaMonitoreo?>(
            value: seleccionado,
            isExpanded: true,
            icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.inputHint),
            style: AppTextStyles.input,
            hint: Row(
              children: [
                const Icon(Icons.filter_alt_outlined,
                    color: AppColors.inputHint, size: 19),
                const SizedBox(width: 10),
                Text('Todos los estados', style: AppTextStyles.hint.copyWith(fontSize: 14)),
              ],
            ),
            items: [
              DropdownMenuItem<EstadoVentaMonitoreo?>(
                value: null,
                child: Text('Todos los estados', style: AppTextStyles.input),
              ),
              for (final estado in EstadoVentaMonitoreoMapper.filtrables)
                DropdownMenuItem<EstadoVentaMonitoreo?>(
                  value: estado,
                  child: Text(estado.label, style: AppTextStyles.input),
                ),
            ],
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}

class _CampoFecha extends StatelessWidget {
  final DateTime fecha;
  final VoidCallback onTap;

  const _CampoFecha({required this.fecha, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _CampoContenedor(
      label: 'Jornada',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 47,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.inputBorder),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  color: AppColors.inputHint, size: 18),
              const SizedBox(width: 10),
              Text(
                formatFechaCorta(fecha),
                style: AppTextStyles.input.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
