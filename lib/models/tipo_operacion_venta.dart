import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum TipoOperacionVenta { vacioXLleno, prestamo, envaseSolo }

class TipoOperacionVentaInfo {
  final String label;
  final String descripcion;
  final IconData icono;

  const TipoOperacionVentaInfo({
    required this.label,
    required this.descripcion,
    required this.icono,
  });
}

extension TipoOperacionVentaX on TipoOperacionVenta {
  String get backendValue {
    switch (this) {
      case TipoOperacionVenta.vacioXLleno:
        return 'VACIO_X_LLENO';
      case TipoOperacionVenta.prestamo:
        return 'PRESTAMO';
      case TipoOperacionVenta.envaseSolo:
        return 'ENVASE';
    }
  }

  TipoOperacionVentaInfo get info {
    switch (this) {
      case TipoOperacionVenta.vacioXLleno:
        return const TipoOperacionVentaInfo(
          label: 'Vacío x Lleno',
          descripcion: 'El cliente entrega envases vacíos y recibe la misma cantidad de llenos.',
          icono: Icons.swap_horiz,
        );
      case TipoOperacionVenta.prestamo:
        return const TipoOperacionVentaInfo(
          label: 'Préstamo',
          descripcion: 'El cliente recibe garrafas sin entregar envases vacíos.',
          icono: Icons.outbox_outlined,
        );
      case TipoOperacionVenta.envaseSolo:
        return const TipoOperacionVentaInfo(
          label: 'Envase solo',
          descripcion: 'Movimiento de envases sin intercambio uno a uno.',
          icono: Icons.propane_tank_outlined,
        );
    }
  }

  bool get usaRecibidos => this != TipoOperacionVenta.prestamo;

  bool concordanciaValida(int entregada, int recibida) {
    switch (this) {
      case TipoOperacionVenta.vacioXLleno:
        return entregada == recibida;
      case TipoOperacionVenta.prestamo:
        return recibida == 0;
      case TipoOperacionVenta.envaseSolo:
        return true;
    }
  }

  String? mensajeInconsistencia(int entregada, int recibida) {
    if (concordanciaValida(entregada, recibida)) return null;
    switch (this) {
      case TipoOperacionVenta.vacioXLleno:
        return 'Cantidades inconsistentes (Entregados ≠ Recibidos). La venta no puede guardarse.';
      case TipoOperacionVenta.prestamo:
        return 'En un préstamo no se reciben envases vacíos (Recibidos debe ser 0).';
      case TipoOperacionVenta.envaseSolo:
        return null;
    }
  }

  Color get color {
    switch (this) {
      case TipoOperacionVenta.vacioXLleno:
        return AppColors.orange;
      case TipoOperacionVenta.prestamo:
        return AppColors.steelBlue;
      case TipoOperacionVenta.envaseSolo:
        return AppColors.graphiteGray;
    }
  }
}
