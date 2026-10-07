import 'package:flutter/material.dart';
import '../../../models/comprobante_visita.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../utils/date_format_utils.dart';
import '../../../utils/formato.dart';

class ComprobanteSeccion extends StatelessWidget {
  final String titulo;
  final IconData icono;
  final Widget child;

  const ComprobanteSeccion({
    super.key,
    required this.titulo,
    required this.icono,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icono, size: 18, color: AppColors.steelBlue),
              const SizedBox(width: 8),
              Text(
                titulo.toUpperCase(),
                style: AppTextStyles.footer.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: AppColors.steelBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class ComprobanteVentaBloque extends StatelessWidget {
  final ComprobanteVenta venta;
  final int numero;
  final bool mostrarEncabezado;

  const ComprobanteVentaBloque({
    super.key,
    required this.venta,
    required this.numero,
    this.mostrarEncabezado = false,
  });

  @override
  Widget build(BuildContext context) {
    final fecha = venta.fecha;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (mostrarEncabezado)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              fecha != null
                  ? 'Venta $numero · ${formatHora12(fecha.toLocal())}'
                  : 'Venta $numero',
              style: AppTextStyles.footer.copyWith(
                color: AppColors.graphiteGray,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        for (final linea in venta.lineas) ComprobanteLineaFila(linea: linea),
      ],
    );
  }
}

class ComprobanteLineaFila extends StatelessWidget {
  final ComprobanteLinea linea;

  const ComprobanteLineaFila({super.key, required this.linea});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.propane_tank_outlined, size: 18, color: AppColors.orange),
              const SizedBox(width: 8),
              Expanded(
                child: Text(linea.descripcion, style: AppTextStyles.label.copyWith(fontSize: 14)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  linea.tipoLabel,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.orange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            linea.usaRecibidos
                ? 'Entregadas: ${linea.cantidadEntregada}  ·  Vacías recibidas: ${linea.cantidadRecibida}'
                : 'Entregadas: ${linea.cantidadEntregada}',
            style: AppTextStyles.footer.copyWith(color: AppColors.graphiteGray),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${formatMoneda(linea.precioUnitario)} × ${linea.cantidadEntregada}',
                  style: AppTextStyles.link.copyWith(fontSize: 12.5),
                ),
              ),
              Text(
                formatMoneda(linea.subtotal),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.steelBlue,
                ),
              ),
            ],
          ),
          if (linea.inconsistente) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.badgeAmber),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Marcada para revisión del administrador',
                    style: AppTextStyles.footer.copyWith(color: AppColors.graphiteGray, fontSize: 11.5),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class ComprobanteDato extends StatelessWidget {
  final String etiqueta;
  final String valor;
  final bool destacado;

  const ComprobanteDato({
    super.key,
    required this.etiqueta,
    required this.valor,
    this.destacado = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              etiqueta,
              style: AppTextStyles.footer.copyWith(
                color: AppColors.graphiteGray,
                fontWeight: destacado ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            valor,
            style: TextStyle(
              fontSize: destacado ? 17 : 13.5,
              fontWeight: FontWeight.w800,
              color: destacado ? AppColors.orange : AppColors.steelBlue,
            ),
          ),
        ],
      ),
    );
  }
}
