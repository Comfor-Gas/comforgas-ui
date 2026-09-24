import 'package:flutter/material.dart';

import '../../../models/cuadre_rodante.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

typedef CargarCuadre = Future<CuadreRodante> Function();

class ReporteCuadreModal extends StatefulWidget {
  final CargarCuadre cargar;

  const ReporteCuadreModal({super.key, required this.cargar});

  static Future<void> mostrar(BuildContext context, {required CargarCuadre cargar}) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (_) => ReporteCuadreModal(cargar: cargar),
    );
  }

  @override
  State<ReporteCuadreModal> createState() => _ReporteCuadreModalState();
}

class _ReporteCuadreModalState extends State<ReporteCuadreModal> {
  bool _loading = true;
  String? _error;
  CuadreRodante? _cuadre;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final cuadre = await widget.cargar();
      if (!mounted) return;
      setState(() {
        _cuadre = cuadre;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo cargar el reporte de cuadre.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 640),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
          child: _contenido(),
        ),
      ),
    );
  }

  Widget _contenido() {
    if (_loading) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator(color: AppColors.orange)),
      );
    }
    final cuadre = _cuadre;
    if (_error != null || cuadre == null) {
      return _errorView(_error ?? 'No se pudo cargar el reporte.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Reporte de cierre',
                style: AppTextStyles.desktopTitle.copyWith(fontSize: 20),
              ),
            ),
            _ChipCuadra(cuadra: cuadre.cuadra),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${cuadre.dominioVehiculo ?? ''} · ${cuadre.nombreChofer ?? ''}'
          '${cuadre.numeroNota != null ? ' · Nota ${cuadre.numeroNota}' : ''}',
          style: AppTextStyles.desktopSubtitle,
        ),
        const SizedBox(height: 16),
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (cuadre.productos.isEmpty)
                  Text('El reporte no tiene productos.', style: AppTextStyles.footer)
                else
                  for (final p in cuadre.productos) _ProductoCard(producto: p),
                if (!cuadre.entradaRegistrada) ...[
                  const SizedBox(height: 8),
                  _Aviso(
                    'La entrada del móvil todavía no fue registrada, así que el conteo físico y las diferencias aún no están disponibles.',
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(foregroundColor: AppColors.steelBlue),
            child: const Text('Cerrar'),
          ),
        ),
      ],
    );
  }

  Widget _errorView(String mensaje) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 40, color: AppColors.error),
          const SizedBox(height: 12),
          Text(mensaje, textAlign: TextAlign.center, style: AppTextStyles.input),
          const SizedBox(height: 18),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}

class _ProductoCard extends StatelessWidget {
  final CuadreProducto producto;

  const _ProductoCard({required this.producto});

  @override
  Widget build(BuildContext context) {
    final p = producto;
    final entrada = p.llenosEntrada != null || p.vaciosEntrada != null || p.averiadosEntrada != null;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.propane_tank_rounded, size: 18, color: AppColors.orange),
              const SizedBox(width: 6),
              Expanded(
                child: Text(p.etiqueta, style: AppTextStyles.label.copyWith(fontSize: 14.5)),
              ),
              _ChipCuadra(cuadra: p.cuadra, compacto: true),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _Stat(etiqueta: 'Cargado', valor: '${p.llenosSalida}', color: AppColors.steelBlue),
              if (p.vaciosSalida > 0) _Stat(etiqueta: 'Vacíos salida', valor: '${p.vaciosSalida}'),
              _Stat(etiqueta: 'Recargas', valor: '${p.recargasLlenos}', color: AppColors.steelBlue),
              _Stat(etiqueta: 'Vendidas', valor: '${p.ventas}', color: AppColors.orange),
              if (p.prestamos > 0) _Stat(etiqueta: 'Préstamos', valor: '${p.prestamos}'),
              if (p.canjes > 0) _Stat(etiqueta: 'Canjes', valor: '${p.canjes}'),
            ],
          ),
          if (entrada) ...[
            const SizedBox(height: 10),
            _LineaTriple(
              titulo: 'Contado (entrada)',
              llenos: p.llenosEntrada ?? 0,
              vacios: p.vaciosEntrada ?? 0,
              averiados: p.averiadosEntrada ?? 0,
            ),
            const SizedBox(height: 10),
            _EnvasesResumen(
              salida: p.envasesSalida ?? 0,
              entrada: p.envasesEntrada ?? 0,
              diferencia: p.diferenciaEnvases ?? 0,
              faltante: p.faltanteNoExplicado ?? 0,
            ),
          ],
        ],
      ),
    );
  }
}

class _EnvasesResumen extends StatelessWidget {
  final int salida;
  final int entrada;
  final int diferencia;
  final int faltante;

  const _EnvasesResumen({
    required this.salida,
    required this.entrada,
    required this.diferencia,
    required this.faltante,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text('Envases (llenos + vacíos + averiados)',
                  style: AppTextStyles.footer.copyWith(color: AppColors.graphiteGray)),
              const Spacer(),
              Text('Salida $salida  →  Entrada $entrada',
                  style: AppTextStyles.label.copyWith(fontSize: 13, color: AppColors.steelBlue)),
            ],
          ),
          if (faltante > 0) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Text('Faltante no explicado',
                    style: AppTextStyles.footer.copyWith(color: AppColors.graphiteGray)),
                const Spacer(),
                Text('$faltante',
                    style: AppTextStyles.label.copyWith(fontSize: 13, color: AppColors.error)),
              ],
            ),
          ] else if (diferencia > 0) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Text('Sobrante',
                    style: AppTextStyles.footer.copyWith(color: AppColors.graphiteGray)),
                const Spacer(),
                Text('+$diferencia',
                    style: AppTextStyles.label.copyWith(fontSize: 13, color: AppColors.badgeAmber)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String etiqueta;
  final String valor;
  final Color? color;

  const _Stat({required this.etiqueta, required this.valor, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(etiqueta, style: AppTextStyles.footer.copyWith(color: AppColors.graphiteGray)),
          const SizedBox(width: 6),
          Text(
            valor,
            style: AppTextStyles.label.copyWith(fontSize: 13.5, color: color ?? AppColors.steelBlue),
          ),
        ],
      ),
    );
  }
}

class _LineaTriple extends StatelessWidget {
  final String titulo;
  final int llenos;
  final int vacios;
  final int averiados;
  final bool resaltarNoCero;

  const _LineaTriple({
    required this.titulo,
    required this.llenos,
    required this.vacios,
    required this.averiados,
    this.resaltarNoCero = false,
  });

  Color _color(int v) {
    if (!resaltarNoCero) return AppColors.steelBlue;
    return v != 0 ? AppColors.error : AppColors.badgeGreen;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(titulo, style: AppTextStyles.footer.copyWith(color: AppColors.graphiteGray)),
        ),
        _mini('Ll', llenos),
        const SizedBox(width: 10),
        _mini('Va', vacios),
        const SizedBox(width: 10),
        _mini('Av', averiados),
      ],
    );
  }

  Widget _mini(String et, int v) {
    return Text(
      '$et $v',
      style: AppTextStyles.label.copyWith(fontSize: 13, color: _color(v)),
    );
  }
}

class _ChipCuadra extends StatelessWidget {
  final bool cuadra;
  final bool compacto;

  const _ChipCuadra({required this.cuadra, this.compacto = false});

  @override
  Widget build(BuildContext context) {
    final color = cuadra ? AppColors.badgeGreen : AppColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        cuadra ? 'Cuadra' : 'No cuadra',
        style: TextStyle(
          fontSize: compacto ? 11.5 : 12.5,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _Aviso extends StatelessWidget {
  final String texto;

  const _Aviso(this.texto);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.badgeAmber.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.badgeAmber.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 17, color: AppColors.badgeAmber),
          const SizedBox(width: 8),
          Expanded(
            child: Text(texto, style: AppTextStyles.footer.copyWith(color: AppColors.graphiteGray)),
          ),
        ],
      ),
    );
  }
}
