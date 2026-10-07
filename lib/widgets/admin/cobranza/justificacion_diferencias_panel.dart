import 'package:flutter/material.dart';

import '../../../core/responsive.dart';
import '../../../models/cuadre_rendicion.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../utils/formato.dart';

String formatSaldoConcepto(ConceptoAjuste concepto, int valor) {
  final abs = valor.abs();
  return concepto.esDinero ? formatMoneda(abs) : '$abs ${abs == 1 ? 'garrafa' : 'garrafas'}';
}

class DiferenciaJustificable {
  final String clave;
  final String etiqueta;
  final String detalle;
  final int diferencia;
  final bool esDinero;

  const DiferenciaJustificable({
    required this.clave,
    required this.etiqueta,
    required this.detalle,
    required this.diferencia,
    required this.esDinero,
  });

  bool get falta => diferencia < 0;

  String get valorTexto {
    final abs = diferencia.abs();
    final monto = esDinero ? formatMoneda(abs) : '$abs ${abs == 1 ? 'garrafa' : 'garrafas'}';
    return '${falta ? 'Falta' : 'Sobra'} $monto';
  }
}

List<DiferenciaJustificable> diferenciasJustificables(CuadreRendicion cuadre) {
  final lista = <DiferenciaJustificable>[];

  void dinero(ConceptoAjuste concepto, int sistema, int declarado) {
    final saldo = cuadre.saldos[concepto] ?? (declarado - sistema);
    if (saldo == 0) return;
    lista.add(DiferenciaJustificable(
      clave: concepto.codigo,
      etiqueta: concepto.etiqueta,
      detalle: 'Sistema ${formatMoneda(sistema)} · Declarado ${formatMoneda(declarado)}',
      diferencia: saldo,
      esDinero: true,
    ));
  }

  dinero(ConceptoAjuste.efectivo, cuadre.efectivoSistema, cuadre.efectivoDeclarado);
  dinero(ConceptoAjuste.cheques, cuadre.chequesSistema, cuadre.chequesDeclarado);
  dinero(ConceptoAjuste.transferencias, cuadre.transferenciasSistema, cuadre.transferenciasDeclarado);

  final envasesPorSku = <DiferenciaJustificable>[];
  for (final e in cuadre.envases) {
    void envase(String tipo, int sistema, int declarado) {
      final dif = declarado - sistema;
      if (dif == 0) return;
      envasesPorSku.add(DiferenciaJustificable(
        clave: '${e.sku}|$tipo',
        etiqueta: '${e.etiqueta} · $tipo',
        detalle: 'Sistema $sistema · Declarado $declarado',
        diferencia: dif,
        esDinero: false,
      ));
    }

    envase('Vacías', e.vaciosSistema, e.vaciosDeclarado);
    envase('Llenas', e.llenosSistema, e.llenosDeclarado);
    envase('Dañadas', e.averiadosSistema, e.averiadosDeclarado);
  }

  if (envasesPorSku.isNotEmpty) {
    lista.addAll(envasesPorSku);
  } else {
    for (final c in const [ConceptoAjuste.vacios, ConceptoAjuste.llenos, ConceptoAjuste.danados]) {
      final saldo = cuadre.saldos[c] ?? 0;
      if (saldo == 0) continue;
      lista.add(DiferenciaJustificable(
        clave: c.codigo,
        etiqueta: c.etiqueta,
        detalle: 'Diferencia informada por el sistema',
        diferencia: saldo,
        esDinero: false,
      ));
    }
  }

  if (lista.isEmpty && cuadre.tieneDiferencias) {
    lista.add(const DiferenciaJustificable(
      clave: 'GENERAL',
      etiqueta: 'Diferencias del cuadre',
      detalle: 'El sistema informa saldos pendientes',
      diferencia: 0,
      esDinero: false,
    ));
  }
  return lista;
}

String componerJustificacion(
  List<DiferenciaJustificable> diferencias,
  Map<String, TextEditingController> comentarios,
) {
  return [
    for (final d in diferencias)
      '• ${d.etiqueta}${d.diferencia == 0 ? '' : ' (${d.valorTexto})'}: ${comentarios[d.clave]?.text.trim() ?? ''}',
  ].join('\n');
}

class JustificacionDiferenciasPanel extends StatelessWidget {
  final List<DiferenciaJustificable> diferencias;
  final Map<String, TextEditingController> comentarios;
  final bool habilitado;
  final VoidCallback onCambio;

  const JustificacionDiferenciasPanel({
    super.key,
    required this.diferencias,
    required this.comentarios,
    required this.onCambio,
    this.habilitado = true,
  });

  int get _justificadas =>
      diferencias.where((d) => (comentarios[d.clave]?.text.trim() ?? '').isNotEmpty).length;

  void _copiarADemas(String clave) {
    final texto = comentarios[clave]?.text.trim() ?? '';
    if (texto.isEmpty) return;
    for (final d in diferencias) {
      final c = comentarios[d.clave];
      if (c != null && d.clave != clave && c.text.trim().isEmpty) c.text = texto;
    }
    onCambio();
  }

  @override
  Widget build(BuildContext context) {
    if (diferencias.isEmpty) return const SizedBox.shrink();
    final completas = _justificadas == diferencias.length;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: completas ? AppColors.inputBorder : AppColors.orange.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.rate_review_outlined, size: 16, color: AppColors.steelBlue),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'JUSTIFICACIÓN DE DIFERENCIAS',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: AppColors.steelBlue,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: (completas ? AppColors.badgeGreen : AppColors.orange).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$_justificadas/${diferencias.length}',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: completas ? AppColors.badgeGreen : AppColors.orange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Los montos y cantidades no se modifican. Escribí por qué hay faltante o sobrante en cada caso; '
            'queda registrado al aprobar.',
            style: AppTextStyles.footer.copyWith(color: AppColors.graphiteGray),
          ),
          const SizedBox(height: 10),
          for (final d in diferencias)
            _FilaJustificacion(
              diferencia: d,
              controller: comentarios[d.clave]!,
              habilitado: habilitado,
              onCambio: onCambio,
              onCopiar: diferencias.length > 1 ? () => _copiarADemas(d.clave) : null,
            ),
        ],
      ),
    );
  }
}

class _FilaJustificacion extends StatelessWidget {
  final DiferenciaJustificable diferencia;
  final TextEditingController controller;
  final bool habilitado;
  final VoidCallback onCambio;
  final VoidCallback? onCopiar;

  const _FilaJustificacion({
    required this.diferencia,
    required this.controller,
    required this.habilitado,
    required this.onCambio,
    this.onCopiar,
  });

  @override
  Widget build(BuildContext context) {
    final d = diferencia;
    final color = d.diferencia == 0
        ? AppColors.badgeAmber
        : (d.falta ? AppColors.error : AppColors.badgeGreen);
    final vacio = controller.text.trim().isEmpty;
    final movil = Responsive.isMobileContext(context);
    final textos = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(d.etiqueta, style: AppTextStyles.label.copyWith(fontSize: 13)),
        const SizedBox(height: 2),
        Text(d.detalle, style: AppTextStyles.footer.copyWith(color: AppColors.graphiteGray)),
      ],
    );
    final badge = d.diferencia == 0
        ? null
        : Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              d.valorTexto,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color),
            ),
          );
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (movil) ...[
            textos,
            if (badge != null) ...[
              const SizedBox(height: 8),
              Align(alignment: Alignment.centerLeft, child: badge),
            ],
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: textos),
                if (badge != null) badge,
              ],
            ),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            enabled: habilitado,
            minLines: 1,
            maxLines: 3,
            maxLength: 300,
            onChanged: (_) => onCambio(),
            cursorColor: AppColors.orange,
            style: AppTextStyles.input.copyWith(fontSize: 13.5),
            decoration: InputDecoration(
              hintText: d.falta ? '¿Por qué falta?' : '¿Por qué sobra?',
              isDense: true,
              counterText: '',
              filled: true,
              fillColor: AppColors.white,
              suffixIcon: onCopiar != null && !vacio
                  ? IconButton(
                      tooltip: 'Usar este comentario en las que están vacías',
                      onPressed: habilitado ? onCopiar : null,
                      icon: const Icon(Icons.copy_all_outlined, size: 18, color: AppColors.steelBlue),
                    )
                  : null,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: vacio ? AppColors.orange.withValues(alpha: 0.5) : AppColors.inputBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.orange),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.inputBorder),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
