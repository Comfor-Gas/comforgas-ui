import 'package:flutter/material.dart';
import '../../../models/venta_monitoreo.dart';
import '../../../theme/app_colors.dart';

class DetalleCilindrosResumen extends StatelessWidget {
  final List<DetalleVentaMonitoreo> detalles;
  final bool compacto;

  const DetalleCilindrosResumen({
    super.key,
    required this.detalles,
    this.compacto = true,
  });

  @override
  Widget build(BuildContext context) {
    if (detalles.isEmpty) {
      return Text(
        'Sin cilindros',
        style: TextStyle(
          fontSize: compacto ? 12.5 : 13.5,
          color: AppColors.inputHint,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final detalle in detalles)
          Padding(
            padding: EdgeInsets.only(bottom: detalle == detalles.last ? 0 : 6),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _Chip(
                  texto: '${detalle.cantidadEntregada} × ${detalle.etiquetaEnvase} Llenos',
                  color: AppColors.orange,
                  compacto: compacto,
                ),
                if (detalle.usaRecibidos)
                  _Chip(
                    texto: '${detalle.cantidadRecibida} × ${detalle.etiquetaEnvase} Vacíos',
                    color: AppColors.steelBlue,
                    compacto: compacto,
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String texto;
  final Color color;
  final bool compacto;

  const _Chip({required this.texto, required this.color, required this.compacto});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          texto,
          style: TextStyle(
            fontSize: compacto ? 12.5 : 13.5,
            fontWeight: FontWeight.w600,
            color: AppColors.graphiteGray,
          ),
        ),
      ],
    );
  }
}
