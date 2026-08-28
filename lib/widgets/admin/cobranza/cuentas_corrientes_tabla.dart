import 'package:flutter/material.dart';

import '../../../models/cuenta_corriente_resumen.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../utils/formato.dart';
import 'credito_estado_badge.dart';

class CuentasCorrientesTabla extends StatelessWidget {
  final List<CuentaCorrienteResumen> clientes;
  final ValueChanged<CuentaCorrienteResumen> onVerDetalle;
  final String mensajeVacio;

  const CuentasCorrientesTabla({
    super.key,
    required this.clientes,
    required this.onVerDetalle,
    this.mensajeVacio = 'No hay clientes con cuenta corriente.',
  });

  @override
  Widget build(BuildContext context) {
    if (clientes.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 44),
        child: Center(
          child: Text(mensajeVacio, style: AppTextStyles.link, textAlign: TextAlign.center),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 760) {
          return Column(
            children: [
              for (final c in clientes)
                _ClienteCard(cliente: c, onVer: () => onVerDetalle(c)),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _Header(),
            for (final c in clientes)
              _Fila(cliente: c, onVer: () => onVerDetalle(c)),
          ],
        );
      },
    );
  }
}

const _colCliente = 3;
const _colEstado = 2;
const _colLimite = 2;
const _colSaldo = 2;
const _colVencido = 2;
const _colAcciones = 1;

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
          _CeldaHeader(flex: _colCliente, texto: 'CLIENTE'),
          _CeldaHeader(flex: _colEstado, texto: 'ESTADO CRÉDITO'),
          _CeldaHeader(flex: _colLimite, texto: 'LÍMITE'),
          _CeldaHeader(flex: _colSaldo, texto: 'SALDO ACTUAL'),
          _CeldaHeader(flex: _colVencido, texto: 'VENCIDO'),
          _CeldaHeader(flex: _colAcciones, texto: '', alinearFinal: true),
        ],
      ),
    );
  }
}

class _CeldaHeader extends StatelessWidget {
  final int flex;
  final String texto;
  final bool alinearFinal;

  const _CeldaHeader({required this.flex, required this.texto, this.alinearFinal = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        texto,
        textAlign: alinearFinal ? TextAlign.right : TextAlign.left,
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
  final CuentaCorrienteResumen cliente;
  final VoidCallback onVer;

  const _Fila({required this.cliente, required this.onVer});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.inputBorder.withOpacity(0.6))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: _colCliente,
            child: Text(
              cliente.nombreCliente,
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.steelBlue),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: _colEstado,
            child: Align(
              alignment: Alignment.centerLeft,
              child: CreditoEstadoBadge(moroso: cliente.moroso),
            ),
          ),
          _Monto(flex: _colLimite, valor: cliente.limiteCredito),
          _Monto(flex: _colSaldo, valor: cliente.saldoUsado, acento: AppColors.steelBlue, fuerte: true),
          _Monto(
            flex: _colVencido,
            valor: cliente.montoVencido,
            acento: cliente.tieneVencido ? AppColors.error : AppColors.graphiteGray,
            fuerte: cliente.tieneVencido,
            guionSiCero: true,
          ),
          Expanded(
            flex: _colAcciones,
            child: Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                onPressed: onVer,
                tooltip: 'Ver detalle',
                icon: const Icon(Icons.chevron_right, color: AppColors.steelBlue),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Monto extends StatelessWidget {
  final int flex;
  final int valor;
  final Color? acento;
  final bool fuerte;
  final bool guionSiCero;

  const _Monto({
    required this.flex,
    required this.valor,
    this.acento,
    this.fuerte = false,
    this.guionSiCero = false,
  });

  @override
  Widget build(BuildContext context) {
    final texto = (guionSiCero && valor == 0) ? '—' : formatMoneda(valor);
    return Expanded(
      flex: flex,
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 13,
          fontWeight: fuerte ? FontWeight.w800 : FontWeight.w600,
          color: acento ?? AppColors.graphiteGray,
        ),
      ),
    );
  }
}

class _ClienteCard extends StatelessWidget {
  final CuentaCorrienteResumen cliente;
  final VoidCallback onVer;

  const _ClienteCard({required this.cliente, required this.onVer});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onVer,
      child: Container(
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
                  child: Text(cliente.nombreCliente, style: AppTextStyles.label.copyWith(fontSize: 14.5)),
                ),
                CreditoEstadoBadge(moroso: cliente.moroso),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _MiniDato(etiqueta: 'Límite', valor: formatMoneda(cliente.limiteCredito))),
                Expanded(child: _MiniDato(etiqueta: 'Saldo', valor: formatMoneda(cliente.saldoUsado))),
                Expanded(
                  child: _MiniDato(
                    etiqueta: 'Vencido',
                    valor: cliente.tieneVencido ? formatMoneda(cliente.montoVencido) : '—',
                    acento: cliente.tieneVencido ? AppColors.error : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniDato extends StatelessWidget {
  final String etiqueta;
  final String valor;
  final Color? acento;

  const _MiniDato({required this.etiqueta, required this.valor, this.acento});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(etiqueta, style: const TextStyle(fontSize: 10.5, color: AppColors.graphiteGray)),
        const SizedBox(height: 2),
        Text(
          valor,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: acento ?? AppColors.steelBlue,
          ),
        ),
      ],
    );
  }
}
