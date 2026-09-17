import 'package:flutter/material.dart';

import '../../../models/deposito_camion.dart';
import '../../../repositories/stock_rodante_admin_repository.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import 'camion_stock_bar.dart';

typedef CargarDetalleDia = Future<List<DetalleNotaDiaria>> Function(String idUsuario);

class FlotaTabla extends StatelessWidget {
  final List<DepositoCamion> camiones;
  final int? idSeleccionado;
  final ValueChanged<DepositoCamion> onNota;
  final ValueChanged<DepositoCamion> onRecargaRuta;
  final ValueChanged<DepositoCamion> onEntradaMovil;
  final ValueChanged<DepositoCamion> onVerHistorial;
  final ValueChanged<DepositoCamion> onVerReporte;
  final CargarDetalleDia cargarDetalle;
  final Map<String, int> asignadoPorChofer;
  final Map<String, NotaRodanteResumen> notaPorChofer;
  final String mensajeVacio;

  const FlotaTabla({
    super.key,
    required this.camiones,
    required this.onNota,
    required this.onRecargaRuta,
    required this.onEntradaMovil,
    required this.onVerHistorial,
    required this.onVerReporte,
    required this.cargarDetalle,
    this.asignadoPorChofer = const {},
    this.notaPorChofer = const {},
    this.idSeleccionado,
    this.mensajeVacio = 'No hay camiones para mostrar.',
  });

  int _asignadoDe(DepositoCamion camion) {
    final id = camion.repartidor?.id;
    if (id == null || id.isEmpty) return 0;
    return asignadoPorChofer[id] ?? 0;
  }

  NotaRodanteResumen? _notaDe(DepositoCamion camion) {
    final id = camion.repartidor?.id;
    if (id == null || id.isEmpty) return null;
    return notaPorChofer[id];
  }

  @override
  Widget build(BuildContext context) {
    if (camiones.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 50),
        child: Center(
          child: Text(mensajeVacio, style: AppTextStyles.link, textAlign: TextAlign.center),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 860) {
          return Column(
            children: [
              for (final camion in camiones)
                _CamionCard(
                  camion: camion,
                  seleccionado: camion.id == idSeleccionado,
                  asignado: _asignadoDe(camion),
                  nota: _notaDe(camion),
                  cargarDetalle: cargarDetalle,
                  onNota: () => onNota(camion),
                  onRecargaRuta: () => onRecargaRuta(camion),
                  onEntradaMovil: () => onEntradaMovil(camion),
                  onVerHistorial: () => onVerHistorial(camion),
                  onVerReporte: () => onVerReporte(camion),
                ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _EncabezadoTabla(),
            for (final camion in camiones)
              _FilaCamion(
                camion: camion,
                seleccionado: camion.id == idSeleccionado,
                asignado: _asignadoDe(camion),
                nota: _notaDe(camion),
                cargarDetalle: cargarDetalle,
                onNota: () => onNota(camion),
                onRecargaRuta: () => onRecargaRuta(camion),
                onEntradaMovil: () => onEntradaMovil(camion),
                onVerHistorial: () => onVerHistorial(camion),
                onVerReporte: () => onVerReporte(camion),
              ),
          ],
        );
      },
    );
  }
}

const _colPatente = 2;
const _colChofer = 2;
const _colStock = 3;
const _colVacias = 1;
const _colEstado = 2;
const _colAcciones = 4;

class _EncabezadoTabla extends StatelessWidget {
  const _EncabezadoTabla();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.inputBorder)),
      ),
      child: Row(
        children: const [
          _CeldaHeader(flex: _colPatente, texto: 'CAMIÓN / PATENTE'),
          _CeldaHeader(flex: _colChofer, texto: 'CHOFER ASIGNADO'),
          _CeldaHeader(flex: _colStock, texto: 'LLENOS ASIGNADOS'),
          _CeldaHeader(flex: _colVacias, texto: 'VACÍAS'),
          _CeldaHeader(flex: _colEstado, texto: 'ESTADO'),
          _CeldaHeader(flex: _colAcciones, texto: 'ACCIONES', alinearFinal: true),
        ],
      ),
    );
  }
}

class _CeldaHeader extends StatelessWidget {
  final int flex;
  final String texto;
  final bool alinearFinal;

  const _CeldaHeader({
    required this.flex,
    required this.texto,
    this.alinearFinal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        texto,
        textAlign: alinearFinal ? TextAlign.right : TextAlign.left,
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

class _FilaCamion extends StatelessWidget {
  final DepositoCamion camion;
  final bool seleccionado;
  final int asignado;
  final NotaRodanteResumen? nota;
  final CargarDetalleDia cargarDetalle;
  final VoidCallback onNota;
  final VoidCallback onRecargaRuta;
  final VoidCallback onEntradaMovil;
  final VoidCallback onVerHistorial;
  final VoidCallback onVerReporte;

  const _FilaCamion({
    required this.camion,
    required this.seleccionado,
    required this.asignado,
    required this.nota,
    required this.cargarDetalle,
    required this.onNota,
    required this.onRecargaRuta,
    required this.onEntradaMovil,
    required this.onVerHistorial,
    required this.onVerReporte,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: seleccionado ? AppColors.orange.withOpacity(0.06) : Colors.transparent,
        border: Border(bottom: BorderSide(color: AppColors.inputBorder.withOpacity(0.6))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
          Expanded(
            flex: _colPatente,
            child: _EnlaceTexto(
              texto: camion.patenteVisible,
              subtitulo: camion.numeroMovil != null ? 'Móvil ${camion.numeroMovil}' : null,
              onTap: onVerHistorial,
            ),
          ),
          Expanded(
            flex: _colChofer,
            child: _EnlaceTexto(
              texto: camion.choferNombre,
              atenuado: !camion.tieneChofer,
              onTap: onVerHistorial,
            ),
          ),
          Expanded(
            flex: _colStock,
            child: Padding(
              padding: const EdgeInsets.only(right: 14),
              child: CamionStockBar(
                llenos: asignado,
                vacios: camion.vacios,
                compacto: true,
                mostrarVacios: false,
              ),
            ),
          ),
          Expanded(
            flex: _colVacias,
            child: Text(
              '${camion.vaciasDelDia}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.steelBlue,
              ),
            ),
          ),
          Expanded(
            flex: _colEstado,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _NotaEstadoChip(nota: nota),
            ),
          ),
          Expanded(
            flex: _colAcciones,
            child: _AccionesFila(
              cerrada: nota?.cerrada ?? false,
              tieneNota: nota != null,
              onNota: onNota,
              onRecargaRuta: onRecargaRuta,
              onEntradaMovil: onEntradaMovil,
              onVerHistorial: onVerHistorial,
              onVerReporte: onVerReporte,
            ),
          ),
            ],
          ),
          _DetalleStockCamion(idUsuario: camion.repartidor?.id ?? '', cargar: cargarDetalle),
        ],
      ),
    );
  }
}

class _EnlaceTexto extends StatelessWidget {
  final String texto;
  final String? subtitulo;
  final bool atenuado;
  final VoidCallback onTap;

  const _EnlaceTexto({
    required this.texto,
    required this.onTap,
    this.subtitulo,
    this.atenuado = false,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              texto,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: atenuado ? AppColors.graphiteGray : AppColors.steelBlue,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (subtitulo != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitulo!,
                style: const TextStyle(fontSize: 11.5, color: AppColors.graphiteGray),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MenuAccion {
  final IconData icono;
  final String texto;
  final VoidCallback onTap;

  const _MenuAccion(this.icono, this.texto, this.onTap);
}

class _AccionesFila extends StatelessWidget {
  final bool cerrada;
  final bool tieneNota;
  final VoidCallback onNota;
  final VoidCallback onRecargaRuta;
  final VoidCallback onEntradaMovil;
  final VoidCallback onVerHistorial;
  final VoidCallback onVerReporte;

  const _AccionesFila({
    required this.cerrada,
    required this.tieneNota,
    required this.onNota,
    required this.onRecargaRuta,
    required this.onEntradaMovil,
    required this.onVerHistorial,
    required this.onVerReporte,
  });

  @override
  Widget build(BuildContext context) {
    if (cerrada) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: FlotaAccionButton(
              texto: 'Ver reporte',
              icon: Icons.assignment_turned_in_outlined,
              relleno: true,
              onTap: onVerReporte,
            ),
          ),
          const SizedBox(width: 8),
          _MenuMas(acciones: [_MenuAccion(Icons.history, 'Ver Historial', onVerHistorial)]),
        ],
      );
    }

    final acciones = <_MenuAccion>[
      if (tieneNota)
        _MenuAccion(Icons.assignment_return_outlined, 'Entrada del Móvil', onEntradaMovil),
      if (tieneNota)
        _MenuAccion(Icons.assignment_turned_in_outlined, 'Ver reporte', onVerReporte),
      _MenuAccion(Icons.history, 'Ver Historial', onVerHistorial),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: tieneNota
              ? FlotaAccionButton(
                  texto: 'Registrar Recarga en Ruta',
                  icon: Icons.local_shipping_outlined,
                  relleno: true,
                  onTap: onRecargaRuta,
                )
              : FlotaAccionButton(
                  texto: 'Agregar Stock / Nota Control',
                  icon: Icons.assignment_outlined,
                  relleno: true,
                  onTap: onNota,
                ),
        ),
        const SizedBox(width: 8),
        _MenuMas(acciones: acciones),
      ],
    );
  }
}

class _MenuMas extends StatelessWidget {
  final List<_MenuAccion> acciones;

  const _MenuMas({required this.acciones});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      tooltip: 'Más acciones',
      icon: const Icon(Icons.more_vert, color: AppColors.steelBlue),
      color: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (i) => acciones[i].onTap(),
      itemBuilder: (_) => [
        for (int i = 0; i < acciones.length; i++)
          PopupMenuItem<int>(
            value: i,
            child: Row(
              children: [
                Icon(acciones[i].icono, size: 17, color: AppColors.steelBlue),
                const SizedBox(width: 10),
                Text(acciones[i].texto, style: AppTextStyles.input.copyWith(fontSize: 13.5)),
              ],
            ),
          ),
      ],
    );
  }
}

class _NotaEstadoChip extends StatelessWidget {
  final NotaRodanteResumen? nota;

  const _NotaEstadoChip({required this.nota});

  @override
  Widget build(BuildContext context) {
    final estado = nota?.estado.toUpperCase() ?? '';
    late final String texto;
    late final Color color;
    if (nota == null) {
      texto = 'Sin carga';
      color = AppColors.badgeGray;
    } else if (estado == 'ENTRADA_COMPLETA') {
      texto = 'Cerrada';
      color = AppColors.badgeGreen;
    } else if (estado == 'RECARGA') {
      texto = 'Recargado';
      color = AppColors.badgeAmber;
    } else {
      texto = 'Con carga';
      color = AppColors.badgeBlue;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        texto,
        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: color),
      ),
    );
  }
}

class FlotaAccionButton extends StatelessWidget {
  final String texto;
  final IconData icon;
  final bool relleno;
  final VoidCallback onTap;

  const FlotaAccionButton({
    super.key,
    required this.texto,
    required this.icon,
    required this.relleno,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = relleno ? AppColors.orange : AppColors.steelBlue;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: relleno ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: color, width: 1.2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: relleno ? AppColors.white : color),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  texto,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: relleno ? AppColors.white : color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CamionCard extends StatelessWidget {
  final DepositoCamion camion;
  final bool seleccionado;
  final int asignado;
  final NotaRodanteResumen? nota;
  final CargarDetalleDia cargarDetalle;
  final VoidCallback onNota;
  final VoidCallback onRecargaRuta;
  final VoidCallback onEntradaMovil;
  final VoidCallback onVerHistorial;
  final VoidCallback onVerReporte;

  const _CamionCard({
    required this.camion,
    required this.seleccionado,
    required this.asignado,
    required this.nota,
    required this.cargarDetalle,
    required this.onNota,
    required this.onRecargaRuta,
    required this.onEntradaMovil,
    required this.onVerHistorial,
    required this.onVerReporte,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: seleccionado ? AppColors.orange : AppColors.inputBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      camion.patenteVisible,
                      style: AppTextStyles.label.copyWith(fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      camion.choferNombre,
                      style: AppTextStyles.link.copyWith(fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              _NotaEstadoChip(nota: nota),
            ],
          ),
          const SizedBox(height: 14),
          CamionStockBar(
            llenos: asignado,
            vacios: camion.vaciasDelDia,
          ),
          const SizedBox(height: 14),
          if (nota?.cerrada ?? false) ...[
            FlotaAccionButton(
              texto: 'Ver reporte',
              icon: Icons.assignment_turned_in_outlined,
              relleno: true,
              onTap: onVerReporte,
            ),
            const SizedBox(height: 8),
            FlotaAccionButton(
              texto: 'Ver Historial',
              icon: Icons.history,
              relleno: false,
              onTap: onVerHistorial,
            ),
          ] else if (nota != null) ...[
            FlotaAccionButton(
              texto: 'Registrar Recarga en Ruta',
              icon: Icons.local_shipping_outlined,
              relleno: true,
              onTap: onRecargaRuta,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FlotaAccionButton(
                  texto: 'Entrada del Móvil',
                  icon: Icons.assignment_return_outlined,
                  relleno: false,
                  onTap: onEntradaMovil,
                ),
                FlotaAccionButton(
                  texto: 'Ver reporte',
                  icon: Icons.assignment_turned_in_outlined,
                  relleno: false,
                  onTap: onVerReporte,
                ),
                FlotaAccionButton(
                  texto: 'Ver Historial',
                  icon: Icons.history,
                  relleno: false,
                  onTap: onVerHistorial,
                ),
              ],
            ),
          ] else ...[
            FlotaAccionButton(
              texto: 'Agregar Stock / Nota Control',
              icon: Icons.assignment_outlined,
              relleno: true,
              onTap: onNota,
            ),
            const SizedBox(height: 8),
            FlotaAccionButton(
              texto: 'Ver Historial',
              icon: Icons.history,
              relleno: false,
              onTap: onVerHistorial,
            ),
          ],
          const SizedBox(height: 12),
          _DetalleStockCamion(idUsuario: camion.repartidor?.id ?? '', cargar: cargarDetalle),
        ],
      ),
    );
  }
}

class _DetalleStockCamion extends StatefulWidget {
  final String idUsuario;
  final CargarDetalleDia cargar;

  const _DetalleStockCamion({required this.idUsuario, required this.cargar});

  @override
  State<_DetalleStockCamion> createState() => _DetalleStockCamionState();
}

class _DetalleStockCamionState extends State<_DetalleStockCamion> {
  bool _abierta = false;
  bool _cargando = false;
  bool _cargado = false;
  String? _error;
  List<DetalleNotaDiaria> _items = const [];

  Future<void> _toggle() async {
    setState(() => _abierta = !_abierta);
    if (_abierta && !_cargado && !_cargando) {
      await _fetch();
    }
  }

  Future<void> _fetch() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final items = await widget.cargar(widget.idUsuario);
      if (!mounted) return;
      setState(() {
        _items = items;
        _cargado = true;
        _cargando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo cargar la carga del día.';
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: _toggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                const Icon(Icons.inventory_2_outlined, size: 15, color: AppColors.steelBlue),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Detalle de la carga del día por tipo',
                    style: AppTextStyles.footer.copyWith(
                      color: AppColors.steelBlue,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: _abierta ? 0.5 : 0,
                  duration: const Duration(milliseconds: 160),
                  child: const Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.graphiteGray),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 160),
          crossFadeState: _abierta ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          firstChild: Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 6),
            child: _cuerpo(),
          ),
          secondChild: const SizedBox(width: double.infinity),
        ),
      ],
    );
  }

  Widget _cuerpo() {
    if (_cargando) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: SizedBox(
            height: 18, width: 18,
            child: CircularProgressIndicator(strokeWidth: 2.2, color: AppColors.orange),
          ),
        ),
      );
    }
    if (_error != null) {
      return Text(_error!, style: AppTextStyles.footer.copyWith(color: AppColors.badgeRed));
    }
    final items = _items.where((i) => i.llenos > 0 || i.vacias > 0).toList();
    if (items.isEmpty) {
      return Text(
        'El camión no tiene carga asignada hoy. Empieza en 0 hasta que le asignes su carga inicial.',
        style: AppTextStyles.footer.copyWith(color: AppColors.graphiteGray),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Row(
              children: const [
                Expanded(flex: 4, child: _CeldaMini('TIPO')),
                Expanded(flex: 3, child: _CeldaMini('LLENAS', alinearFinal: true)),
                Expanded(flex: 3, child: _CeldaMini('VACÍAS', alinearFinal: true)),
              ],
            ),
          ),
          for (final it in items) ...[
            const Divider(height: 1, color: AppColors.inputBorder),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Text('Garrafa ${it.etiqueta}',
                        style: AppTextStyles.input.copyWith(fontSize: 13)),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text('${it.llenos}',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                            fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.badgeGreen)),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text('${it.vacias}',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                            fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.steelBlue)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CeldaMini extends StatelessWidget {
  final String texto;
  final bool alinearFinal;
  const _CeldaMini(this.texto, {this.alinearFinal = false});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alinearFinal ? Alignment.centerRight : Alignment.centerLeft,
      child: Text(
        texto,
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: AppColors.graphiteGray,
        ),
      ),
    );
  }
}
