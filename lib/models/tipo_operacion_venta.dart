import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum TipoOperacionVenta { vacioXLleno, prestamo, ventaSocial }

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
      case TipoOperacionVenta.ventaSocial:
        return 'SOCIAL';
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
      case TipoOperacionVenta.ventaSocial:
        return const TipoOperacionVentaInfo(
          label: 'Venta Social',
          descripcion: 'Dejás garrafas llenas en el punto. La visita queda en pausa y se liquida al volver.',
          icono: Icons.volunteer_activism_outlined,
        );
    }
  }

  bool get usaRecibidos =>
      this != TipoOperacionVenta.prestamo && this != TipoOperacionVenta.ventaSocial;

  bool get esSocial => this == TipoOperacionVenta.ventaSocial;

  bool concordanciaValida(int entregada, int recibida) {
    switch (this) {
      case TipoOperacionVenta.vacioXLleno:
        return entregada == recibida;
      case TipoOperacionVenta.prestamo:
        return recibida == 0;
      case TipoOperacionVenta.ventaSocial:
        return true;
    }
  }

  String? mensajeInconsistencia(int entregada, int recibida) {
    if (concordanciaValida(entregada, recibida)) return null;
    switch (this) {
      case TipoOperacionVenta.vacioXLleno:
        return 'Cantidades inconsistentes (Entregados ≠ Recibidos). Se registra igual, marcada para revisión del administrador.';
      case TipoOperacionVenta.prestamo:
        return 'En un préstamo no se reciben envases vacíos (Recibidos debe ser 0).';
      case TipoOperacionVenta.ventaSocial:
        return null;
    }
  }

  Color get color {
    switch (this) {
      case TipoOperacionVenta.vacioXLleno:
        return AppColors.orange;
      case TipoOperacionVenta.prestamo:
        return AppColors.steelBlue;
      case TipoOperacionVenta.ventaSocial:
        return AppColors.steelBlue;
    }
  }
}
