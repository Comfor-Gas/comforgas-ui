import 'package:flutter/material.dart';
import '../../../models/cobro_draft.dart';
import '../../../models/metodo_pago.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../utils/date_format_utils.dart';
import '../../../utils/formato.dart';

class ComprobanteCobro extends StatelessWidget {
  final CobroDraft cobro;
  final String nombreCliente;
  final String uuidOffline;
  final bool pendienteSync;

  const ComprobanteCobro({
    super.key,
    required this.cobro,
    required this.nombreCliente,
    required this.uuidOffline,
    required this.pendienteSync,
  });

  static Future<void> mostrar(
    BuildContext context, {
    required CobroDraft cobro,
    required String nombreCliente,
    required String uuidOffline,
    required bool pendienteSync,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ComprobanteCobro(
        cobro: cobro,
        nombreCliente: nombreCliente,
        uuidOffline: uuidOffline,
        pendienteSync: pendienteSync,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 14, 20, 24 + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.inputBorder,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const Icon(Icons.receipt_long, color: AppColors.orange, size: 24),
              const SizedBox(width: 10),
              Text('Comprobante de Cobro', style: AppTextStyles.title.copyWith(fontSize: 18)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            pendienteSync ? 'Provisorio · pendiente de sincronizar' : 'Registrado',
            style: AppTextStyles.link.copyWith(fontSize: 12.5),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.inputBorder),
            ),
            child: Column(
              children: [
                _Linea(etiqueta: 'Cliente', valor: nombreCliente),
                _Linea(
                  etiqueta: 'Venta',
                  valor: cobro.idVenta != null
                      ? '#${cobro.idVenta}'
                      : 'Offline (pendiente de sync)',
                ),
                _Linea(etiqueta: 'Método', valor: cobro.metodo.etiqueta),
                _Linea(etiqueta: 'Fecha', valor: fechaHoraTexto(cobro.timestampCobro)),
                const Divider(height: 22, color: AppColors.inputBorder),
                Row(
                  children: [
                    Expanded(
                      child: Text('Total cobrado', style: AppTextStyles.label.copyWith(fontSize: 14)),
                    ),
                    Text(
                      formatMoneda(cobro.monto),
                      style: AppTextStyles.title.copyWith(fontSize: 22, color: AppColors.orange),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.tag, size: 14, color: AppColors.graphiteGray),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'UUID: $uuidOffline',
                  style: const TextStyle(fontSize: 11, color: AppColors.graphiteGray),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.check, size: 20),
              label: const Text('Cerrar'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.steelBlue,
                side: const BorderSide(color: AppColors.steelBlue),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String fechaHoraTexto(DateTime fecha) => '${formatFechaCorta(fecha)} · ${formatHora12(fecha)}';

class _Linea extends StatelessWidget {
  final String etiqueta;
  final String valor;

  const _Linea({required this.etiqueta, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(etiqueta, style: AppTextStyles.link.copyWith(fontSize: 13)),
          ),
          Text(
            valor,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.steelBlue),
          ),
        ],
      ),
    );
  }
}
