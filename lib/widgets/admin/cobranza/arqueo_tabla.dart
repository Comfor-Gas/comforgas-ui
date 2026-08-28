import 'package:flutter/material.dart';

import '../../../models/arqueo_caja.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../utils/formato.dart';
import 'sync_estado_badge.dart';

String etiquetaMetodo(String codigo) {
  switch (codigo.toUpperCase()) {
    case 'EFECTIVO':
      return 'Efectivo';
    case 'CHEQUE':
      return 'Cheque';
    case 'TRANSFERENCIA':
      return 'Transferencia';
    case 'CUENTA_CORRIENTE':
      return 'Cta Cte';
    default:
      return codigo;
  }
}

String horaHms(DateTime? fecha) {
  if (fecha == null) return '—';
  final h = fecha.hour.toString().padLeft(2, '0');
  final m = fecha.minute.toString().padLeft(2, '0');
  final s = fecha.second.toString().padLeft(2, '0');
  return '$h:$m:$s';
}

class ArqueoTabla extends StatelessWidget {
  final List<ArqueoMovimiento> movimientos;
  final String mensajeVacio;

  const ArqueoTabla({
    super.key,
    required this.movimientos,
    this.mensajeVacio = 'No hay cobros registrados en esta jornada.',
  });

  @override
  Widget build(BuildContext context) {
    if (movimientos.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 44),
        child: Center(
          child: Text(mensajeVacio, style: AppTextStyles.link, textAlign: TextAlign.center),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 820) {
          return Column(
            children: [for (final m in movimientos) _MovimientoCard(mov: m)],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _Header(),
            for (final m in movimientos) _Fila(mov: m),
          ],
        );
      },
    );
  }
}

const _colVenta = 2;
const _colCliente = 3;
const _colMetodo = 2;
const _colMonto = 2;
const _colFisico = 2;
const _colSincro = 2;
const _colEstado = 2;

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.inputBorder)),
      ),
      child: Row(
        children: const [
          _CeldaHeader(flex: _colVenta, texto: 'ID VENTA'),
          _CeldaHeader(flex: _colCliente, texto: 'CLIENTE'),
          _CeldaHeader(flex: _colMetodo, texto: 'MÉTODO'),
          _CeldaHeader(flex: _colMonto, texto: 'MONTO'),
          _CeldaHeader(flex: _colFisico, texto: 'HORA COBRO (FÍSICO)'),
          _CeldaHeader(flex: _colSincro, texto: 'HORA SINCRO (SERVIDOR)'),
          _CeldaHeader(flex: _colEstado, texto: 'ESTADO'),
        ],
      ),
    );
  }
}

class _CeldaHeader extends StatelessWidget {
  final int flex;
  final String texto;

  const _CeldaHeader({required this.flex, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        texto,
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
          color: AppColors.graphiteGray,
        ),
      ),
    );
  }
}

class _Fila extends StatelessWidget {
  final ArqueoMovimiento mov;

  const _Fila({required this.mov});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.inputBorder.withOpacity(0.6))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _Celda(flex: _colVenta, texto: mov.idVenta != null ? '#${mov.idVenta}' : '—', fuerte: true),
          _Celda(flex: _colCliente, texto: mov.nombreCliente),
          _Celda(flex: _colMetodo, texto: etiquetaMetodo(mov.metodoPago)),
          _Celda(flex: _colMonto, texto: formatMoneda(mov.monto), fuerte: true),
          _Celda(flex: _colFisico, texto: horaHms(mov.horaFisica)),
          _Celda(
            flex: _colSincro,
            texto: horaHms(mov.horaSincro),
            sub: mov.esDiferido ? 'diferido' : 'inmediato',
          ),
          Expanded(
            flex: _colEstado,
            child: Align(
              alignment: Alignment.centerLeft,
              child: SyncEstadoBadge(diferido: mov.esDiferido),
            ),
          ),
        ],
      ),
    );
  }
}

class _Celda extends StatelessWidget {
  final int flex;
  final String texto;
  final String? sub;
  final bool fuerte;

  const _Celda({required this.flex, required this.texto, this.sub, this.fuerte = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            texto,
            style: TextStyle(
              fontSize: 13,
              fontWeight: fuerte ? FontWeight.w800 : FontWeight.w500,
              color: AppColors.steelBlue,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (sub != null) ...[
            const SizedBox(height: 2),
            Text(
              sub!,
              style: const TextStyle(fontSize: 10.5, color: AppColors.graphiteGray),
            ),
          ],
        ],
      ),
    );
  }
}

class _MovimientoCard extends StatelessWidget {
  final ArqueoMovimiento mov;

  const _MovimientoCard({required this.mov});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  mov.nombreCliente,
                  style: AppTextStyles.label.copyWith(fontSize: 14.5),
                ),
              ),
              Text(
                formatMoneda(mov.monto),
                style: AppTextStyles.title.copyWith(fontSize: 16, color: AppColors.orange),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Venta ${mov.idVenta != null ? '#${mov.idVenta}' : '—'} · ${etiquetaMetodo(mov.metodoPago)}',
            style: AppTextStyles.link.copyWith(fontSize: 12.5),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _MiniDato(etiqueta: 'Físico', valor: horaHms(mov.horaFisica))),
              Expanded(child: _MiniDato(etiqueta: 'Sincro', valor: horaHms(mov.horaSincro))),
              SyncEstadoBadge(diferido: mov.esDiferido),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniDato extends StatelessWidget {
  final String etiqueta;
  final String valor;

  const _MiniDato({required this.etiqueta, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(etiqueta, style: const TextStyle(fontSize: 10.5, color: AppColors.graphiteGray)),
        const SizedBox(height: 2),
        Text(
          valor,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.steelBlue),
        ),
      ],
    );
  }
}
