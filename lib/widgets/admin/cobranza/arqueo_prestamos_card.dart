import 'package:flutter/material.dart';

import '../../../models/arqueo_caja.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../utils/formato.dart';

class ArqueoPrestamosCard extends StatelessWidget {
  final List<ArqueoNotaDebito> notas;
  final int garrafasAdeudadas;
  final int pendientes;
  final int totalCobrado;

  const ArqueoPrestamosCard({
    super.key,
    required this.notas,
    required this.garrafasAdeudadas,
    required this.pendientes,
    this.totalCobrado = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long_outlined, size: 20, color: AppColors.steelBlue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Préstamos — Notas de Débito',
                  style: AppTextStyles.label.copyWith(fontSize: 15),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.steelBlue.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${notas.length}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.steelBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _Metrica(
                etiqueta: 'Garrafas adeudadas',
                valor: '$garrafasAdeudadas',
                acento: AppColors.orange,
              ),
              _Metrica(
                etiqueta: 'Pendientes',
                valor: '$pendientes',
                acento: AppColors.badgeAmber,
              ),
              if (totalCobrado > 0)
                _Metrica(
                  etiqueta: 'Cobrado en préstamos',
                  valor: formatMoneda(totalCobrado),
                  acento: AppColors.steelBlue,
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (notas.isEmpty)
            _VacioPrestamos()
          else ...[
            const _EncabezadoNotas(),
            const Divider(height: 16, color: AppColors.inputBorder),
            for (int i = 0; i < notas.length; i++) ...[
              _FilaNota(nota: notas[i]),
              if (i < notas.length - 1)
                const Divider(height: 16, color: AppColors.inputBorder),
            ],
          ],
        ],
      ),
    );
  }
}

class _Metrica extends StatelessWidget {
  final String etiqueta;
  final String valor;
  final Color acento;

  const _Metrica({
    required this.etiqueta,
    required this.valor,
    required this.acento,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: acento.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: acento.withOpacity(0.30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            etiqueta,
            style: AppTextStyles.footer.copyWith(color: AppColors.graphiteGray),
          ),
          const SizedBox(height: 2),
          Text(
            valor,
            style: AppTextStyles.title.copyWith(fontSize: 18, color: acento),
          ),
        ],
      ),
    );
  }
}

class _EncabezadoNotas extends StatelessWidget {
  const _EncabezadoNotas();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(flex: 3, child: _CeldaHeader(texto: 'PRODUCTO')),
        Expanded(flex: 3, child: _CeldaHeader(texto: 'CLIENTE')),
        Expanded(flex: 2, child: _CeldaHeader(texto: 'ADEUDA')),
        Expanded(flex: 3, child: _CeldaHeader(texto: 'ESTADO', alinearFinal: true)),
      ],
    );
  }
}

class _CeldaHeader extends StatelessWidget {
  final String texto;
  final bool alinearFinal;

  const _CeldaHeader({required this.texto, this.alinearFinal = false});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alinearFinal ? Alignment.centerRight : Alignment.centerLeft,
      child: Text(
        texto,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: AppColors.graphiteGray,
        ),
      ),
    );
  }
}

class _FilaNota extends StatelessWidget {
  final ArqueoNotaDebito nota;

  const _FilaNota({required this.nota});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 3,
          child: Text(
            nota.idProducto.isNotEmpty ? nota.idProducto : 'Producto',
            style: AppTextStyles.input.copyWith(fontSize: 13),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            nota.idClienteExt != null ? 'Cliente #${nota.idClienteExt}' : 'Sin cliente',
            style: AppTextStyles.link.copyWith(fontSize: 12.5),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            '${nota.cantidadAdeudada}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.orange,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Align(
            alignment: Alignment.centerRight,
            child: _EstadoChip(estado: nota.estado),
          ),
        ),
      ],
    );
  }
}

class _EstadoChip extends StatelessWidget {
  final String estado;

  const _EstadoChip({required this.estado});

  @override
  Widget build(BuildContext context) {
    final normalizado = estado.toUpperCase();
    late final Color color;
    late final String texto;
    switch (normalizado) {
      case 'SALDADA':
        color = AppColors.badgeGreen;
        texto = 'Saldada';
        break;
      case 'ANULADA':
        color = AppColors.badgeGray;
        texto = 'Anulada';
        break;
      case 'PENDIENTE':
        color = AppColors.badgeAmber;
        texto = 'Pendiente';
        break;
      default:
        color = AppColors.badgeGray;
        texto = estado.isEmpty ? 'Sin estado' : estado;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        texto,
        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: color),
      ),
    );
  }
}

class _VacioPrestamos extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, size: 18, color: AppColors.badgeGreen),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'No se registraron préstamos (notas de débito) en esta jornada.',
              style: AppTextStyles.link.copyWith(fontSize: 12.5, color: AppColors.graphiteGray),
            ),
          ),
        ],
      ),
    );
  }
}
