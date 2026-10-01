import 'package:flutter/material.dart';

import '../../../models/chofer_cuenta.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

class ChoferesLista extends StatelessWidget {
  final List<ChoferCuenta> cuentas;
  final ValueChanged<ChoferCuenta> onEditar;
  final String mensajeVacio;

  const ChoferesLista({
    super.key,
    required this.cuentas,
    required this.onEditar,
    this.mensajeVacio = 'Todavía no hay choferes con cuenta.',
  });

  @override
  Widget build(BuildContext context) {
    if (cuentas.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 44, horizontal: 16),
        child: Column(
          children: [
            const Icon(Icons.person_search_outlined, size: 40, color: AppColors.badgeGray),
            const SizedBox(height: 10),
            Text(mensajeVacio, textAlign: TextAlign.center, style: AppTextStyles.link),
          ],
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final compacto = constraints.maxWidth < 640;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!compacto) const _Encabezado(),
            for (var i = 0; i < cuentas.length; i++)
              _FilaChofer(
                cuenta: cuentas[i],
                compacto: compacto,
                par: i.isEven,
                onEditar: () => onEditar(cuentas[i]),
              ),
          ],
        );
      },
    );
  }
}

class _Encabezado extends StatelessWidget {
  const _Encabezado();

  @override
  Widget build(BuildContext context) {
    const estilo = TextStyle(
      fontSize: 10.5,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.3,
      color: AppColors.graphiteGray,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.inputBorder)),
      ),
      child: const Row(
        children: [
          SizedBox(width: 50),
          Expanded(flex: 4, child: Text('CHOFER', style: estilo)),
          Expanded(flex: 4, child: Text('CORREO', style: estilo)),
          Expanded(flex: 2, child: Text('VÍNCULO API', style: estilo)),
          SizedBox(width: 110),
        ],
      ),
    );
  }
}

class _FilaChofer extends StatelessWidget {
  final ChoferCuenta cuenta;
  final bool compacto;
  final bool par;
  final VoidCallback onEditar;

  const _FilaChofer({
    required this.cuenta,
    required this.compacto,
    required this.par,
    required this.onEditar,
  });

  @override
  Widget build(BuildContext context) {
    final nombre = Text(
      cuenta.nombreMostrado,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.steelBlue),
    );
    final correo = Text(
      cuenta.email,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTextStyles.input.copyWith(fontSize: 13.5, color: AppColors.graphiteGray),
    );
    final boton = compacto
        ? IconButton(
            tooltip: 'Editar correo o contraseña',
            onPressed: onEditar,
            icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.orange),
          )
        : TextButton.icon(
            onPressed: onEditar,
            icon: const Icon(Icons.edit_outlined, size: 17),
            label: const Text('Editar'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.orange,
              textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            ),
          );

    return Container(
      padding: EdgeInsets.symmetric(horizontal: compacto ? 14 : 20, vertical: 12),
      decoration: BoxDecoration(
        color: par ? AppColors.white : AppColors.background.withOpacity(0.5),
        border: Border(bottom: BorderSide(color: AppColors.inputBorder.withOpacity(0.6))),
      ),
      child: Row(
        children: [
          _Avatar(nombre: cuenta.nombreMostrado),
          const SizedBox(width: 14),
          if (compacto)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  nombre,
                  const SizedBox(height: 2),
                  correo,
                  if (cuenta.idChoferExterno != null) ...[
                    const SizedBox(height: 6),
                    const _BadgeVinculo(),
                  ],
                ],
              ),
            )
          else ...[
            Expanded(flex: 4, child: nombre),
            Expanded(flex: 4, child: correo),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: cuenta.idChoferExterno != null
                    ? const _BadgeVinculo()
                    : Text('—', style: AppTextStyles.footer.copyWith(color: AppColors.graphiteGray)),
              ),
            ),
          ],
          SizedBox(
            width: compacto ? 44 : 110,
            child: Align(alignment: Alignment.centerRight, child: boton),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String nombre;

  const _Avatar({required this.nombre});

  String get _iniciales {
    final partes = nombre.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (partes.isEmpty) return '?';
    if (partes.length == 1) return partes.first.substring(0, 1).toUpperCase();
    return (partes.first.substring(0, 1) + partes[1].substring(0, 1)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.orange.withOpacity(0.12),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.orange.withOpacity(0.5)),
      ),
      child: Text(
        _iniciales,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.orange),
      ),
    );
  }
}

class _BadgeVinculo extends StatelessWidget {
  const _BadgeVinculo();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.steelBlue.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.link_rounded, size: 13, color: AppColors.steelBlue),
          SizedBox(width: 4),
          Text(
            'Vinculado',
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.steelBlue),
          ),
        ],
      ),
    );
  }
}
