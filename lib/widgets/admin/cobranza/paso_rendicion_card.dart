import 'package:flutter/material.dart';
import '../../../models/cuadre_rendicion.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

enum EstadoPasoRendicion { cargando, sinRendicion, pendiente, aprobada, error }

class PasoRendicionCard extends StatelessWidget {
  final CuadreRendicion? cuadre;
  final bool cargando;
  final bool error;
  final VoidCallback? onAbrir;

  const PasoRendicionCard({
    super.key,
    required this.cuadre,
    required this.cargando,
    required this.onAbrir,
    this.error = false,
  });

  EstadoPasoRendicion get _estado {
    final c = cuadre;
    if (cargando && c == null) return EstadoPasoRendicion.cargando;
    if (error && c == null) return EstadoPasoRendicion.error;
    if (c == null || !c.hayRendicion) return EstadoPasoRendicion.sinRendicion;
    if (c.aprobadaORutaCerrada) return EstadoPasoRendicion.aprobada;
    return EstadoPasoRendicion.pendiente;
  }

  @override
  Widget build(BuildContext context) {
    final estado = _estado;
    final (color, icono, titulo, detalle) = switch (estado) {
      EstadoPasoRendicion.cargando => (
          AppColors.graphiteGray,
          Icons.hourglass_top_rounded,
          'Consultando la rendición…',
          'Un momento.',
        ),
      EstadoPasoRendicion.error => (
          AppColors.error,
          Icons.error_outline,
          'No se pudo consultar la rendición',
          'Abrí el cuadre para reintentar.',
        ),
      EstadoPasoRendicion.sinRendicion => (
          AppColors.badgeAmber,
          Icons.hourglass_empty,
          'El chofer todavía no envió la rendición',
          'Cuando la envíe, revisá el cuadre y aprobala para poder cerrar el arqueo.',
        ),
      EstadoPasoRendicion.pendiente => (
          AppColors.orange,
          Icons.fact_check_outlined,
          'Rendición pendiente de aprobación',
          (cuadre?.saldosPendientes.isNotEmpty ?? false)
              ? 'Hay diferencias: ajustalas o aprobá con diferencias indicando el motivo.'
              : 'La rendición cuadra. Revisala y aprobala para habilitar el cierre del arqueo.',
        ),
      EstadoPasoRendicion.aprobada => (
          AppColors.badgeGreen,
          Icons.verified_outlined,
          'Rendición aprobada',
          'Ya podés contar la plata y cerrar el arqueo de caja.',
        ),
    };
    final destacado = estado == EstadoPasoRendicion.pendiente;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: destacado ? AppColors.orange.withOpacity(0.5) : AppColors.inputBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _NumeroPaso(numero: 1, texto: 'CUADRE DE RENDICIÓN'),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icono, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo, style: AppTextStyles.label.copyWith(fontSize: 14.5, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text(detalle, style: AppTextStyles.footer.copyWith(color: AppColors.graphiteGray, fontSize: 12.5)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: destacado
                ? ElevatedButton.icon(
                    onPressed: onAbrir,
                    icon: const Icon(Icons.fact_check_outlined, size: 18),
                    label: const Text('Revisar y aprobar rendición'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.orange,
                      foregroundColor: AppColors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  )
                : OutlinedButton.icon(
                    onPressed: onAbrir,
                    icon: const Icon(Icons.fact_check_outlined, size: 18),
                    label: Text(estado == EstadoPasoRendicion.aprobada ? 'Ver cuadre de rendición' : 'Abrir cuadre de rendición'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.steelBlue,
                      side: const BorderSide(color: AppColors.steelBlue),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class NumeroPasoArqueo extends StatelessWidget {
  const NumeroPasoArqueo({super.key});

  @override
  Widget build(BuildContext context) => const _NumeroPaso(numero: 2, texto: 'ARQUEO DE CAJA');
}

class _NumeroPaso extends StatelessWidget {
  final int numero;
  final String texto;

  const _NumeroPaso({required this.numero, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: const BoxDecoration(color: AppColors.steelBlue, shape: BoxShape.circle),
          child: Text(
            '$numero',
            style: const TextStyle(color: AppColors.white, fontSize: 12, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          texto,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
            color: AppColors.steelBlue,
          ),
        ),
      ],
    );
  }
}
