import 'package:flutter/material.dart';
import '../../../models/metas_dia_chofer.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../utils/formato.dart';
import 'anillo_progreso.dart';
import 'barra_progreso_metrica.dart';

class MetricasDiaCard extends StatelessWidget {
  final MetasDiaChofer metas;

  const MetricasDiaCard({super.key, required this.metas});

  static const Color _azul = Color(0xFF3A7BD5);

  String _pct(double v) {
    final t = v.toStringAsFixed(v >= 10 || v == 0 ? 0 : 1).replaceAll('.', ',');
    return '$t %';
  }

  @override
  Widget build(BuildContext context) {
    final m = metas;
    final ventaCumplida = m.efectividadVenta >= m.metaEfectividadVenta && m.visitasCerradas > 0;
    final recuperoCumplido = m.efectividadRecupero >= m.metaEfectividadRecupero && m.envasesEntregados > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Tarjeta(
          child: Row(
            children: [
              AnilloProgreso(
                progreso: m.progresoVisitas,
                color: AppColors.orange,
                diametro: 128,
                centro: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '${m.visitasCerradas}',
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              color: AppColors.steelBlue,
                            ),
                          ),
                          TextSpan(
                            text: '/${m.visitasProgramadas}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.graphiteGray,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Text(
                      'visitas',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.graphiteGray),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _TituloMetrica(icono: Icons.route_outlined, texto: 'Visitas realizadas'),
                    const SizedBox(height: 10),
                    _Dato(color: AppColors.orange, etiqueta: 'Con operación', valor: '${m.visitasCompletadas}'),
                    _Dato(color: AppColors.graphiteGray, etiqueta: 'Sin operar', valor: '${m.visitasNoAsistio}'),
                    _Dato(color: AppColors.inputBorder, etiqueta: 'Pendientes', valor: '${m.visitasPendientes}'),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _Tarjeta(
                child: Column(
                  children: [
                    const _TituloMetrica(icono: Icons.trending_up, texto: 'Efectividad de venta'),
                    const SizedBox(height: 14),
                    AnilloProgreso(
                      progreso: m.efectividadVenta / 100,
                      color: _azul,
                      diametro: 104,
                      grosor: 10,
                      centro: Text(
                        _pct(m.efectividadVenta),
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.steelBlue),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _EstadoMeta(
                      cumplida: ventaCumplida,
                      texto: 'Meta ${_pct(m.metaEfectividadVenta)}',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _Tarjeta(
                child: Column(
                  children: [
                    const _TituloMetrica(icono: Icons.payments_outlined, texto: 'Vendido hoy'),
                    const SizedBox(height: 18),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        formatMoneda(m.montoTotalVentas),
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.orange),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${m.envasesEntregados} garrafas entregadas',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.footer.copyWith(color: AppColors.graphiteGray),
                    ),
                    if (m.envasesPrestamo > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${m.envasesPrestamo} en préstamo',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.footer.copyWith(color: AppColors.graphiteGray),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _Tarjeta(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: _TituloMetrica(icono: Icons.propane_tank_outlined, texto: 'Garrafas vacías recuperadas'),
                  ),
                  Text(
                    _pct(m.efectividadRecupero),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.steelBlue),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              BarraProgresoMetrica(
                progreso: m.efectividadRecupero / 100,
                meta: m.metaEfectividadRecupero / 100,
                color: _azul,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${m.envasesRecuperados} de ${m.envasesEntregados} garrafas',
                      style: AppTextStyles.footer.copyWith(color: AppColors.graphiteGray, fontSize: 12.5),
                    ),
                  ),
                  _EstadoMeta(
                    cumplida: recuperoCumplido,
                    texto: 'Meta ${_pct(m.metaEfectividadRecupero)}',
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Tarjeta extends StatelessWidget {
  final Widget child;

  const _Tarjeta({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: child,
    );
  }
}

class _TituloMetrica extends StatelessWidget {
  final IconData icono;
  final String texto;

  const _TituloMetrica({required this.icono, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icono, size: 16, color: AppColors.orange),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            texto,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.label.copyWith(fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _Dato extends StatelessWidget {
  final Color color;
  final String etiqueta;
  final String valor;

  const _Dato({required this.color, required this.etiqueta, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              etiqueta,
              style: AppTextStyles.footer.copyWith(color: AppColors.graphiteGray, fontSize: 12.5),
            ),
          ),
          Text(
            valor,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.steelBlue),
          ),
        ],
      ),
    );
  }
}

class _EstadoMeta extends StatelessWidget {
  final bool cumplida;
  final String texto;

  const _EstadoMeta({required this.cumplida, required this.texto});

  @override
  Widget build(BuildContext context) {
    final color = cumplida ? AppColors.badgeGreen : AppColors.graphiteGray;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(cumplida ? Icons.check_circle : Icons.flag_outlined, size: 13, color: color),
          const SizedBox(width: 4),
          Text(texto, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}
