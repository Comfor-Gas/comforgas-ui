import 'package:flutter/material.dart';

import '../../../models/administrador_cuenta.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

class AdministradoresLista extends StatelessWidget {
  final List<AdministradorCuenta> cuentas;
  final String? idPrincipal;
  final String? idActual;
  final ValueChanged<AdministradorCuenta> onDarDeBaja;
  final ValueChanged<AdministradorCuenta> onEditar;
  final String mensajeVacio;
  final bool habilitado;

  const AdministradoresLista({
    super.key,
    required this.cuentas,
    required this.idPrincipal,
    required this.idActual,
    required this.onDarDeBaja,
    required this.onEditar,
    this.mensajeVacio = 'Todavía no hay administradores.',
    this.habilitado = true,
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
              _FilaAdministrador(
                cuenta: cuentas[i],
                principal: cuentas[i].id == idPrincipal,
                actual: cuentas[i].id == idActual,
                compacto: compacto,
                par: i.isEven,
                habilitado: habilitado,
                editable: cuentas[i].id != idPrincipal || idActual == idPrincipal,
                onDarDeBaja: () => onDarDeBaja(cuentas[i]),
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
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.inputBorder)),
      ),
      child: const Row(
        children: [
          SizedBox(width: 50),
          Expanded(flex: 4, child: Text('ADMINISTRADOR', style: estilo)),
          Expanded(flex: 4, child: Text('CORREO', style: estilo)),
          Expanded(flex: 2, child: Text('ALTA', style: estilo)),
          SizedBox(width: 220),
        ],
      ),
    );
  }
}

class _FilaAdministrador extends StatelessWidget {
  final AdministradorCuenta cuenta;
  final bool principal;
  final bool actual;
  final bool compacto;
  final bool par;
  final bool habilitado;
  final bool editable;
  final VoidCallback onDarDeBaja;
  final VoidCallback onEditar;

  const _FilaAdministrador({
    required this.cuenta,
    required this.principal,
    required this.actual,
    required this.compacto,
    required this.par,
    required this.habilitado,
    required this.editable,
    required this.onDarDeBaja,
    required this.onEditar,
  });

  String get _alta {
    final f = cuenta.creadoEl?.toLocal();
    if (f == null) return '—';
    String dos(int n) => n.toString().padLeft(2, '0');
    return '${dos(f.day)}/${dos(f.month)}/${f.year}';
  }

  Widget _editar() {
    if (!editable) {
      return const Tooltip(
        message: 'Solo la cuenta principal puede editar sus propios datos.',
        child: Padding(
          padding: EdgeInsets.all(8),
          child: Icon(Icons.edit_off_outlined, size: 19, color: AppColors.badgeGray),
        ),
      );
    }
    if (compacto) {
      return IconButton(
        tooltip: 'Editar',
        onPressed: habilitado ? onEditar : null,
        icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.orange),
      );
    }
    return TextButton.icon(
      onPressed: habilitado ? onEditar : null,
      icon: const Icon(Icons.edit_outlined, size: 17),
      label: const Text('Editar'),
      style: TextButton.styleFrom(
        foregroundColor: AppColors.orange,
        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
      ),
    );
  }

  Widget _baja() {
    if (principal || actual) {
      return Tooltip(
        message: principal
            ? 'La cuenta principal no se puede dar de baja.'
            : 'No podés darte de baja a vos mismo.',
        child: const Padding(
          padding: EdgeInsets.all(8),
          child: Icon(Icons.lock_outline, size: 19, color: AppColors.badgeGray),
        ),
      );
    }
    if (compacto) {
      return IconButton(
        tooltip: 'Dar de baja',
        onPressed: habilitado ? onDarDeBaja : null,
        icon: const Icon(Icons.person_remove_outlined, size: 20, color: AppColors.error),
      );
    }
    return TextButton.icon(
      onPressed: habilitado ? onDarDeBaja : null,
      icon: const Icon(Icons.person_remove_outlined, size: 17),
      label: const Text('Dar de baja'),
      style: TextButton.styleFrom(
        foregroundColor: AppColors.error,
        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nombre = Row(
      children: [
        Flexible(
          child: Text(
            cuenta.nombreMostrado,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.steelBlue),
          ),
        ),
        if (principal) ...[
          const SizedBox(width: 8),
          const _Etiqueta(texto: 'Principal', icono: Icons.star_rounded, color: AppColors.orange),
        ],
        if (actual) ...[
          const SizedBox(width: 6),
          const _Etiqueta(texto: 'Vos', icono: Icons.person_outline, color: AppColors.steelBlue),
        ],
      ],
    );
    final correo = Text(
      cuenta.email,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTextStyles.input.copyWith(fontSize: 13.5, color: AppColors.graphiteGray),
    );

    return Container(
      padding: EdgeInsets.symmetric(horizontal: compacto ? 14 : 20, vertical: 12),
      decoration: BoxDecoration(
        color: par ? AppColors.white : AppColors.background.withOpacity(0.5),
        border: Border(bottom: BorderSide(color: AppColors.inputBorder.withOpacity(0.6))),
      ),
      child: Row(
        children: [
          _Avatar(nombre: cuenta.nombreMostrado, principal: principal),
          const SizedBox(width: 14),
          if (compacto)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  nombre,
                  const SizedBox(height: 2),
                  correo,
                  const SizedBox(height: 2),
                  Text('Alta: $_alta', style: AppTextStyles.footer.copyWith(color: AppColors.graphiteGray)),
                ],
              ),
            )
          else ...[
            Expanded(flex: 4, child: nombre),
            Expanded(flex: 4, child: correo),
            Expanded(
              flex: 2,
              child: Text(_alta, style: AppTextStyles.footer.copyWith(color: AppColors.graphiteGray)),
            ),
          ],
          SizedBox(
            width: compacto ? 88 : 220,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [_editar(), _baja()],
            ),
          ),
        ],
      ),
    );
  }
}

class _Etiqueta extends StatelessWidget {
  final String texto;
  final IconData icono;
  final Color color;

  const _Etiqueta({required this.texto, required this.icono, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 12, color: color),
          const SizedBox(width: 3),
          Text(texto, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String nombre;
  final bool principal;

  const _Avatar({required this.nombre, required this.principal});

  String get _iniciales {
    final partes = nombre.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (partes.isEmpty) return '?';
    if (partes.length == 1) return partes.first.substring(0, 1).toUpperCase();
    return (partes.first.substring(0, 1) + partes[1].substring(0, 1)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final color = principal ? AppColors.orange : AppColors.steelBlue;
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        _iniciales,
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color),
      ),
    );
  }
}
