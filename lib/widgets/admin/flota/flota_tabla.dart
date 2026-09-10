import 'package:flutter/material.dart';

import '../../../models/deposito_camion.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import 'camion_stock_bar.dart';
import 'estado_camion_badge.dart';

class FlotaTabla extends StatelessWidget {
  final List<DepositoCamion> camiones;
  final int? idSeleccionado;
  final ValueChanged<DepositoCamion> onNota;
  final ValueChanged<DepositoCamion> onRecargaRuta;
  final ValueChanged<DepositoCamion> onEntradaMovil;
  final ValueChanged<DepositoCamion> onVerHistorial;
  final String mensajeVacio;

  const FlotaTabla({
    super.key,
    required this.camiones,
    required this.onNota,
    required this.onRecargaRuta,
    required this.onEntradaMovil,
    required this.onVerHistorial,
    this.idSeleccionado,
    this.mensajeVacio = 'No hay camiones para mostrar.',
  });

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
                  onNota: () => onNota(camion),
                  onRecargaRuta: () => onRecargaRuta(camion),
                  onEntradaMovil: () => onEntradaMovil(camion),
                  onVerHistorial: () => onVerHistorial(camion),
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
                onNota: () => onNota(camion),
                onRecargaRuta: () => onRecargaRuta(camion),
                onEntradaMovil: () => onEntradaMovil(camion),
                onVerHistorial: () => onVerHistorial(camion),
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
          _CeldaHeader(flex: _colStock, texto: 'STOCK ACTUAL'),
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
  final VoidCallback onNota;
  final VoidCallback onRecargaRuta;
  final VoidCallback onEntradaMovil;
  final VoidCallback onVerHistorial;

  const _FilaCamion({
    required this.camion,
    required this.seleccionado,
    required this.onNota,
    required this.onRecargaRuta,
    required this.onEntradaMovil,
    required this.onVerHistorial,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: seleccionado ? AppColors.orange.withOpacity(0.06) : Colors.transparent,
        border: Border(bottom: BorderSide(color: AppColors.inputBorder.withOpacity(0.6))),
      ),
      child: Row(
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
                llenos: camion.llenos,
                vacios: camion.vacios,
                cupo: camion.cupoBase,
                compacto: true,
              ),
            ),
          ),
          Expanded(
            flex: _colVacias,
            child: Text(
              '${camion.vacios}',
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
              child: EstadoCamionBadge(estado: camion.estado),
            ),
          ),
          Expanded(
            flex: _colAcciones,
            child: _AccionesFila(
              onNota: onNota,
              onRecargaRuta: onRecargaRuta,
              onEntradaMovil: onEntradaMovil,
              onVerHistorial: onVerHistorial,
            ),
          ),
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

class _AccionesFila extends StatelessWidget {
  final VoidCallback onNota;
  final VoidCallback onRecargaRuta;
  final VoidCallback onEntradaMovil;
  final VoidCallback onVerHistorial;

  const _AccionesFila({
    required this.onNota,
    required this.onRecargaRuta,
    required this.onEntradaMovil,
    required this.onVerHistorial,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: FlotaAccionButton(
            texto: 'Agregar Stock / Nota Control',
            icon: Icons.assignment_outlined,
            relleno: true,
            onTap: onNota,
          ),
        ),
        const SizedBox(width: 8),
        _MenuMas(
          onRecargaRuta: onRecargaRuta,
          onEntradaMovil: onEntradaMovil,
          onVerHistorial: onVerHistorial,
        ),
      ],
    );
  }
}

class _MenuMas extends StatelessWidget {
  final VoidCallback onRecargaRuta;
  final VoidCallback onEntradaMovil;
  final VoidCallback onVerHistorial;

  const _MenuMas({
    required this.onRecargaRuta,
    required this.onEntradaMovil,
    required this.onVerHistorial,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      tooltip: 'Más acciones',
      icon: const Icon(Icons.more_vert, color: AppColors.steelBlue),
      color: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (v) {
        if (v == 0) {
          onRecargaRuta();
        } else if (v == 1) {
          onEntradaMovil();
        } else {
          onVerHistorial();
        }
      },
      itemBuilder: (_) => [
        _item(0, Icons.local_shipping_outlined, 'Registrar Recarga en Ruta'),
        _item(1, Icons.assignment_return_outlined, 'Entrada del Móvil'),
        _item(2, Icons.history, 'Ver Historial'),
      ],
    );
  }

  PopupMenuItem<int> _item(int valor, IconData icono, String texto) {
    return PopupMenuItem<int>(
      value: valor,
      child: Row(
        children: [
          Icon(icono, size: 17, color: AppColors.steelBlue),
          const SizedBox(width: 10),
          Text(texto, style: AppTextStyles.input.copyWith(fontSize: 13.5)),
        ],
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
  final VoidCallback onNota;
  final VoidCallback onRecargaRuta;
  final VoidCallback onEntradaMovil;
  final VoidCallback onVerHistorial;

  const _CamionCard({
    required this.camion,
    required this.seleccionado,
    required this.onNota,
    required this.onRecargaRuta,
    required this.onEntradaMovil,
    required this.onVerHistorial,
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
              EstadoCamionBadge(estado: camion.estado),
            ],
          ),
          const SizedBox(height: 14),
          CamionStockBar(
            llenos: camion.llenos,
            vacios: camion.vacios,
            cupo: camion.cupoBase,
          ),
          const SizedBox(height: 14),
          FlotaAccionButton(
            texto: 'Agregar Stock / Nota Control',
            icon: Icons.assignment_outlined,
            relleno: true,
            onTap: onNota,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FlotaAccionButton(
                texto: 'Recarga en Ruta',
                icon: Icons.local_shipping_outlined,
                relleno: false,
                onTap: onRecargaRuta,
              ),
              FlotaAccionButton(
                texto: 'Entrada del Móvil',
                icon: Icons.assignment_return_outlined,
                relleno: false,
                onTap: onEntradaMovil,
              ),
              FlotaAccionButton(
                texto: 'Ver Historial',
                icon: Icons.history,
                relleno: false,
                onTap: onVerHistorial,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
