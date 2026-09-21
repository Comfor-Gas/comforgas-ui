import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../models/venta_social.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../widgets/chofer/comodato/contador_envases.dart';
import '../../../widgets/primary_button.dart';

typedef GuardarReanudarSocial = Future<bool> Function(ReanudarSocialDraft draft);

class FinalizarVentaSocialScreen extends StatefulWidget {
  final PausaSocialDraft pausa;
  final String nombreCliente;
  final GuardarReanudarSocial onConfirmar;

  const FinalizarVentaSocialScreen({
    super.key,
    required this.pausa,
    required this.nombreCliente,
    required this.onConfirmar,
  });

  @override
  State<FinalizarVentaSocialScreen> createState() => _FinalizarVentaSocialScreenState();
}

class _FinalizarVentaSocialScreenState extends State<FinalizarVentaSocialScreen> {
  static const _uuid = Uuid();

  final Map<String, int> _llenos = {};
  final Map<String, int> _vacios = {};
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    for (final it in widget.pausa.items) {
      _llenos[it.idProducto] = 0;
      _vacios[it.idProducto] = 0;
    }
  }

  int _devueltos(EnvaseSocialEntregado it) =>
      (_llenos[it.idProducto] ?? 0) + (_vacios[it.idProducto] ?? 0);

  bool _cuadraItem(EnvaseSocialEntregado it) =>
      _devueltos(it) == it.cantidadEntregada;

  bool get _cuadraTodo => widget.pausa.items.every(_cuadraItem);

  int get _totalVendidas => widget.pausa.items.fold(
      0, (a, it) => a + (it.cantidadEntregada - (_llenos[it.idProducto] ?? 0)));

  bool get _valido => !_guardando;

  Future<void> _confirmar() async {
    if (!_valido) return;
    setState(() => _guardando = true);
    final items = widget.pausa.items
        .map((it) => RetornoSocialItem(
              entregado: it,
              llenosRetornados: _llenos[it.idProducto] ?? 0,
              vaciosRecuperados: _vacios[it.idProducto] ?? 0,
            ))
        .toList();
    final draft = ReanudarSocialDraft(
      items: items,
      uuidOffline: _uuid.v4(),
      timestamp: DateTime.now(),
    );
    final ok = await widget.onConfirmar(draft);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.steelBlue,
        foregroundColor: AppColors.white,
        elevation: 0,
        title: const Text('Finalizar Venta Social'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Encabezado(
                      nombreCliente: widget.nombreCliente,
                      totalEntregado: widget.pausa.totalEntregado,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'CONTEO DE ENVASES DEVUELTOS',
                      style: AppTextStyles.footer.copyWith(
                        letterSpacing: 0.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.graphiteGray,
                      ),
                    ),
                    const SizedBox(height: 10),
                    for (final it in widget.pausa.items) _filaItem(it),
                    const SizedBox(height: 6),
                    _AvisoCuadre(cuadra: _cuadraTodo),
                  ],
                ),
              ),
            ),
            _BarraVendidas(vendidas: _totalVendidas, habilitado: _cuadraTodo),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: PrimaryButton(
                text: 'Confirmar y liquidar venta',
                isLoading: _guardando,
                onPressed: _valido ? _confirmar : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filaItem(EnvaseSocialEntregado it) {
    final cuadra = _cuadraItem(it);
    final vendidas = it.cantidadEntregada - (_llenos[it.idProducto] ?? 0);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: cuadra ? AppColors.badgeGreen.withOpacity(0.5) : AppColors.inputBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.propane_tank_rounded, size: 18, color: AppColors.orange),
              const SizedBox(width: 8),
              Expanded(
                child: Text(it.etiqueta, style: AppTextStyles.label.copyWith(fontSize: 14)),
              ),
              Text(
                'Entregadas: ${it.cantidadEntregada}',
                style: AppTextStyles.footer.copyWith(color: AppColors.graphiteGray),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _campo(
            etiqueta: 'Llenos devueltos',
            valor: _llenos[it.idProducto] ?? 0,
            max: it.cantidadEntregada - (_vacios[it.idProducto] ?? 0),
            onChanged: (v) => setState(() => _llenos[it.idProducto] = v),
          ),
          const SizedBox(height: 10),
          _campo(
            etiqueta: 'Vacíos recuperados',
            valor: _vacios[it.idProducto] ?? 0,
            max: it.cantidadEntregada - (_llenos[it.idProducto] ?? 0),
            onChanged: (v) => setState(() => _vacios[it.idProducto] = v),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                cuadra ? Icons.check_circle : Icons.error_outline,
                size: 16,
                color: cuadra ? AppColors.badgeGreen : AppColors.badgeAmber,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  cuadra
                      ? 'Cuadra · Vendidas: $vendidas'
                      : 'Faltan ${it.cantidadEntregada - _devueltos(it)} para cuadrar (${_devueltos(it)}/${it.cantidadEntregada})',
                  style: AppTextStyles.footer.copyWith(
                    color: cuadra ? AppColors.badgeGreen : AppColors.badgeAmber,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _campo({
    required String etiqueta,
    required int valor,
    required int max,
    required ValueChanged<int> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(etiqueta, style: AppTextStyles.input.copyWith(fontSize: 13.5)),
        ),
        ContadorEnvases(
          value: valor,
          enabled: !_guardando,
          min: 0,
          max: max < 0 ? 0 : max,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _Encabezado extends StatelessWidget {
  final String nombreCliente;
  final int totalEntregado;

  const _Encabezado({required this.nombreCliente, required this.totalEntregado});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.steelBlue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.volunteer_activism_outlined, size: 20, color: AppColors.steelBlue),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nombreCliente, style: AppTextStyles.label.copyWith(fontSize: 14.5)),
                const SizedBox(height: 2),
                Text(
                  'Se dejaron $totalEntregado garrafas. Contá los llenos devueltos y los vacíos recuperados. Deben cuadrar con lo entregado.',
                  style: AppTextStyles.footer.copyWith(color: AppColors.graphiteGray),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AvisoCuadre extends StatelessWidget {
  final bool cuadra;

  const _AvisoCuadre({required this.cuadra});

  @override
  Widget build(BuildContext context) {
    final color = cuadra ? AppColors.badgeGreen : AppColors.badgeAmber;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(cuadra ? Icons.check_circle_outline : Icons.info_outline, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              cuadra
                  ? 'El cuadre coincide. Podés confirmar y liquidar la venta.'
                  : 'El cuadre no coincide (los devueltos no igualan lo entregado). Podés liquidar igual: queda marcada como inconsistente para revisión del administrador.',
              style: AppTextStyles.footer.copyWith(color: AppColors.graphiteGray),
            ),
          ),
        ],
      ),
    );
  }
}

class _BarraVendidas extends StatelessWidget {
  final int vendidas;
  final bool habilitado;

  const _BarraVendidas({required this.vendidas, required this.habilitado});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppColors.white,
      child: Row(
        children: [
          Expanded(
            child: Text('Garrafas vendidas', style: AppTextStyles.label.copyWith(fontSize: 15)),
          ),
          Text(
            '$vendidas',
            style: AppTextStyles.title.copyWith(
              fontSize: 18,
              color: habilitado ? AppColors.orange : AppColors.badgeGray,
            ),
          ),
        ],
      ),
    );
  }
}
